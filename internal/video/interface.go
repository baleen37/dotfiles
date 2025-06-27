package video

import (
	"context"
	"ssulmeta-go/pkg/models"
)

// Composer defines the interface for video composition
type Composer interface {
	// ComposeVideo creates a video from images and audio
	ComposeVideo(ctx context.Context, images []string, audioPath string, scenes []models.Scene) (*models.VideoMetadata, error)

	// GenerateThumbnail generates a thumbnail from the video
	GenerateThumbnail(ctx context.Context, videoPath string) (string, error)
}
