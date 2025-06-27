package video

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"ssulmeta-go/pkg/models"
)

// MockComposer is a mock implementation of Composer
type MockComposer struct {
	assetPath string
}

// NewMockComposer creates a new mock composer
func NewMockComposer(assetPath string) *MockComposer {
	return &MockComposer{
		assetPath: assetPath,
	}
}

// ComposeVideo creates a mock video file
func (m *MockComposer) ComposeVideo(ctx context.Context, images []string, audioPath string, scenes []models.Scene) (*models.VideoMetadata, error) {
	// Create mock video directory
	mockDir := filepath.Join(m.assetPath, "mock_videos")
	if err := os.MkdirAll(mockDir, 0755); err != nil {
		return nil, err
	}

	// Create mock video file
	videoPath := filepath.Join(mockDir, fmt.Sprintf("video_%d.mp4", len(images)))
	file, err := os.Create(videoPath)
	if err != nil {
		return nil, err
	}
	if err := file.Close(); err != nil {
		return nil, fmt.Errorf("failed to close file: %w", err)
	}

	// Return mock metadata
	metadata := &models.VideoMetadata{
		FilePath:      videoPath,
		Duration:      60.0, // 60 seconds
		Width:         1080,
		Height:        1920,
		FPS:           30,
		FileSizeBytes: 1024 * 1024 * 10, // 10MB
	}

	return metadata, nil
}

// GenerateThumbnail creates a mock thumbnail
func (m *MockComposer) GenerateThumbnail(ctx context.Context, videoPath string) (string, error) {
	// Create mock thumbnail directory
	mockDir := filepath.Join(m.assetPath, "mock_thumbnails")
	if err := os.MkdirAll(mockDir, 0755); err != nil {
		return "", err
	}

	// Create mock thumbnail file
	thumbnailPath := filepath.Join(mockDir, "thumbnail.jpg")
	file, err := os.Create(thumbnailPath)
	if err != nil {
		return "", err
	}
	if err := file.Close(); err != nil {
		return "", fmt.Errorf("failed to close file: %w", err)
	}

	return thumbnailPath, nil
}
