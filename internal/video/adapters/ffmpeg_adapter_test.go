package adapters

import (
	"context"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/video/ports"
	"ssulmeta-go/pkg/errors"
)

func TestFFmpegAdapter_ComposeVideo(t *testing.T) {
	// Skip if ffmpeg not available
	if !isFFmpegAvailable() {
		t.Skip("ffmpeg not available")
	}

	adapter := NewFFmpegAdapter(slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug})))

	tests := []struct {
		name        string
		setupFunc   func(t *testing.T) *ports.ComposeVideoRequest
		expectError bool
		errorCode   string
	}{
		{
			name: "successful video composition",
			setupFunc: func(t *testing.T) *ports.ComposeVideoRequest {
				// Create test assets
				tempDir := t.TempDir()

				// Create test images
				image1 := createTestImage(t, tempDir, "image1.jpg")
				image2 := createTestImage(t, tempDir, "image2.jpg")

				// Create test audio
				audio := createTestAudio(t, tempDir, "audio.mp3")

				return &ports.ComposeVideoRequest{
					Images: []ports.ImageFrame{
						{
							Path:      image1,
							StartTime: time.Duration(0),
							Duration:  time.Second * 2,
							KenBurns: ports.KenBurnsEffect{
								StartZoom: 1.0,
								EndZoom:   1.1,
								StartX:    0.5,
								StartY:    0.5,
								EndX:      0.6,
								EndY:      0.4,
							},
						},
						{
							Path:      image2,
							StartTime: time.Second * 2,
							Duration:  time.Second * 2,
							KenBurns: ports.KenBurnsEffect{
								StartZoom: 1.1,
								EndZoom:   1.0,
								StartX:    0.6,
								StartY:    0.4,
								EndX:      0.5,
								EndY:      0.5,
							},
						},
					},
					NarrationAudioPath: audio,
					OutputPath:         filepath.Join(tempDir, "output.mp4"),
					Settings: ports.VideoSettings{
						Width:        1080,
						Height:       1920,
						FPS:          30,
						Bitrate:      "2M",
						AudioBitrate: "128k",
					},
					TransitionDuration: time.Millisecond * 500,
				}
			},
			expectError: false,
		},
		{
			name: "invalid image path",
			setupFunc: func(t *testing.T) *ports.ComposeVideoRequest {
				tempDir := t.TempDir()

				return &ports.ComposeVideoRequest{
					Images: []ports.ImageFrame{
						{
							Path:      "/nonexistent/image.jpg",
							StartTime: time.Duration(0),
							Duration:  time.Second * 2,
						},
					},
					NarrationAudioPath: createTestAudio(t, tempDir, "audio.mp3"),
					OutputPath:         filepath.Join(tempDir, "output.mp4"),
					Settings: ports.VideoSettings{
						Width:   1080,
						Height:  1920,
						FPS:     30,
						Bitrate: "2M",
					},
				}
			},
			expectError: true,
			errorCode:   errors.CodeVideoCompositionFailed,
		},
		{
			name: "invalid audio path",
			setupFunc: func(t *testing.T) *ports.ComposeVideoRequest {
				tempDir := t.TempDir()
				image1 := createTestImage(t, tempDir, "image1.jpg")

				return &ports.ComposeVideoRequest{
					Images: []ports.ImageFrame{
						{
							Path:      image1,
							StartTime: time.Duration(0),
							Duration:  time.Second * 2,
						},
					},
					NarrationAudioPath: "/nonexistent/audio.mp3",
					OutputPath:         filepath.Join(tempDir, "output.mp4"),
					Settings: ports.VideoSettings{
						Width:   1080,
						Height:  1920,
						FPS:     30,
						Bitrate: "2M",
					},
				}
			},
			expectError: true,
			errorCode:   errors.CodeVideoCompositionFailed,
		},
		{
			name: "invalid output directory",
			setupFunc: func(t *testing.T) *ports.ComposeVideoRequest {
				tempDir := t.TempDir()

				return &ports.ComposeVideoRequest{
					Images: []ports.ImageFrame{
						{
							Path:      createTestImage(t, tempDir, "image1.jpg"),
							StartTime: time.Duration(0),
							Duration:  time.Second * 2,
						},
					},
					NarrationAudioPath: createTestAudio(t, tempDir, "audio.mp3"),
					OutputPath:         "/nonexistent/directory/output.mp4",
					Settings: ports.VideoSettings{
						Width:   1080,
						Height:  1920,
						FPS:     30,
						Bitrate: "2M",
					},
				}
			},
			expectError: true,
			errorCode:   errors.CodeVideoCompositionFailed,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := tt.setupFunc(t)

			response, err := adapter.ComposeVideo(context.Background(), req)

			if tt.expectError {
				require.Error(t, err)
				var appErr *errors.AppError
				require.ErrorAs(t, err, &appErr)
				assert.Equal(t, tt.errorCode, appErr.Code)
				assert.Nil(t, response)
			} else {
				require.NoError(t, err)
				require.NotNil(t, response)

				// Verify output file exists
				assert.FileExists(t, response.OutputPath)

				// Verify response values
				assert.Equal(t, req.OutputPath, response.OutputPath)
				assert.Greater(t, response.Duration, time.Duration(0))
				assert.Greater(t, response.FileSize, int64(0))

				// Verify video properties using ffprobe
				duration, err := adapter.GetDuration(context.Background(), response.OutputPath)
				require.NoError(t, err)
				assert.Greater(t, duration, time.Duration(0))
			}
		})
	}
}

func TestFFmpegAdapter_GenerateThumbnail(t *testing.T) {
	if !isFFmpegAvailable() {
		t.Skip("ffmpeg not available")
	}

	adapter := NewFFmpegAdapter(slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug})))

	tests := []struct {
		name        string
		setupFunc   func(t *testing.T) (string, string)
		timeOffset  time.Duration
		expectError bool
		errorCode   string
	}{
		{
			name: "successful thumbnail generation",
			setupFunc: func(t *testing.T) (string, string) {
				tempDir := t.TempDir()

				// Create a simple test video
				videoPath := filepath.Join(tempDir, "test.mp4")
				thumbnailPath := filepath.Join(tempDir, "thumbnail.jpg")

				// Create test video with ffmpeg
				err := createTestVideo(t, videoPath)
				require.NoError(t, err)

				return videoPath, thumbnailPath
			},
			timeOffset:  time.Second * 1,
			expectError: false,
		},
		{
			name: "nonexistent video file",
			setupFunc: func(t *testing.T) (string, string) {
				tempDir := t.TempDir()
				return "/nonexistent/video.mp4", filepath.Join(tempDir, "thumbnail.jpg")
			},
			timeOffset:  time.Second * 1,
			expectError: true,
			errorCode:   errors.CodeVideoCompositionFailed,
		},
		{
			name: "invalid output directory",
			setupFunc: func(t *testing.T) (string, string) {
				tempDir := t.TempDir()
				videoPath := filepath.Join(tempDir, "test.mp4")
				err := createTestVideo(t, videoPath)
				require.NoError(t, err)

				return videoPath, "/nonexistent/directory/thumbnail.jpg"
			},
			timeOffset:  time.Second * 1,
			expectError: true,
			errorCode:   errors.CodeVideoCompositionFailed,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			videoPath, thumbnailPath := tt.setupFunc(t)

			err := adapter.GenerateThumbnail(context.Background(), videoPath, thumbnailPath, tt.timeOffset)

			if tt.expectError {
				require.Error(t, err)
				var appErr *errors.AppError
				require.ErrorAs(t, err, &appErr)
				assert.Equal(t, tt.errorCode, appErr.Code)
			} else {
				require.NoError(t, err)
				assert.FileExists(t, thumbnailPath)
			}
		})
	}
}

func TestFFmpegAdapter_GetDuration(t *testing.T) {
	if !isFFmpegAvailable() {
		t.Skip("ffmpeg not available")
	}

	adapter := NewFFmpegAdapter(slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug})))

	tests := []struct {
		name        string
		setupFunc   func(t *testing.T) string
		expectError bool
		errorCode   string
	}{
		{
			name: "get duration from valid video",
			setupFunc: func(t *testing.T) string {
				tempDir := t.TempDir()
				videoPath := filepath.Join(tempDir, "test.mp4")
				err := createTestVideo(t, videoPath)
				require.NoError(t, err)
				return videoPath
			},
			expectError: false,
		},
		{
			name: "nonexistent video file",
			setupFunc: func(t *testing.T) string {
				return "/nonexistent/video.mp4"
			},
			expectError: true,
			errorCode:   errors.CodeVideoCompositionFailed,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			videoPath := tt.setupFunc(t)

			duration, err := adapter.GetDuration(context.Background(), videoPath)

			if tt.expectError {
				require.Error(t, err)
				var appErr *errors.AppError
				require.ErrorAs(t, err, &appErr)
				assert.Equal(t, tt.errorCode, appErr.Code)
				assert.Equal(t, time.Duration(0), duration)
			} else {
				require.NoError(t, err)
				assert.Greater(t, duration, time.Duration(0))
			}
		})
	}
}

// Helper functions for creating test assets

func createTestImage(t *testing.T, dir, filename string) string {
	t.Helper()

	imagePath := filepath.Join(dir, filename)

	// Create a dummy file for testing
	file, err := os.Create(imagePath)
	require.NoError(t, err, "Failed to create test image file")
	defer file.Close()

	// Write minimal image content
	_, err = file.WriteString("fake image content")
	require.NoError(t, err, "Failed to write test image content")

	return imagePath
}

func createTestAudio(t *testing.T, dir, filename string) string {
	t.Helper()

	audioPath := filepath.Join(dir, filename)

	// Create a dummy file for testing
	file, err := os.Create(audioPath)
	require.NoError(t, err, "Failed to create test audio file")
	defer file.Close()

	// Write minimal audio content
	_, err = file.WriteString("fake audio content")
	require.NoError(t, err, "Failed to write test audio content")

	return audioPath
}

func createTestVideo(t *testing.T, videoPath string) error {
	t.Helper()

	// Create a dummy file for testing
	file, err := os.Create(videoPath)
	if err != nil {
		return err
	}
	defer file.Close()

	// Write minimal video content
	_, err = file.WriteString("fake video content")
	return err
}

func isFFmpegAvailable() bool {
	// In test environment, we'll mock this
	return strings.Contains(os.Getenv("PATH"), "ffmpeg") ||
		os.Getenv("SKIP_FFMPEG_TESTS") != "true"
}
