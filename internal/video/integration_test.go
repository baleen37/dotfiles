package video

import (
	"context"
	"log/slog"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/video/adapters"
	"ssulmeta-go/internal/video/core"
	"ssulmeta-go/internal/video/ports"
)

// TestVideoIntegration tests the video domain components working together
func TestVideoIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))

	t.Run("video domain components integration", func(t *testing.T) {
		// Create adapters
		ffmpegAdapter := adapters.NewFFmpegAdapter(logger)
		validator := adapters.NewVideoValidator(logger)

		// Create service with dependencies
		service := core.NewService(ffmpegAdapter, validator, logger)

		// Verify service is properly initialized
		require.NotNil(t, service)

		t.Log("Video domain integration test passed - all components properly initialized")
	})

	t.Run("ffmpeg checker integration", func(t *testing.T) {
		checker := adapters.NewFFmpegChecker()
		require.NotNil(t, checker)

		// Test basic functionality
		path := checker.GetFFmpegPath()
		assert.NotEmpty(t, path)

		t.Logf("FFmpeg checker initialized with path: %s", path)
	})

	t.Run("mock video composition workflow", func(t *testing.T) {
		// This test uses mocked components to verify the integration workflow
		ffmpegAdapter := adapters.NewFFmpegAdapter(logger)
		validator := adapters.NewVideoValidator(logger)
		service := core.NewService(ffmpegAdapter, validator, logger)

		// Create a minimal request for testing
		req := &ports.ComposeVideoRequest{
			Images: []ports.ImageFrame{
				{
					Path:      "/fake/image1.jpg",
					StartTime: time.Duration(0),
					Duration:  time.Second * 2,
				},
			},
			OutputPath: "/fake/output.mp4",
			Settings: ports.VideoSettings{
				Width:  1080,
				Height: 1920,
				FPS:    30,
			},
		}

		// In test environment, this should fail validation (file doesn't exist)
		_, err := service.ComposeVideo(context.Background(), req)
		require.Error(t, err, "Should fail with non-existent files")

		t.Log("Mock video composition workflow validation passed")
	})
}
