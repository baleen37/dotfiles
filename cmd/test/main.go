package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"ssulmeta-go/internal/channel"
	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/story"
	"ssulmeta-go/pkg/logger"
)

func main() {
	// Set environment to test
	if err := os.Setenv("APP_ENV", "test"); err != nil {
		log.Fatalf("Failed to set environment: %v", err)
	}

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Initialize logger
	if err := logger.Init(&cfg.Logging); err != nil {
		log.Fatalf("Failed to init logger: %v", err)
	}

	// Test with different channels
	channels := []string{"fairy_tale", "horror", "romance"}

	for _, channelName := range channels {
		fmt.Printf("\n=== Testing %s channel ===\n", channelName)

		// Load channel config
		channelCfg, err := channel.LoadChannelConfig(channelName)
		if err != nil {
			logger.Error("Failed to load channel config", "channel", channelName, "error", err)
			continue
		}

		// Convert to model
		ch := channelCfg.ToModel()

		// Create story service (using mock)
		storySvc, err := story.NewService(&cfg.API)
		if err != nil {
			logger.Error("Failed to create story service", "error", err)
			continue
		}

		// Generate story
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		generatedStory, err := storySvc.GenerateStory(ctx, ch)
		if err != nil {
			logger.Error("Failed to generate story", "error", err)
			continue
		}

		// Print results
		fmt.Printf("\nChannel: %s\n", ch.Name)
		fmt.Printf("Title: %s\n", generatedStory.Title)
		fmt.Printf("Content (%d chars): %s\n", len([]rune(generatedStory.Content)), generatedStory.Content)
		fmt.Printf("Number of scenes: %d\n", len(generatedStory.Scenes))

		for i, scene := range generatedStory.Scenes {
			fmt.Printf("\nScene %d:\n", scene.Number)
			fmt.Printf("  Description: %s\n", scene.Description)
			fmt.Printf("  Image Prompt: %s\n", scene.ImagePrompt)
			fmt.Printf("  Duration: %.1f seconds\n", scene.Duration)

			if i >= 2 { // Only show first 3 scenes
				fmt.Printf("  ... and %d more scenes\n", len(generatedStory.Scenes)-3)
				break
			}
		}

		fmt.Println("\n" + strings.Repeat("-", 80))
	}

	// Test actual API if key is set
	testRealAPI(cfg)
}

func testRealAPI(cfg *config.Config) {
	// Check if OpenAI API key is set
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		fmt.Println("\n\nTo test with real OpenAI API, set OPENAI_API_KEY environment variable")
		return
	}

	fmt.Println("\n\n=== Testing with Real OpenAI API ===")

	// Override config to use real API
	cfg.API.UseMock = false
	cfg.API.OpenAI.APIKey = apiKey

	// Load fairy tale channel for testing
	channelCfg, err := channel.LoadChannelConfig("fairy_tale")
	if err != nil {
		logger.Error("Failed to load channel config", "error", err)
		return
	}

	ch := channelCfg.ToModel()

	// Create story service with real API
	storySvc, err := story.NewService(&cfg.API)
	if err != nil {
		logger.Error("Failed to create story service", "error", err)
		return
	}

	// Generate story
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	fmt.Println("Calling OpenAI API...")
	generatedStory, err := storySvc.GenerateStory(ctx, ch)
	if err != nil {
		logger.Error("Failed to generate story with OpenAI", "error", err)
		return
	}

	// Print results
	fmt.Printf("\nReal API Results:\n")
	fmt.Printf("Title: %s\n", generatedStory.Title)
	fmt.Printf("Content (%d chars): %s\n", len([]rune(generatedStory.Content)), generatedStory.Content)
	fmt.Printf("Number of scenes: %d\n", len(generatedStory.Scenes))
}
