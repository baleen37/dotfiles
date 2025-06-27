package image

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
