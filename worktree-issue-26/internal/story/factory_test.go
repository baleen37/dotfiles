package story

import (
	"context"
	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/story/ports"
	"ssulmeta-go/pkg/models"
	"testing"
)

func TestNewServiceWithConfig(t *testing.T) {
	tests := []struct {
		name    string
		cfg     *config.APIConfig
		wantErr bool
	}{
		{
			name: "creates service with mock generator",
			cfg: &config.APIConfig{
				UseMock: true,
			},
			wantErr: false,
		},
		{
			name: "creates service with OpenAI generator",
			cfg: &config.APIConfig{
				UseMock: false,
				OpenAI: config.OpenAIConfig{
					APIKey:      "test-key",
					Model:       "gpt-4",
					MaxTokens:   1000,
					Temperature: 0.7,
					RateLimit:   10,
				},
			},
			wantErr: false,
		},
		{
			name: "creates service with empty OpenAI config",
			cfg: &config.APIConfig{
				UseMock: false,
				OpenAI:  config.OpenAIConfig{},
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			service, err := NewServiceWithConfig(tt.cfg)
			if (err != nil) != tt.wantErr {
				t.Errorf("NewServiceWithConfig() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if !tt.wantErr && service == nil {
				t.Error("NewServiceWithConfig() returned nil service")
			}
		})
	}
}

func TestNewServiceWithConfig_Integration(t *testing.T) {
	tests := []struct {
		name     string
		cfg      *config.APIConfig
		validate func(t *testing.T, service ports.Service)
	}{
		{
			name: "mock generator produces valid story",
			cfg: &config.APIConfig{
				UseMock: true,
			},
			validate: func(t *testing.T, service ports.Service) {
				channel := &models.Channel{
					ID:             1,
					Name:           "Test Channel",
					PromptTemplate: "Test prompt",
				}

				ctx := context.Background()
				story, err := service.GenerateStory(ctx, channel)
				if err != nil {
					t.Fatalf("Failed to generate story: %v", err)
				}

				if story == nil {
					t.Fatal("Generated story is nil")
				}

				if story.Title == "" {
					t.Error("Story title is empty")
				}

				if len(story.Scenes) == 0 {
					t.Error("Story has no scenes")
				}

				// Verify it's using mock generator by checking consistent output
				story2, _ := service.GenerateStory(ctx, channel)
				if story.Title != story2.Title {
					t.Error("Mock generator should produce consistent output")
				}
			},
		},
		{
			name: "service validates story correctly",
			cfg: &config.APIConfig{
				UseMock: true,
			},
			validate: func(t *testing.T, service ports.Service) {
				// Test that the service includes validation
				// Mock generator always produces valid stories, so we can't test
				// validation failure directly, but we can verify the service works
				channel := &models.Channel{
					ID:             1,
					Name:           "Test Channel",
					PromptTemplate: "Test prompt",
				}

				ctx := context.Background()
				story, err := service.GenerateStory(ctx, channel)
				if err != nil {
					t.Fatalf("Service should generate valid story: %v", err)
				}

				// Verify story meets validation criteria
				contentLength := len([]rune(story.Content))
				if contentLength < 270 || contentLength > 300 {
					t.Errorf("Story content length %d is outside valid range [270, 300]", contentLength)
				}

				if len(story.Scenes) < 6 || len(story.Scenes) > 10 {
					t.Errorf("Story has %d scenes, expected between 6 and 10", len(story.Scenes))
				}
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			service, err := NewServiceWithConfig(tt.cfg)
			if err != nil {
				t.Fatalf("Failed to create service: %v", err)
			}

			tt.validate(t, service)
		})
	}
}

func BenchmarkNewServiceWithConfig(b *testing.B) {
	cfg := &config.APIConfig{
		UseMock: true,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = NewServiceWithConfig(cfg)
	}
}

func BenchmarkServiceWithMockGenerator(b *testing.B) {
	cfg := &config.APIConfig{
		UseMock: true,
	}

	service, _ := NewServiceWithConfig(cfg)
	channel := &models.Channel{
		ID:             1,
		Name:           "Benchmark Channel",
		PromptTemplate: "Benchmark prompt",
	}
	ctx := context.Background()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = service.GenerateStory(ctx, channel)
	}
}
