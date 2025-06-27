package adapters

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"ssulmeta-go/internal/image/ports"
)

// MockProcessor is a mock implementation of ImageProcessor
type MockProcessor struct{}

// NewMockProcessor creates a new mock processor
func NewMockProcessor() ports.ImageProcessor {
	return &MockProcessor{}
}

// ResizeImage simulates image resizing
func (m *MockProcessor) ResizeImage(ctx context.Context, imagePath string, width, height int) (string, error) {
	// Check if input file exists
	if _, err := os.Stat(imagePath); err != nil {
		return "", fmt.Errorf("input image not found: %w", err)
	}

	// Create resized file path
	dir := filepath.Dir(imagePath)
	base := filepath.Base(imagePath)
	ext := filepath.Ext(base)
	nameWithoutExt := strings.TrimSuffix(base, ext)

	resizedPath := filepath.Join(dir, fmt.Sprintf("%s_resized_%dx%d%s", nameWithoutExt, width, height, ext))

	// Create a placeholder file for the resized image
	file, err := os.Create(resizedPath)
	if err != nil {
		return "", fmt.Errorf("failed to create resized image: %w", err)
	}
	if err := file.Close(); err != nil {
		return "", fmt.Errorf("failed to close file: %w", err)
	}

	return resizedPath, nil
}

// ValidateImage simulates image validation
func (m *MockProcessor) ValidateImage(ctx context.Context, imagePath string) error {
	// Check if file exists
	info, err := os.Stat(imagePath)
	if err != nil {
		return fmt.Errorf("image not found: %w", err)
	}

	// Check if it's not a directory
	if info.IsDir() {
		return fmt.Errorf("path is a directory, not an image")
	}

	// Check file extension
	ext := strings.ToLower(filepath.Ext(imagePath))
	validExtensions := map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".webp": true,
	}

	if !validExtensions[ext] {
		return fmt.Errorf("invalid image format: %s", ext)
	}

	// In a real implementation, we would check:
	// - Image dimensions
	// - File size
	// - Color depth
	// - Corruption

	return nil
}
