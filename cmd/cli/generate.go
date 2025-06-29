package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"

	"ssulmeta-go/internal/story"
	"ssulmeta-go/pkg/models"
)

var generateCmd = &cobra.Command{
	Use:   "generate",
	Short: "Generate YouTube Shorts stories",
	Long: `Generate YouTube Shorts stories using AI-powered content generation.

This command creates storytelling-based content for specified channels using
configured templates and AI generation services.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		// Get flags
		channelName, _ := cmd.Flags().GetString("channel")
		outputDir, _ := cmd.Flags().GetString("output")
		templateOverride, _ := cmd.Flags().GetString("template")
		count, _ := cmd.Flags().GetInt("count")
		dryRun, _ := cmd.Flags().GetBool("dry-run")

		// Validate required flags
		if channelName == "" {
			return fmt.Errorf("channel is required")
		}

		// Get configuration
		cfg := GetConfig()
		if cfg == nil {
			return fmt.Errorf("configuration not loaded")
		}

		// Get logger
		logger := GetLogger(cmd)

		// Validate channel exists
		validChannels := []string{"fairy_tale", "horror", "romance"}
		isValid := false
		for _, valid := range validChannels {
			if channelName == valid {
				isValid = true
				break
			}
		}
		if !isValid {
			return fmt.Errorf("channel configuration not found for '%s'", channelName)
		}

		logger.Start(fmt.Sprintf("Generating story for channel: %s", channelName))

		// Create channel model
		channel := models.NewChannel(channelName)
		
		// Set template based on channel or override
		if templateOverride != "" {
			channel.PromptTemplate = templateOverride
		} else {
			// Use channel-specific templates
			switch channelName {
			case "fairy_tale":
				channel.PromptTemplate = "Create a short fairy tale story suitable for children. Include magical elements and a happy ending."
			case "horror":
				channel.PromptTemplate = "Create a short horror story with suspense and a twist ending. Keep it appropriate for YouTube."
			case "romance":
				channel.PromptTemplate = "Create a short romantic story with emotional depth and relatable characters."
			default:
				channel.PromptTemplate = cfg.Story.DefaultPrompt
			}
		}

		// Create story service
		storyService, err := story.NewServiceWithConfig(&cfg.API, &cfg.Story, cfg.HTTPClient.OpenAITimeout)
		if err != nil {
			return fmt.Errorf("failed to create story service: %w", err)
		}

		// Generate stories
		for i := 0; i < count; i++ {
			logger.Progress(fmt.Sprintf("Generating story %d/%d", i+1, count))

			// Generate story
			ctx := context.Background()
			storyResult, err := storyService.GenerateStory(ctx, channel)
			if err != nil {
				logger.Error("Failed to generate story", err)
				return fmt.Errorf("failed to generate story: %w", err)
			}

			logger.Success(fmt.Sprintf("Story generated: %s", storyResult.Title))

			// Save to output directory if specified
			if outputDir != "" && !dryRun {
				filename := fmt.Sprintf("%s_%d.json", channelName, i+1)
				outputPath := filepath.Join(outputDir, filename)
				
				// Create output directory if it doesn't exist
				if err := os.MkdirAll(outputDir, 0755); err != nil {
					return fmt.Errorf("failed to create output directory: %w", err)
				}

				// Marshal story to JSON
				data, err := json.MarshalIndent(storyResult, "", "  ")
				if err != nil {
					return fmt.Errorf("failed to marshal story: %w", err)
				}

				// Write to file
				if err := os.WriteFile(outputPath, data, 0644); err != nil {
					return fmt.Errorf("failed to write story file: %w", err)
				}

				logger.Progress(fmt.Sprintf("Story saved to: %s", outputPath))
			}

			// Dry run mode
			if dryRun {
				logger.Progress("Dry run mode - story not saved")
			}
		}

		logger.Success(fmt.Sprintf("Generated %d stories successfully", count))
		return nil
	},
}

func init() {
	generateCmd.Flags().StringP("channel", "c", "", "Channel name to generate content for (required)")
	generateCmd.Flags().StringP("output", "o", "", "Output directory for generated content")
	generateCmd.Flags().StringP("template", "t", "", "Override channel template")
	generateCmd.Flags().IntP("count", "n", 1, "Number of stories to generate")
	generateCmd.Flags().Bool("dry-run", false, "Perform a dry run without saving files")

	if err := generateCmd.MarkFlagRequired("channel"); err != nil {
		panic(fmt.Sprintf("failed to mark channel flag as required: %v", err))
	}
}