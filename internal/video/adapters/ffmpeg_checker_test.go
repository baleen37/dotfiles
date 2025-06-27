package adapters

import (
	"context"
	"runtime"
	"testing"

	"ssulmeta-go/internal/video/ports"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestFFmpegChecker_NewFFmpegChecker(t *testing.T) {
	checker := NewFFmpegChecker()
	assert.NotNil(t, checker)
	assert.Equal(t, "ffmpeg", checker.GetFFmpegPath())
}

func TestFFmpegChecker_NewFFmpegCheckerWithPath(t *testing.T) {
	customPath := "/usr/local/bin/ffmpeg"
	checker := NewFFmpegCheckerWithPath(customPath)
	assert.NotNil(t, checker)
	assert.Equal(t, customPath, checker.GetFFmpegPath())
}

func TestFFmpegChecker_IsFFmpegAvailable(t *testing.T) {
	tests := []struct {
		name        string
		ffmpegPath  string
		expectError bool
		skipReason  string
	}{
		{
			name:        "system ffmpeg",
			ffmpegPath:  "ffmpeg",
			expectError: false, // We'll check if ffmpeg is actually available
		},
		{
			name:        "invalid path",
			ffmpegPath:  "/invalid/path/to/ffmpeg",
			expectError: true,
		},
		{
			name:        "non-executable file",
			ffmpegPath:  "/bin/ls", // ls exists but is not ffmpeg
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.skipReason != "" {
				t.Skip(tt.skipReason)
			}

			checker := NewFFmpegCheckerWithPath(tt.ffmpegPath)
			ctx := context.Background()

			err := checker.IsFFmpegAvailable(ctx)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				// For system ffmpeg, we only assert no error if ffmpeg is actually installed
				if tt.ffmpegPath == "ffmpeg" {
					// Check if ffmpeg is available on this system
					// If not available, skip this test
					if err != nil {
						t.Skipf("ffmpeg not available on this system: %v", err)
					}
				}
				assert.NoError(t, err)
			}
		})
	}
}

func TestFFmpegChecker_GetFFmpegVersion(t *testing.T) {
	checker := NewFFmpegChecker()
	ctx := context.Background()

	// First check if ffmpeg is available
	if err := checker.IsFFmpegAvailable(ctx); err != nil {
		t.Skipf("ffmpeg not available on this system: %v", err)
	}

	version, err := checker.GetFFmpegVersion(ctx)
	assert.NoError(t, err)
	assert.NotEmpty(t, version)
	t.Logf("FFmpeg version: %s", version)
}

func TestFFmpegChecker_GetFFmpegVersion_InvalidPath(t *testing.T) {
	checker := NewFFmpegCheckerWithPath("/invalid/path/to/ffmpeg")
	ctx := context.Background()

	version, err := checker.GetFFmpegVersion(ctx)
	assert.Error(t, err)
	assert.Empty(t, version)
}

func TestFFmpegChecker_IsFFprobeAvailable(t *testing.T) {
	checker := NewFFmpegChecker().(*FFmpegChecker)
	ctx := context.Background()

	err := checker.IsFFprobeAvailable(ctx)

	// ffprobe is usually installed together with ffmpeg
	// If ffmpeg is available but ffprobe is not, that's unusual but possible
	if err != nil {
		t.Logf("ffprobe not available: %v", err)
		// Don't fail the test, just log it
	} else {
		t.Log("ffprobe is available")
	}
}

func TestFFmpegChecker_CheckAllDependencies(t *testing.T) {
	checker := NewFFmpegChecker().(*FFmpegChecker)
	ctx := context.Background()

	err := checker.CheckAllDependencies(ctx)

	if err != nil {
		t.Logf("Some dependencies not available: %v", err)
		// This is expected in CI environments without ffmpeg installed
		if runtime.GOOS == "linux" {
			t.Skip("Skipping dependency check on Linux CI environment")
		}
	} else {
		t.Log("All ffmpeg dependencies are available")
	}
}

func TestFFmpegChecker_GetFFmpegPath(t *testing.T) {
	tests := []struct {
		name         string
		ffmpegPath   string
		expectedPath string
	}{
		{
			name:         "default path",
			ffmpegPath:   "",
			expectedPath: "ffmpeg",
		},
		{
			name:         "custom path",
			ffmpegPath:   "/usr/local/bin/ffmpeg",
			expectedPath: "/usr/local/bin/ffmpeg",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var checker ports.FFmpegChecker
			if tt.ffmpegPath == "" {
				checker = NewFFmpegChecker()
			} else {
				checker = NewFFmpegCheckerWithPath(tt.ffmpegPath)
			}

			assert.Equal(t, tt.expectedPath, checker.GetFFmpegPath())
		})
	}
}

// Integration test that requires ffmpeg to be installed
func TestFFmpegChecker_Integration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	checker := NewFFmpegChecker()
	ctx := context.Background()

	// Check availability
	err := checker.IsFFmpegAvailable(ctx)
	if err != nil {
		t.Skipf("ffmpeg not available, skipping integration test: %v", err)
	}

	// Get version
	version, err := checker.GetFFmpegVersion(ctx)
	require.NoError(t, err)
	require.NotEmpty(t, version)

	t.Logf("Integration test passed with ffmpeg version: %s", version)
}

// Benchmark for ffmpeg availability check
func BenchmarkFFmpegChecker_IsFFmpegAvailable(b *testing.B) {
	checker := NewFFmpegChecker()
	ctx := context.Background()

	// Check if ffmpeg is available before benchmarking
	if err := checker.IsFFmpegAvailable(ctx); err != nil {
		b.Skipf("ffmpeg not available: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = checker.IsFFmpegAvailable(ctx)
	}
}
