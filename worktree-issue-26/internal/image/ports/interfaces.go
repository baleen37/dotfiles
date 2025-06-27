package ports

import (
	"context"
	"ssulmeta-go/pkg/models"
)

// Generator defines the interface for image generation
type Generator interface {
	// GenerateImage generates an image based on the prompt
	GenerateImage(ctx context.Context, prompt string) (string, error)

	// GenerateSceneImages generates images for all scenes
	GenerateSceneImages(ctx context.Context, scenes []models.Scene) ([]string, error)
}

// PromptBuilder defines the interface for building image prompts
type PromptBuilder interface {
	// BuildPrompt creates an image generation prompt from scene description
	BuildPrompt(scene models.Scene, style string) string

	// BuildPromptsForStory creates prompts for all scenes maintaining style consistency
	BuildPromptsForStory(scenes []models.Scene, style string) []string
}

// ImageProcessor defines the interface for post-processing images
type ImageProcessor interface {
	// ResizeImage resizes an image to specified dimensions
	ResizeImage(ctx context.Context, imagePath string, width, height int) (string, error)

	// ValidateImage checks if image meets requirements
	ValidateImage(ctx context.Context, imagePath string) error
}
