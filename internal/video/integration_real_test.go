//go:build !skip_real_media
// +build !skip_real_media

package video_test

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"testing"
	"time"

	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/video/adapters"
	"ssulmeta-go/internal/video/core"
	"ssulmeta-go/internal/video/ports"
	"ssulmeta-go/internal/video/testutil"
	"ssulmeta-go/pkg/logger"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestVideoGeneration_RealMedia(t *testing.T) {
	// Skip if ffmpeg not available
	if os.Getenv("SKIP_FFMPEG_EXECUTION") == "true" {
		t.Skip("Skipping real media test: SKIP_FFMPEG_EXECUTION=true")
	}

	// Check if ffmpeg is available
	checker := adapters.NewFFmpegChecker()
	if !checker.IsAvailable() {
		t.Skip("Skipping real media test: ffmpeg not available")
	}

	// Initialize logger
	logCfg := &config.LoggingConfig{
		Level:  "debug",
		Format: "text",
	}
	require.NoError(t, logger.Init(logCfg))

	// Create test media files
	testDataDir := filepath.Join("testdata", "real_media_test")
	require.NoError(t, testutil.CreateTestMediaFiles(testDataDir))
	defer func() {
		if err := testutil.CleanupTestMedia(testDataDir); err != nil {
			t.Logf("Failed to cleanup test media: %v", err)
		}
	}()

	// Create video service with real adapters
	composer := adapters.NewFFmpegComposer()
	validator := adapters.NewValidator()
	logger := slog.Default()
	service := core.NewService(composer, validator, logger)

	tests := []struct {
		name     string
		request  *ports.ComposeVideoRequest
		wantErr  bool
		validate func(t *testing.T, outputPath string)
	}{
		{
			name: "single scene video",
			request: &ports.ComposeVideoRequest{
				Images: []ports.ImageFrame{
					{
						Path:     filepath.Join(testDataDir, "images", "test_1.jpg"),
						Duration: 3.0 * time.Second,
					},
				},
				NarrationAudioPath: filepath.Join(testDataDir, "audio", "narration.wav"),
				OutputPath:         filepath.Join(testDataDir, "output", "single_scene.mp4"),
				Settings: ports.VideoSettings{
					Width:           1080,
					Height:          1920,
					FPS:             30,
					NarrationVolume: 1.0,
					AudioBitrate:    "128k",
				},
			},
			validate: func(t *testing.T, outputPath string) {
				// Check file exists
				info, err := os.Stat(outputPath)
				require.NoError(t, err)
				assert.True(t, info.Size() > 0)

				// TODO: Use ffprobe to validate video properties
			},
		},
		{
			name: "multi scene video with background music",
			request: &ports.ComposeVideoRequest{
				Images: []ports.ImageFrame{
					{
						Path:     filepath.Join(testDataDir, "images", "test_1.jpg"),
						Duration: 2.0 * time.Second,
					},
					{
						Path:     filepath.Join(testDataDir, "images", "test_2.jpg"),
						Duration: 2.0 * time.Second,
					},
					{
						Path:     filepath.Join(testDataDir, "images", "test_3.jpg"),
						Duration: 1.0 * time.Second,
					},
				},
				NarrationAudioPath:  filepath.Join(testDataDir, "audio", "narration.wav"),
				BackgroundMusicPath: filepath.Join(testDataDir, "audio", "background.wav"),
				OutputPath:          filepath.Join(testDataDir, "output", "multi_scene.mp4"),
				Settings: ports.VideoSettings{
					Width:                 1080,
					Height:                1920,
					FPS:                   30,
					NarrationVolume:       1.0,
					BackgroundMusicVolume: 0.3,
					AudioBitrate:          "128k",
				},
			},
			validate: func(t *testing.T, outputPath string) {
				// Check file exists
				info, err := os.Stat(outputPath)
				require.NoError(t, err)
				assert.True(t, info.Size() > 0)

				// Validate with actual validator
				validator := adapters.NewValidator()
				expectedSettings := ports.VideoSettings{
					Width:  1080,
					Height: 1920,
					Format: "mp4",
				}
				result, err := validator.ValidateVideo(context.Background(), outputPath, expectedSettings)
				require.NoError(t, err)

				assert.Equal(t, "mp4", result.Format)
				assert.Equal(t, 1080, result.Width)
				assert.Equal(t, 1920, result.Height)
				assert.True(t, result.Duration >= 4500*time.Millisecond && result.Duration <= 5500*time.Millisecond) // ~5 seconds
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()

			// Ensure output directory exists
			require.NoError(t, os.MkdirAll(filepath.Dir(tt.request.OutputPath), 0755))

			// Compose video
			resp, err := service.ComposeVideo(ctx, tt.request)
			if tt.wantErr {
				assert.Error(t, err)
				return
			}

			require.NoError(t, err)
			require.NotNil(t, resp)

			// Validate output
			if tt.validate != nil {
				tt.validate(t, resp.OutputPath)
			}
		})
	}
}

func TestVideoGeneration_Performance(t *testing.T) {
	// Skip if not running performance tests
	if testing.Short() {
		t.Skip("Skipping performance test in short mode")
	}

	if os.Getenv("SKIP_FFMPEG_EXECUTION") == "true" {
		t.Skip("Skipping performance test: SKIP_FFMPEG_EXECUTION=true")
	}

	// Check if ffmpeg is available
	checker := adapters.NewFFmpegChecker()
	if !checker.IsAvailable() {
		t.Skip("Skipping performance test: ffmpeg not available")
	}

	// Initialize logger
	logCfg := &config.LoggingConfig{
		Level:  "info",
		Format: "text",
	}
	require.NoError(t, logger.Init(logCfg))

	// Create test media files
	testDataDir := filepath.Join("testdata", "performance_test")
	require.NoError(t, testutil.CreateTestMediaFiles(testDataDir))
	defer func() {
		if err := testutil.CleanupTestMedia(testDataDir); err != nil {
			t.Logf("Failed to cleanup test media: %v", err)
		}
	}()

	// Create video service
	composer := adapters.NewFFmpegComposer()
	validator := adapters.NewValidator()
	logger := slog.Default()
	service := core.NewService(composer, validator, logger)

	// Benchmark video composition
	benchmarks := []struct {
		name        string
		numScenes   int
		maxDuration time.Duration
	}{
		{"3 scenes", 3, 10 * time.Second},
		{"5 scenes", 5, 15 * time.Second},
		{"10 scenes", 10, 30 * time.Second},
	}

	for _, bm := range benchmarks {
		t.Run(bm.name, func(t *testing.T) {
			// Prepare request
			images := make([]ports.ImageFrame, bm.numScenes)
			for i := 0; i < bm.numScenes; i++ {
				images[i] = ports.ImageFrame{
					Path:     filepath.Join(testDataDir, "images", fmt.Sprintf("test_%d.jpg", (i%3)+1)),
					Duration: 2.0 * time.Second,
				}
			}

			request := &ports.ComposeVideoRequest{
				Images:              images,
				NarrationAudioPath:  filepath.Join(testDataDir, "audio", "narration.wav"),
				BackgroundMusicPath: filepath.Join(testDataDir, "audio", "background.wav"),
				OutputPath:          filepath.Join(testDataDir, "output", fmt.Sprintf("perf_%d_scenes.mp4", bm.numScenes)),
				Settings: ports.VideoSettings{
					Width:                 1080,
					Height:                1920,
					FPS:                   30,
					NarrationVolume:       1.0,
					BackgroundMusicVolume: 0.3,
					AudioBitrate:          "128k",
				},
			}

			// Ensure output directory exists
			require.NoError(t, os.MkdirAll(filepath.Dir(request.OutputPath), 0755))

			// Measure composition time
			start := time.Now()

			ctx, cancel := context.WithTimeout(context.Background(), bm.maxDuration)
			defer cancel()

			resp, err := service.ComposeVideo(ctx, request)
			elapsed := time.Since(start)

			require.NoError(t, err)
			require.NotNil(t, resp)

			// Log performance metrics
			t.Logf("Composed %d scenes in %v", bm.numScenes, elapsed)
			assert.Less(t, elapsed, bm.maxDuration, "Video composition took too long")
		})
	}
}

func BenchmarkVideoComposition(b *testing.B) {
	if os.Getenv("SKIP_FFMPEG_EXECUTION") == "true" {
		b.Skip("Skipping benchmark: SKIP_FFMPEG_EXECUTION=true")
	}

	// Check if ffmpeg is available
	checker := adapters.NewFFmpegChecker()
	if !checker.IsAvailable() {
		b.Skip("Skipping benchmark: ffmpeg not available")
	}

	// Initialize logger
	logCfg := &config.LoggingConfig{
		Level:  "error",
		Format: "text",
	}
	if err := logger.Init(logCfg); err != nil {
		b.Fatalf("Failed to initialize logger: %v", err)
	}

	// Create test media files once
	testDataDir := filepath.Join("testdata", "benchmark_test")
	if err := testutil.CreateTestMediaFiles(testDataDir); err != nil {
		b.Fatalf("Failed to create test media files: %v", err)
	}
	defer func() {
		if err := testutil.CleanupTestMedia(testDataDir); err != nil {
			b.Logf("Failed to cleanup test media: %v", err)
		}
	}()

	// Create video service
	composer := adapters.NewFFmpegComposer()
	validator := adapters.NewValidator()
	logger := slog.Default()
	service := core.NewService(composer, validator, logger)

	// Prepare request
	request := &ports.ComposeVideoRequest{
		Images: []ports.ImageFrame{
			{Path: filepath.Join(testDataDir, "images", "test_1.jpg"), Duration: 2.0 * time.Second},
			{Path: filepath.Join(testDataDir, "images", "test_2.jpg"), Duration: 2.0 * time.Second},
			{Path: filepath.Join(testDataDir, "images", "test_3.jpg"), Duration: 2.0 * time.Second},
		},
		NarrationAudioPath:  filepath.Join(testDataDir, "audio", "narration.wav"),
		BackgroundMusicPath: filepath.Join(testDataDir, "audio", "background.wav"),
		OutputPath:          filepath.Join(testDataDir, "output", "benchmark.mp4"),
		Settings: ports.VideoSettings{
			Width:                 1080,
			Height:                1920,
			FPS:                   30,
			NarrationVolume:       1.0,
			BackgroundMusicVolume: 0.3,
			AudioBitrate:          "128k",
		},
	}

	// Ensure output directory exists
	if err := os.MkdirAll(filepath.Dir(request.OutputPath), 0755); err != nil {
		b.Fatalf("Failed to create output directory: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		ctx := context.Background()
		_, err := service.ComposeVideo(ctx, request)
		if err != nil {
			b.Fatal(err)
		}
	}
}
