package youtube

import (
	"context"
	"ssulmeta-go/pkg/models"
)

// Uploader defines the interface for YouTube upload
type Uploader interface {
	// UploadVideo uploads a video to YouTube
	UploadVideo(ctx context.Context, videoPath string, metadata *models.YouTubeMetadata) (videoID string, url string, err error)

	// UpdateVideoMetadata updates metadata for an existing video
	UpdateVideoMetadata(ctx context.Context, videoID string, metadata *models.YouTubeMetadata) error
}
