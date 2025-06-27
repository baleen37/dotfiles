package core

import (
	"context"
	"fmt"
	"log/slog"

	"ssulmeta-go/internal/image/ports"
	"ssulmeta-go/pkg/models"
)

// Service represents the image generation service
type Service struct {
	generator     ports.Generator
	promptBuilder ports.PromptBuilder
	processor     ports.ImageProcessor
	logger        *slog.Logger
}

// NewService creates a new image service
func NewService(
	generator ports.Generator,
	promptBuilder ports.PromptBuilder,
	processor ports.ImageProcessor,
	logger *slog.Logger,
) *Service {
	return &Service{
		generator:     generator,
		promptBuilder: promptBuilder,
		processor:     processor,
		logger:        logger.With("service", "image"),
	}
}

// GenerateStoryImages generates images for all scenes in a story
func (s *Service) GenerateStoryImages(ctx context.Context, story models.Story, channelStyle string) ([]string, error) {
	s.logger.Info("Starting image generation for story",
		"title", story.Title,
		"scene_count", len(story.Scenes),
	)

	// Build prompts for all scenes with style consistency
	prompts := s.promptBuilder.BuildPromptsForStory(story.Scenes, channelStyle)

	// Update scenes with generated prompts
	updatedScenes := make([]models.Scene, len(story.Scenes))
	for i, scene := range story.Scenes {
		updatedScenes[i] = scene
		updatedScenes[i].ImagePrompt = prompts[i]
	}

	// Generate images
	imagePaths, err := s.generator.GenerateSceneImages(ctx, updatedScenes)
	if err != nil {
		s.logger.Error("Failed to generate images",
			"error", err,
			"story_title", story.Title,
		)
		return nil, fmt.Errorf("failed to generate images: %w", err)
	}

	// Process images (resize, validate)
	processedPaths := make([]string, len(imagePaths))
	for i, imagePath := range imagePaths {
		// Validate image
		if err := s.processor.ValidateImage(ctx, imagePath); err != nil {
			s.logger.Warn("Image validation failed, attempting to regenerate",
				"scene", i+1,
				"error", err,
			)

			// Retry generation for this scene
			retryPath, retryErr := s.generator.GenerateImage(ctx, prompts[i])
			if retryErr != nil {
				return nil, fmt.Errorf("failed to regenerate image for scene %d: %w", i+1, retryErr)
			}
			imagePath = retryPath
		}

		// Resize to YouTube Shorts format (1080x1920)
		resizedPath, err := s.processor.ResizeImage(ctx, imagePath, 1080, 1920)
		if err != nil {
			s.logger.Error("Failed to resize image",
				"scene", i+1,
				"error", err,
			)
			// Use original if resize fails
			processedPaths[i] = imagePath
		} else {
			processedPaths[i] = resizedPath
		}
	}

	s.logger.Info("Successfully generated images for story",
		"title", story.Title,
		"image_count", len(processedPaths),
	)

	return processedPaths, nil
}

// GenerateSingleImage generates a single image with the given prompt
func (s *Service) GenerateSingleImage(ctx context.Context, prompt string) (string, error) {
	s.logger.Info("Generating single image", "prompt_length", len(prompt))

	// Add vertical format specification
	verticalPrompt := fmt.Sprintf("%s, vertical orientation, 9:16 aspect ratio", prompt)

	// Generate image
	imagePath, err := s.generator.GenerateImage(ctx, verticalPrompt)
	if err != nil {
		s.logger.Error("Failed to generate image", "error", err)
		return "", fmt.Errorf("failed to generate image: %w", err)
	}

	// Validate and process
	if err := s.processor.ValidateImage(ctx, imagePath); err != nil {
		s.logger.Warn("Image validation failed", "error", err)
		// Continue with processing anyway
	}

	// Resize to YouTube Shorts format
	resizedPath, err := s.processor.ResizeImage(ctx, imagePath, 1080, 1920)
	if err != nil {
		s.logger.Error("Failed to resize image", "error", err)
		// Return original if resize fails
		return imagePath, nil
	}

	return resizedPath, nil
}
