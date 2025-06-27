package config

import (
	"testing"
	"time"
)

func TestConfigValidation(t *testing.T) {
	tests := []struct {
		name      string
		config    Config
		wantError bool
	}{
		{
			name: "valid config",
			config: Config{
				App: AppConfig{
					Name: "test-app",
				},
				Database: DatabaseConfig{
					Host: "localhost",
					Port: 5432,
				},
				Server: ServerConfig{
					Port:      ":8080",
					RedisAddr: "localhost:6379",
				},
				HTTPClient: HTTPClientConfig{
					OpenAITimeout: 30 * time.Second,
					TTSTimeout:    30 * time.Second,
					ImageTimeout:  120 * time.Second,
				},
				Story: StoryConfig{
					ReadingRate: 15.0,
					MinDuration: 3.0,
					MaxDuration: 12.0,
				},
				API: APIConfig{
					OpenAI: OpenAIConfig{
						BaseURL: "https://api.openai.com/v1/chat/completions",
					},
					Image: ImageAPIConfig{
						Width:  1080,
						Height: 1920,
					},
				},
			},
			wantError: false,
		},
		{
			name: "missing app name",
			config: Config{
				Database: DatabaseConfig{
					Host: "localhost",
					Port: 5432,
				},
			},
			wantError: true,
		},
		{
			name: "invalid duration bounds",
			config: Config{
				App: AppConfig{
					Name: "test-app",
				},
				Database: DatabaseConfig{
					Host: "localhost",
					Port: 5432,
				},
				Server: ServerConfig{
					Port:      ":8080",
					RedisAddr: "localhost:6379",
				},
				HTTPClient: HTTPClientConfig{
					OpenAITimeout: 30 * time.Second,
					TTSTimeout:    30 * time.Second,
					ImageTimeout:  120 * time.Second,
				},
				Story: StoryConfig{
					ReadingRate: 15.0,
					MinDuration: 12.0, // Invalid: min > max
					MaxDuration: 3.0,
				},
				API: APIConfig{
					OpenAI: OpenAIConfig{
						BaseURL: "https://api.openai.com/v1/chat/completions",
					},
					Image: ImageAPIConfig{
						Width:  1080,
						Height: 1920,
					},
				},
			},
			wantError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()
			if (err != nil) != tt.wantError {
				t.Errorf("Config.Validate() error = %v, wantError %v", err, tt.wantError)
			}
		})
	}
}

func TestConfigStructure(t *testing.T) {
	// Test that configuration struct is properly structured
	config := Config{
		App: AppConfig{
			Name: "test-app",
		},
		Database: DatabaseConfig{
			Host: "localhost",
			Port: 5432,
		},
		Server: ServerConfig{
			Port:      ":8080",
			RedisAddr: "localhost:6379",
		},
		HTTPClient: HTTPClientConfig{
			OpenAITimeout: 30 * time.Second,
			TTSTimeout:    30 * time.Second,
			ImageTimeout:  120 * time.Second,
		},
		Story: StoryConfig{
			ReadingRate:   15.0,
			MinDuration:   3.0,
			MaxDuration:   12.0,
			DefaultPrompt: "test prompt",
			DefaultTitle:  "test title",
		},
		API: APIConfig{
			OpenAI: OpenAIConfig{
				BaseURL:      "https://api.openai.com/v1/chat/completions",
				SystemPrompt: "test system prompt",
			},
			Image: ImageAPIConfig{
				Width:  1080,
				Height: 1920,
			},
		},
	}

	// Verify structure is complete
	if config.App.Name == "" {
		t.Error("App name should not be empty")
	}

	if config.Story.ReadingRate <= 0 {
		t.Error("Story reading rate should be positive")
	}

	if config.HTTPClient.OpenAITimeout <= 0 {
		t.Error("OpenAI timeout should be positive")
	}

	if config.API.OpenAI.BaseURL == "" {
		t.Error("OpenAI base URL should not be empty")
	}

	if config.API.Image.Width <= 0 || config.API.Image.Height <= 0 {
		t.Error("Image dimensions should be positive")
	}
}
