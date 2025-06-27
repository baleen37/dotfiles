package core

import (
	"context"
	"errors"
	"ssulmeta-go/internal/story/adapters"
	"ssulmeta-go/internal/story/ports"
	"ssulmeta-go/pkg/models"
	"strings"
	"sync"
	"testing"
	"time"
)

func TestService_GenerateStory(t *testing.T) {
	// Create mock service using dependency injection
	generator := adapters.NewMockGenerator()
	validator := NewValidator()
	service := NewService(generator, validator)

	// Create test channel
	channel := models.NewChannel("test_channel")
	channel.PromptTemplate = "테스트용 프롬프트"

	// Generate story
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	story, err := service.GenerateStory(ctx, channel)
	if err != nil {
		t.Fatalf("Failed to generate story: %v", err)
	}

	// Verify story
	if story.Title == "" {
		t.Error("Story title is empty")
	}

	if story.Content == "" {
		t.Error("Story content is empty")
	}

	if len(story.Scenes) == 0 {
		t.Error("No scenes generated")
	}

	t.Logf("Generated story: %s", story.Title)
	t.Logf("Content length: %d characters", len([]rune(story.Content)))
	t.Logf("Number of scenes: %d", len(story.Scenes))
}

func TestValidator(t *testing.T) {
	validator := NewValidator()

	tests := []struct {
		name    string
		story   *models.Story
		wantErr bool
	}{
		{
			name: "valid story",
			story: &models.Story{
				Title:   "테스트 이야기",
				Content: "옛날 옛적에 아름다운 마을이 있었습니다. 그 마을에는 착한 사람들이 살고 있었습니다. 어느 날, 마을에 신비한 나그네가 찾아왔습니다. 나그네는 마을 사람들에게 특별한 선물을 주었습니다. 그것은 바로 희망의 씨앗이었습니다. 마을 사람들은 정성껏 씨앗을 심고 가꾸었습니다. 시간이 흘러 씨앗은 아름다운 꽃으로 피어났습니다. 그 꽃은 마을 전체를 환하게 밝혀주었습니다. 마을 사람들은 더욱 행복해졌습니다. 그들은 나그네에게 감사하며 살았습니다. 이 이야기는 희망과 감사의 중요성을 전합니다.",
			},
			wantErr: false,
		},
		{
			name: "too short",
			story: &models.Story{
				Title:   "짧은 이야기",
				Content: "너무 짧은 내용.",
			},
			wantErr: true,
		},
		{
			name: "empty title",
			story: &models.Story{
				Title:   "",
				Content: "제목이 없는 이야기입니다. 충분히 긴 내용을 포함하고 있습니다. 세 번째 문장도 추가합니다.",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validator.ValidateStory(tt.story)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateStory() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

// Enhanced tests with error scenarios
func TestService_GenerateStory_Enhanced(t *testing.T) {
	tests := []struct {
		name        string
		generator   ports.Generator
		validator   *Validator
		channel     *models.Channel
		timeout     time.Duration
		wantErr     bool
		errContains string
	}{
		{
			name:      "successful generation",
			generator: adapters.NewMockGenerator(),
			validator: NewValidator(),
			channel: &models.Channel{
				ID:             1,
				Name:           "Test Channel",
				PromptTemplate: "테스트용 프롬프트",
			},
			timeout: 5 * time.Second,
			wantErr: false,
		},
		{
			name:        "nil channel",
			generator:   adapters.NewMockGenerator(),
			validator:   NewValidator(),
			channel:     nil,
			timeout:     5 * time.Second,
			wantErr:     true,
			errContains: "channel is nil",
		},
		{
			name:      "generator error",
			generator: &errorGenerator{err: errors.New("API error")},
			validator: NewValidator(),
			channel: &models.Channel{
				ID:             2,
				Name:           "Test Channel",
				PromptTemplate: "테스트용 프롬프트",
			},
			timeout:     5 * time.Second,
			wantErr:     true,
			errContains: "API error",
		},
		{
			name:      "validation error",
			generator: &invalidStoryGenerator{},
			validator: NewValidator(),
			channel: &models.Channel{
				ID:             3,
				Name:           "Test Channel",
				PromptTemplate: "테스트용 프롬프트",
			},
			timeout:     5 * time.Second,
			wantErr:     true,
			errContains: "content too short",
		},
		{
			name:      "context cancellation",
			generator: &slowGenerator{delay: 5 * time.Second},
			validator: NewValidator(),
			channel: &models.Channel{
				ID:             4,
				Name:           "Test Channel",
				PromptTemplate: "테스트용 프롬프트",
			},
			timeout:     100 * time.Millisecond,
			wantErr:     true,
			errContains: "context deadline exceeded",
		},
		{
			name:      "empty prompt template",
			generator: adapters.NewMockGenerator(),
			validator: NewValidator(),
			channel: &models.Channel{
				ID:             5,
				Name:           "Test Channel",
				PromptTemplate: "",
			},
			timeout: 5 * time.Second,
			wantErr: false, // Should still work with empty prompt
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			service := NewService(tt.generator, tt.validator)

			ctx, cancel := context.WithTimeout(context.Background(), tt.timeout)
			defer cancel()

			story, err := service.GenerateStory(ctx, tt.channel)

			if (err != nil) != tt.wantErr {
				t.Errorf("GenerateStory() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if err != nil && tt.errContains != "" {
				if !strings.Contains(err.Error(), tt.errContains) {
					t.Errorf("GenerateStory() error = %v, want error containing %s", err, tt.errContains)
				}
			}

			if !tt.wantErr && story == nil {
				t.Error("GenerateStory() returned nil story without error")
			}
		})
	}
}

// Test concurrent story generation
func TestService_GenerateStory_Concurrent(t *testing.T) {
	generator := adapters.NewMockGenerator()
	validator := NewValidator()
	service := NewService(generator, validator)

	channel := &models.Channel{
		ID:             1,
		Name:           "Test Channel",
		PromptTemplate: "테스트용 프롬프트",
	}

	const numGoroutines = 10
	var wg sync.WaitGroup
	wg.Add(numGoroutines)

	errors := make(chan error, numGoroutines)
	stories := make(chan *models.Story, numGoroutines)

	for i := 0; i < numGoroutines; i++ {
		go func(id int) {
			defer wg.Done()

			ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()

			story, err := service.GenerateStory(ctx, channel)
			if err != nil {
				errors <- err
				return
			}
			stories <- story
		}(i)
	}

	wg.Wait()
	close(errors)
	close(stories)

	// Check results
	errorCount := 0
	for err := range errors {
		t.Errorf("Concurrent generation error: %v", err)
		errorCount++
	}

	storyCount := 0
	for story := range stories {
		if story == nil {
			t.Error("Received nil story")
		}
		storyCount++
	}

	if storyCount+errorCount != numGoroutines {
		t.Errorf("Expected %d results, got %d stories and %d errors",
			numGoroutines, storyCount, errorCount)
	}
}

// Mock generators for testing different scenarios

type errorGenerator struct {
	err error
}

func (g *errorGenerator) GenerateStory(ctx context.Context, channel *models.Channel) (*models.Story, error) {
	return nil, g.err
}

func (g *errorGenerator) DivideIntoScenes(ctx context.Context, story *models.Story) error {
	return g.err
}

type invalidStoryGenerator struct{}

func (g *invalidStoryGenerator) GenerateStory(ctx context.Context, channel *models.Channel) (*models.Story, error) {
	return &models.Story{
		Title:   "Too Short",
		Content: "Short", // Too short content
		Scenes:  []models.Scene{},
	}, nil
}

func (g *invalidStoryGenerator) DivideIntoScenes(ctx context.Context, story *models.Story) error {
	story.Scenes = []models.Scene{} // Empty scenes
	return nil
}

type slowGenerator struct {
	delay time.Duration
}

func (g *slowGenerator) GenerateStory(ctx context.Context, channel *models.Channel) (*models.Story, error) {
	select {
	case <-time.After(g.delay):
		return &models.Story{
			Title:   "Slow Story",
			Content: strings.Repeat("가", 280),
			Scenes:  []models.Scene{},
		}, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

func (g *slowGenerator) DivideIntoScenes(ctx context.Context, story *models.Story) error {
	story.Scenes = []models.Scene{
		{Number: 1, Description: "Scene 1", ImagePrompt: "prompt1", Duration: 3.0},
		{Number: 2, Description: "Scene 2", ImagePrompt: "prompt2", Duration: 3.0},
		{Number: 3, Description: "Scene 3", ImagePrompt: "prompt3", Duration: 3.0},
		{Number: 4, Description: "Scene 4", ImagePrompt: "prompt4", Duration: 3.0},
		{Number: 5, Description: "Scene 5", ImagePrompt: "prompt5", Duration: 3.0},
		{Number: 6, Description: "Scene 6", ImagePrompt: "prompt6", Duration: 3.0},
	}
	return nil
}
