package core

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"testing"
	"time"

	"ssulmeta-go/internal/video/ports"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
)

// MockComposer is a mock implementation of ports.Composer
type MockComposer struct {
	mock.Mock
}

func (m *MockComposer) ComposeVideo(ctx context.Context, req *ports.ComposeVideoRequest) (*ports.ComposeVideoResponse, error) {
	args := m.Called(ctx, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*ports.ComposeVideoResponse), args.Error(1)
}

func (m *MockComposer) GenerateThumbnail(ctx context.Context, videoPath string, outputPath string, timeOffset time.Duration) error {
	args := m.Called(ctx, videoPath, outputPath, timeOffset)
	return args.Error(0)
}

func (m *MockComposer) GetDuration(ctx context.Context, videoPath string) (time.Duration, error) {
	args := m.Called(ctx, videoPath)
	return args.Get(0).(time.Duration), args.Error(1)
}

// MockValidator is a mock implementation of ports.Validator
type MockValidator struct {
	mock.Mock
}

func (m *MockValidator) ValidateVideo(ctx context.Context, videoPath string, expectedSettings ports.VideoSettings) (*ports.ValidationResult, error) {
	args := m.Called(ctx, videoPath, expectedSettings)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*ports.ValidationResult), args.Error(1)
}

func (m *MockValidator) ValidateAudioFile(ctx context.Context, audioPath string) error {
	args := m.Called(ctx, audioPath)
	return args.Error(0)
}

func (m *MockValidator) ValidateImageFile(ctx context.Context, imagePath string) error {
	args := m.Called(ctx, imagePath)
	return args.Error(0)
}

func TestNewService(t *testing.T) {
	composer := &MockComposer{}
	validator := &MockValidator{}
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))

	service := NewService(composer, validator, logger)

	assert.NotNil(t, service)
	assert.Equal(t, composer, service.composer)
	assert.Equal(t, validator, service.validator)
	assert.Equal(t, logger, service.logger)
}

func TestService_ComposeVideo_Success(t *testing.T) {
	composer := &MockComposer{}
	validator := &MockValidator{}
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))

	service := NewService(composer, validator, logger)

	ctx := context.Background()
	req := &ports.ComposeVideoRequest{
		Images: []ports.ImageFrame{
			{
				Path:      "/test/image1.jpg",
				Duration:  3 * time.Second,
				StartTime: 0,
				KenBurns: ports.KenBurnsEffect{
					StartZoom: 1.0,
					EndZoom:   1.1,
					StartX:    0.5,
					StartY:    0.5,
					EndX:      0.5,
					EndY:      0.5,
				},
			},
			{
				Path:      "/test/image2.jpg",
				Duration:  3 * time.Second,
				StartTime: 3 * time.Second,
				KenBurns: ports.KenBurnsEffect{
					StartZoom: 1.0,
					EndZoom:   1.1,
					StartX:    0.5,
					StartY:    0.5,
					EndX:      0.6,
					EndY:      0.4,
				},
			},
		},
		NarrationAudioPath:  "/test/narration.wav",
		BackgroundMusicPath: "/test/background.mp3",
		OutputPath:          "/test/output.mp4",
		Settings: ports.VideoSettings{
			Width:                 1080,
			Height:                1920,
			FrameRate:             30,
			VideoBitrate:          "2M",
			AudioBitrate:          "128k",
			Format:                "mp4",
			BackgroundMusicVolume: 0.3,
			NarrationVolume:       0.8,
		},
		TransitionDuration: 500 * time.Millisecond,
	}

	expectedResponse := &ports.ComposeVideoResponse{
		OutputPath:    "/test/output.mp4",
		Duration:      6 * time.Second,
		FileSize:      1024 * 1024 * 10, // 10MB
		ThumbnailPath: "/test/output_thumbnail.jpg",
	}

	// Mock expectations
	validator.On("ValidateImageFile", ctx, "/test/image1.jpg").Return(nil)
	validator.On("ValidateImageFile", ctx, "/test/image2.jpg").Return(nil)
	validator.On("ValidateAudioFile", ctx, "/test/narration.wav").Return(nil)
	validator.On("ValidateAudioFile", ctx, "/test/background.mp3").Return(nil)
	composer.On("ComposeVideo", ctx, mock.MatchedBy(func(r *ports.ComposeVideoRequest) bool {
		return len(r.Images) == 2 && r.OutputPath == "/test/output.mp4"
	})).Return(expectedResponse, nil)

	// Execute
	response, err := service.ComposeVideo(ctx, req)

	// Assert
	require.NoError(t, err)
	assert.Equal(t, expectedResponse, response)
	composer.AssertExpectations(t)
	validator.AssertExpectations(t)
}

func TestService_ComposeVideo_ValidationFailure(t *testing.T) {
	composer := &MockComposer{}
	validator := &MockValidator{}
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))

	service := NewService(composer, validator, logger)

	ctx := context.Background()
	req := &ports.ComposeVideoRequest{
		Images: []ports.ImageFrame{
			{Path: "/test/invalid_image.jpg", Duration: 3 * time.Second},
		},
		NarrationAudioPath: "/test/narration.wav",
		OutputPath:         "/test/output.mp4",
		Settings: ports.VideoSettings{
			Width:     1080,
			Height:    1920,
			FrameRate: 30,
		},
	}

	// Mock expectations - image validation fails
	validator.On("ValidateImageFile", ctx, "/test/invalid_image.jpg").Return(errors.New("invalid image format"))

	// Execute
	response, err := service.ComposeVideo(ctx, req)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, response)
	assert.Contains(t, err.Error(), "failed to validate image")
	validator.AssertExpectations(t)
}

func TestService_ComposeVideo_EmptyImages(t *testing.T) {
	composer := &MockComposer{}
	validator := &MockValidator{}
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))

	service := NewService(composer, validator, logger)

	ctx := context.Background()
	req := &ports.ComposeVideoRequest{
		Images:             []ports.ImageFrame{}, // Empty
		NarrationAudioPath: "/test/narration.wav",
		OutputPath:         "/test/output.mp4",
		Settings: ports.VideoSettings{
			Width:     1080,
			Height:    1920,
			FrameRate: 30,
		},
	}

	// Execute
	response, err := service.ComposeVideo(ctx, req)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, response)
	assert.Contains(t, err.Error(), "at least one image is required")
}

func TestService_ComposeVideo_InvalidOutputPath(t *testing.T) {
	composer := &MockComposer{}
	validator := &MockValidator{}
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))

	service := NewService(composer, validator, logger)

	ctx := context.Background()
	req := &ports.ComposeVideoRequest{
		Images: []ports.ImageFrame{
			{Path: "/test/image1.jpg", Duration: 3 * time.Second},
		},
		NarrationAudioPath: "/test/narration.wav",
		OutputPath:         "", // Empty output path
		Settings: ports.VideoSettings{
			Width:     1080,
			Height:    1920,
			FrameRate: 30,
		},
	}

	// Execute
	response, err := service.ComposeVideo(ctx, req)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, response)
	assert.Contains(t, err.Error(), "output path is required")
}

func TestService_CalculateImageTiming(t *testing.T) {
	composer := &MockComposer{}
	validator := &MockValidator{}
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))

	service := NewService(composer, validator, logger)

	images := []ports.ImageFrame{
		{Path: "/test/image1.jpg", Duration: 0}, // Will be calculated
		{Path: "/test/image2.jpg", Duration: 0}, // Will be calculated
		{Path: "/test/image3.jpg", Duration: 0}, // Will be calculated
	}

	totalDuration := 10 * time.Second
	transitionDuration := 500 * time.Millisecond

	result := service.calculateImageTiming(images, totalDuration, transitionDuration)

	// Assert
	assert.Len(t, result, 3)

	// Each image should get equal time minus transitions
	expectedDuration := (totalDuration - 2*transitionDuration) / 3
	for i, img := range result {
		assert.Equal(t, expectedDuration, img.Duration)
		expectedStartTime := time.Duration(i) * expectedDuration
		assert.Equal(t, expectedStartTime, img.StartTime)
	}
}

func TestService_GenerateKenBurnsEffect(t *testing.T) {
	composer := &MockComposer{}
	validator := &MockValidator{}
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))

	service := NewService(composer, validator, logger)

	tests := []struct {
		name         string
		sceneIndex   int
		totalScenes  int
		expectedZoom bool
		expectedPan  bool
	}{
		{
			name:         "first scene - zoom in",
			sceneIndex:   0,
			totalScenes:  3,
			expectedZoom: true,
			expectedPan:  true,
		},
		{
			name:         "middle scene - pan",
			sceneIndex:   1,
			totalScenes:  3,
			expectedZoom: true,
			expectedPan:  true,
		},
		{
			name:         "last scene - zoom out",
			sceneIndex:   2,
			totalScenes:  3,
			expectedZoom: true,
			expectedPan:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			effect := service.generateKenBurnsEffect(tt.sceneIndex, tt.totalScenes)

			// Verify zoom values are reasonable
			assert.GreaterOrEqual(t, effect.StartZoom, 1.0)
			assert.GreaterOrEqual(t, effect.EndZoom, 1.0)
			assert.LessOrEqual(t, effect.StartZoom, 1.2)
			assert.LessOrEqual(t, effect.EndZoom, 1.2)

			// Verify pan values are within valid range (0.0-1.0)
			assert.GreaterOrEqual(t, effect.StartX, 0.0)
			assert.LessOrEqual(t, effect.StartX, 1.0)
			assert.GreaterOrEqual(t, effect.StartY, 0.0)
			assert.LessOrEqual(t, effect.StartY, 1.0)
			assert.GreaterOrEqual(t, effect.EndX, 0.0)
			assert.LessOrEqual(t, effect.EndX, 1.0)
			assert.GreaterOrEqual(t, effect.EndY, 0.0)
			assert.LessOrEqual(t, effect.EndY, 1.0)
		})
	}
}

func TestService_ValidateVideoSettings(t *testing.T) {
	composer := &MockComposer{}
	validator := &MockValidator{}
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))

	service := NewService(composer, validator, logger)

	tests := []struct {
		name        string
		settings    ports.VideoSettings
		expectError bool
		errorMsg    string
	}{
		{
			name: "valid settings",
			settings: ports.VideoSettings{
				Width:                 1080,
				Height:                1920,
				FrameRate:             30,
				VideoBitrate:          "2M",
				AudioBitrate:          "128k",
				Format:                "mp4",
				BackgroundMusicVolume: 0.3,
				NarrationVolume:       0.8,
			},
			expectError: false,
		},
		{
			name: "invalid width",
			settings: ports.VideoSettings{
				Width:     0,
				Height:    1920,
				FrameRate: 30,
			},
			expectError: true,
			errorMsg:    "width must be greater than 0",
		},
		{
			name: "invalid height",
			settings: ports.VideoSettings{
				Width:     1080,
				Height:    0,
				FrameRate: 30,
			},
			expectError: true,
			errorMsg:    "height must be greater than 0",
		},
		{
			name: "invalid frame rate",
			settings: ports.VideoSettings{
				Width:     1080,
				Height:    1920,
				FrameRate: 0,
			},
			expectError: true,
			errorMsg:    "frame rate must be greater than 0",
		},
		{
			name: "invalid volume - too high",
			settings: ports.VideoSettings{
				Width:                 1080,
				Height:                1920,
				FrameRate:             30,
				BackgroundMusicVolume: 1.5, // Invalid
				NarrationVolume:       0.8,
			},
			expectError: true,
			errorMsg:    "background music volume must be between 0.0 and 1.0",
		},
		{
			name: "invalid volume - negative",
			settings: ports.VideoSettings{
				Width:                 1080,
				Height:                1920,
				FrameRate:             30,
				BackgroundMusicVolume: 0.3,
				NarrationVolume:       -0.1, // Invalid
			},
			expectError: true,
			errorMsg:    "narration volume must be between 0.0 and 1.0",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := service.validateVideoSettings(&tt.settings)

			if tt.expectError {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.errorMsg)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}
