package image_test

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"strings"
	"testing"

	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/image"
	"ssulmeta-go/pkg/models"
)

func TestImageService_Integration(t *testing.T) {
	// Skip if not in integration test mode
	if os.Getenv("INTEGRATION_TEST") != "true" {
		t.Skip("Skipping integration test. Set INTEGRATION_TEST=true to run.")
	}

	// Create test config
	cfg := &config.Config{
		API: config.APIConfig{
			Image: config.ImageAPIConfig{
				Provider: "mock", // Use mock for integration tests
				APIKey:   "test-key",
				BaseURL:  "http://localhost:8080",
			},
		},
		Storage: config.StorageConfig{
			BasePath: "./test_assets",
		},
	}

	// Create logger
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	}))

	// Create container
	container, err := image.NewContainer(cfg, logger)
	if err != nil {
		t.Fatalf("Failed to create container: %v", err)
	}

	// Create test story
	story := models.Story{
		Title:   "테스트 이야기",
		Content: "옛날 옛적에 작은 마을에 한 소녀가 살았습니다.",
		Scenes: []models.Scene{
			{
				Number:      1,
				Description: "작은 마을의 아침, 소녀가 창문을 열고 밖을 바라본다",
				Duration:    3.5,
			},
			{
				Number:      2,
				Description: "소녀가 숲으로 향하는 길을 걷고 있다",
				Duration:    4.0,
			},
			{
				Number:      3,
				Description: "깊은 숲 속에서 신비한 빛을 발견한다",
				Duration:    3.5,
			},
		},
	}

	channelStyle := "children's book illustration, bright colors, whimsical style"

	// Test image generation
	ctx := context.Background()
	imagePaths, err := container.Service.GenerateStoryImages(ctx, story, channelStyle)
	if err != nil {
		t.Fatalf("Failed to generate images: %v", err)
	}

	// Verify results
	if len(imagePaths) != len(story.Scenes) {
		t.Errorf("Expected %d images, got %d", len(story.Scenes), len(imagePaths))
	}

	// Check that all image files exist
	for i, path := range imagePaths {
		if _, err := os.Stat(path); err != nil {
			t.Errorf("Image %d does not exist at path: %s", i+1, path)
		}
	}

	// Cleanup test assets
	defer func() {
		if err := os.RemoveAll("./test_assets"); err != nil {
			t.Logf("Failed to clean up test assets: %v", err)
		}
	}()
}

func TestPromptBuilder_Integration(t *testing.T) {
	// This test doesn't need INTEGRATION_TEST flag as it tests only core logic

	// Create test config
	cfg := &config.Config{
		API: config.APIConfig{
			Image: config.ImageAPIConfig{
				Provider: "mock",
			},
		},
		Storage: config.StorageConfig{
			BasePath: "./test_assets",
		},
	}

	// Create logger
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	// Create container
	container, err := image.NewContainer(cfg, logger)
	if err != nil {
		t.Fatalf("Failed to create container: %v", err)
	}

	// Test scenes
	scenes := []models.Scene{
		{
			Number:      1,
			Description: "어린 왕자가 작은 별에서 장미를 바라본다",
		},
		{
			Number:      2,
			Description: "왕자가 우주를 여행하며 다른 별들을 방문한다",
		},
		{
			Number:      3,
			Description: "지구에 도착한 왕자가 사막에서 여우를 만난다",
		},
	}

	style := "fantasy illustration, dreamy atmosphere, soft pastel colors"

	// Build prompts
	prompts := container.PromptBuilder.BuildPromptsForStory(scenes, style)

	// Verify prompts
	if len(prompts) != len(scenes) {
		t.Fatalf("Expected %d prompts, got %d", len(scenes), len(prompts))
	}

	// Check that all prompts contain essential elements
	for i, prompt := range prompts {
		t.Logf("Prompt %d: %s", i+1, prompt)

		// Should contain style
		if !contains(prompt, style) {
			t.Errorf("Prompt %d missing style", i+1)
		}

		// Should contain vertical format specification
		if !contains(prompt, "vertical") || !contains(prompt, "9:16") {
			t.Errorf("Prompt %d missing vertical format specification", i+1)
		}

		// Should contain scene progression
		expectedProgression := fmt.Sprintf("scene %d of %d", i+1, len(scenes))
		if !contains(prompt, expectedProgression) {
			t.Errorf("Prompt %d missing progression info", i+1)
		}
	}
}

func contains(s, substr string) bool {
	return strings.Contains(s, substr)
}
