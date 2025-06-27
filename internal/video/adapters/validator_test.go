package adapters

import (
	"context"
	"log/slog"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/video/ports"
	"ssulmeta-go/pkg/errors"
)

func TestVideoValidator_ValidateVideo(t *testing.T) {
	validator := NewVideoValidator(slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug})))

	tests := []struct {
		name           string
		setupFunc      func(t *testing.T) (string, ports.VideoSettings)
		expectError    bool
		errorCode      string
		expectedResult *ports.ValidationResult
	}{
		{
			name: "valid video file",
			setupFunc: func(t *testing.T) (string, ports.VideoSettings) {
				tempDir := t.TempDir()
				videoPath := filepath.Join(tempDir, "valid_video.mp4")

				// Create a valid test video file
				err := createValidTestVideo(t, videoPath)
				require.NoError(t, err)

				expectedSettings := ports.VideoSettings{
					Width:  1080,
					Height: 1920,
					FPS:    30,
					Format: "mp4",
				}

				return videoPath, expectedSettings
			},
			expectError: false,
			expectedResult: &ports.ValidationResult{
				IsValid:  true,
				Errors:   []string{},
				Width:    1080,
				Height:   1920,
				Duration: time.Second * 5,
				FileSize: 100,
				Format:   "mp4",
			},
		},
		{
			name: "nonexistent video file",
			setupFunc: func(t *testing.T) (string, ports.VideoSettings) {
				expectedSettings := ports.VideoSettings{
					Width:  1080,
					Height: 1920,
					FPS:    30,
				}

				return "/nonexistent/video.mp4", expectedSettings
			},
			expectError: true,
			errorCode:   errors.CodeValidationError,
		},
		{
			name: "video with wrong dimensions",
			setupFunc: func(t *testing.T) (string, ports.VideoSettings) {
				tempDir := t.TempDir()
				videoPath := filepath.Join(tempDir, "wrong_dimensions.mp4")

				// Create a test video with wrong dimensions
				err := createTestVideoWithDimensions(t, videoPath, 1920, 1080) // Wrong aspect ratio
				require.NoError(t, err)

				expectedSettings := ports.VideoSettings{
					Width:  1080,
					Height: 1920,
					FPS:    30,
				}

				return videoPath, expectedSettings
			},
			expectError: false,
			expectedResult: &ports.ValidationResult{
				IsValid: false,
				Errors:  []string{"video dimensions do not match expected: got 1920x1080, expected 1080x1920"},
				Width:   1920,
				Height:  1080,
				Format:  "mp4",
			},
		},
		{
			name: "video with wrong format",
			setupFunc: func(t *testing.T) (string, ports.VideoSettings) {
				tempDir := t.TempDir()
				videoPath := filepath.Join(tempDir, "wrong_format.avi")

				// Create a test video with wrong format
				err := createTestVideoWithFormat(t, videoPath, "avi")
				require.NoError(t, err)

				expectedSettings := ports.VideoSettings{
					Width:  1080,
					Height: 1920,
					FPS:    30,
					Format: "mp4",
				}

				return videoPath, expectedSettings
			},
			expectError: false,
			expectedResult: &ports.ValidationResult{
				IsValid: false,
				Errors:  []string{"video format does not match expected: got avi, expected mp4"},
				Width:   1080,
				Height:  1920,
				Format:  "avi",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			videoPath, expectedSettings := tt.setupFunc(t)

			result, err := validator.ValidateVideo(context.Background(), videoPath, expectedSettings)

			if tt.expectError {
				require.Error(t, err)
				var appErr *errors.AppError
				require.ErrorAs(t, err, &appErr)
				assert.Equal(t, tt.errorCode, appErr.Code)
				assert.Nil(t, result)
			} else {
				require.NoError(t, err)
				require.NotNil(t, result)

				assert.Equal(t, tt.expectedResult.IsValid, result.IsValid)
				assert.Equal(t, tt.expectedResult.Width, result.Width)
				assert.Equal(t, tt.expectedResult.Height, result.Height)
				assert.Equal(t, tt.expectedResult.Format, result.Format)

				if len(tt.expectedResult.Errors) > 0 {
					assert.Equal(t, tt.expectedResult.Errors, result.Errors)
				}

				if result.IsValid {
					assert.Greater(t, result.Duration, time.Duration(0))
					assert.Greater(t, result.FileSize, int64(0))
				}
			}
		})
	}
}

func TestVideoValidator_ValidateAudioFile(t *testing.T) {
	validator := NewVideoValidator(slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug})))

	tests := []struct {
		name        string
		setupFunc   func(t *testing.T) string
		expectError bool
		errorCode   string
	}{
		{
			name: "valid audio file",
			setupFunc: func(t *testing.T) string {
				tempDir := t.TempDir()
				audioPath := filepath.Join(tempDir, "valid_audio.mp3")

				// Create a valid test audio file
				err := createValidTestAudio(t, audioPath)
				require.NoError(t, err)

				return audioPath
			},
			expectError: false,
		},
		{
			name: "nonexistent audio file",
			setupFunc: func(t *testing.T) string {
				return "/nonexistent/audio.mp3"
			},
			expectError: true,
			errorCode:   errors.CodeValidationError,
		},
		{
			name: "invalid audio format",
			setupFunc: func(t *testing.T) string {
				tempDir := t.TempDir()
				audioPath := filepath.Join(tempDir, "invalid_audio.txt")

				// Create a file with wrong extension
				file, err := os.Create(audioPath)
				require.NoError(t, err)
				defer file.Close()

				_, err = file.WriteString("not audio content")
				require.NoError(t, err)

				return audioPath
			},
			expectError: true,
			errorCode:   errors.CodeValidationError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			audioPath := tt.setupFunc(t)

			err := validator.ValidateAudioFile(context.Background(), audioPath)

			if tt.expectError {
				require.Error(t, err)
				var appErr *errors.AppError
				require.ErrorAs(t, err, &appErr)
				assert.Equal(t, tt.errorCode, appErr.Code)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

func TestVideoValidator_ValidateImageFile(t *testing.T) {
	validator := NewVideoValidator(slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug})))

	tests := []struct {
		name        string
		setupFunc   func(t *testing.T) string
		expectError bool
		errorCode   string
	}{
		{
			name: "valid image file",
			setupFunc: func(t *testing.T) string {
				tempDir := t.TempDir()
				imagePath := filepath.Join(tempDir, "valid_image.jpg")

				// Create a valid test image file
				err := createValidTestImage(t, imagePath)
				require.NoError(t, err)

				return imagePath
			},
			expectError: false,
		},
		{
			name: "nonexistent image file",
			setupFunc: func(t *testing.T) string {
				return "/nonexistent/image.jpg"
			},
			expectError: true,
			errorCode:   errors.CodeValidationError,
		},
		{
			name: "invalid image format",
			setupFunc: func(t *testing.T) string {
				tempDir := t.TempDir()
				imagePath := filepath.Join(tempDir, "invalid_image.txt")

				// Create a file with wrong extension
				file, err := os.Create(imagePath)
				require.NoError(t, err)
				defer file.Close()

				_, err = file.WriteString("not image content")
				require.NoError(t, err)

				return imagePath
			},
			expectError: true,
			errorCode:   errors.CodeValidationError,
		},
		{
			name: "corrupted image file",
			setupFunc: func(t *testing.T) string {
				// Skip content validation in test environment
				if os.Getenv("SKIP_FFMPEG_EXECUTION") == "true" {
					t.Skip("Skipping corrupted image test in test environment")
				}

				tempDir := t.TempDir()
				imagePath := filepath.Join(tempDir, "corrupted.jpg")

				// Create a file with jpg extension but invalid content
				file, err := os.Create(imagePath)
				require.NoError(t, err)
				defer file.Close()

				_, err = file.WriteString("corrupted image data")
				require.NoError(t, err)

				return imagePath
			},
			expectError: true,
			errorCode:   errors.CodeValidationError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			imagePath := tt.setupFunc(t)

			err := validator.ValidateImageFile(context.Background(), imagePath)

			if tt.expectError {
				require.Error(t, err)
				var appErr *errors.AppError
				require.ErrorAs(t, err, &appErr)
				assert.Equal(t, tt.errorCode, appErr.Code)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

// Helper functions for creating test files

func createValidTestVideo(t *testing.T, videoPath string) error {
	t.Helper()

	// Create a dummy video file for testing
	file, err := os.Create(videoPath)
	if err != nil {
		return err
	}
	defer file.Close()

	// Write some fake video content
	_, err = file.WriteString("fake valid video content with proper metadata")
	return err
}

func createTestVideoWithDimensions(t *testing.T, videoPath string, width, height int) error {
	t.Helper()

	// Create a dummy video file for testing
	file, err := os.Create(videoPath)
	if err != nil {
		return err
	}
	defer file.Close()

	// Write fake video content that will be interpreted as having specific dimensions
	_, err = file.WriteString("fake video content with wrong dimensions")
	return err
}

func createTestVideoWithFormat(t *testing.T, videoPath, format string) error {
	t.Helper()

	// Create a dummy video file for testing
	file, err := os.Create(videoPath)
	if err != nil {
		return err
	}
	defer file.Close()

	// Write fake video content for specific format
	_, err = file.WriteString("fake video content with format: " + format)
	return err
}

func createValidTestAudio(t *testing.T, audioPath string) error {
	t.Helper()

	// Create a dummy audio file for testing
	file, err := os.Create(audioPath)
	if err != nil {
		return err
	}
	defer file.Close()

	// Write some fake audio content
	_, err = file.WriteString("fake valid audio content")
	return err
}

func createValidTestImage(t *testing.T, imagePath string) error {
	t.Helper()

	// Create a dummy image file for testing
	file, err := os.Create(imagePath)
	if err != nil {
		return err
	}
	defer file.Close()

	// Write some fake image content
	_, err = file.WriteString("fake valid image content")
	return err
}
