package youtube

import (
	"context"
	"fmt"
	"ssulmeta-go/pkg/models"
	"time"
)

// MockUploader is a mock implementation of Uploader
type MockUploader struct{}

// NewMockUploader creates a new mock uploader
func NewMockUploader() *MockUploader {
	return &MockUploader{}
}

// UploadVideo simulates video upload
func (m *MockUploader) UploadVideo(ctx context.Context, videoPath string, metadata *models.YouTubeMetadata) (string, string, error) {
	// Simulate upload delay
	select {
	case <-time.After(2 * time.Second):
		// Upload "completed"
	case <-ctx.Done():
		return "", "", ctx.Err()
	}

	// Return mock video ID and URL
	videoID := fmt.Sprintf("mock_%d", time.Now().Unix())
	url := fmt.Sprintf("https://youtube.com/shorts/%s", videoID)

	return videoID, url, nil
}

// UpdateVideoMetadata simulates metadata update
func (m *MockUploader) UpdateVideoMetadata(ctx context.Context, videoID string, metadata *models.YouTubeMetadata) error {
	// Simulate API call
	select {
	case <-time.After(500 * time.Millisecond):
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}
