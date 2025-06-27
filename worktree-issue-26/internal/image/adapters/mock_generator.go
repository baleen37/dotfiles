package adapters

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	"ssulmeta-go/internal/image/ports"
	"ssulmeta-go/pkg/models"
)

// MockGenerator is a mock implementation of Generator
type MockGenerator struct {
	assetPath string
}

// NewMockGenerator creates a new mock generator
func NewMockGenerator(assetPath string) ports.Generator {
	return &MockGenerator{
		assetPath: assetPath,
	}
}

// GenerateImage returns a path to a sample image
func (m *MockGenerator) GenerateImage(ctx context.Context, prompt string) (string, error) {
	// Create mock image directory
	mockDir := filepath.Join(m.assetPath, "mock_images")
	if err := os.MkdirAll(mockDir, 0755); err != nil {
		return "", err
	}

	// Return path to a placeholder image
	// In real implementation, we would copy a sample image here
	imagePath := filepath.Join(mockDir, fmt.Sprintf("image_%d.jpg", len(prompt)%5))

	// Create a placeholder file
	file, err := os.Create(imagePath)
	if err != nil {
		return "", err
	}
	if err := file.Close(); err != nil {
		return "", fmt.Errorf("failed to close file: %w", err)
	}

	return imagePath, nil
}

// GenerateSceneImages generates mock images for all scenes
func (m *MockGenerator) GenerateSceneImages(ctx context.Context, scenes []models.Scene) ([]string, error) {
	images := make([]string, len(scenes))

	for i, scene := range scenes {
		image, err := m.GenerateImage(ctx, scene.ImagePrompt)
		if err != nil {
			return nil, fmt.Errorf("failed to generate image for scene %d: %w", scene.Number, err)
		}
		images[i] = image
	}

	return images, nil
}
