package adapters

import (
	"context"
	"fmt"
	"os/exec"
	"regexp"
	"ssulmeta-go/internal/video/ports"
	"ssulmeta-go/pkg/errors"
	"strings"
)

// FFmpegChecker implements the FFmpegChecker interface
type FFmpegChecker struct {
	ffmpegPath string
}

// NewFFmpegChecker creates a new FFmpegChecker instance
func NewFFmpegChecker() ports.FFmpegChecker {
	return &FFmpegChecker{
		ffmpegPath: "ffmpeg", // Default to system PATH
	}
}

// IsAvailable is a convenience method that checks ffmpeg availability
func (f *FFmpegChecker) IsAvailable() bool {
	ctx := context.Background()
	return f.IsFFmpegAvailable(ctx) == nil
}

// NewFFmpegCheckerWithPath creates a new FFmpegChecker with custom ffmpeg path
func NewFFmpegCheckerWithPath(path string) ports.FFmpegChecker {
	return &FFmpegChecker{
		ffmpegPath: path,
	}
}

// IsFFmpegAvailable checks if ffmpeg binary is available in the system
func (f *FFmpegChecker) IsFFmpegAvailable(ctx context.Context) error {
	cmd := exec.CommandContext(ctx, f.ffmpegPath, "-version")
	output, err := cmd.Output()
	if err != nil {
		if _, ok := err.(*exec.ExitError); ok {
			return errors.NewInternalError(
				errors.CodeDependencyUnavailable,
				"ffmpeg binary not found or failed to execute",
				map[string]interface{}{
					"ffmpeg_path": f.ffmpegPath,
					"error":       err.Error(),
				},
			)
		}
		return errors.NewInternalError(
			errors.CodeDependencyUnavailable,
			"failed to check ffmpeg availability",
			map[string]interface{}{
				"ffmpeg_path": f.ffmpegPath,
				"error":       err.Error(),
			},
		)
	}

	// Check if output contains ffmpeg version information
	outputStr := string(output)
	if !strings.Contains(outputStr, "ffmpeg version") {
		return errors.NewInternalError(
			errors.CodeDependencyUnavailable,
			"ffmpeg binary found but version check failed",
			map[string]interface{}{
				"ffmpeg_path": f.ffmpegPath,
				"output":      outputStr,
			},
		)
	}

	return nil
}

// GetFFmpegVersion returns the version of ffmpeg
func (f *FFmpegChecker) GetFFmpegVersion(ctx context.Context) (string, error) {
	cmd := exec.CommandContext(ctx, f.ffmpegPath, "-version")
	output, err := cmd.Output()
	if err != nil {
		return "", errors.NewInternalError(
			errors.CodeDependencyUnavailable,
			"failed to get ffmpeg version",
			map[string]interface{}{
				"ffmpeg_path": f.ffmpegPath,
				"error":       err.Error(),
			},
		)
	}

	// Extract version using regex
	re := regexp.MustCompile(`ffmpeg version ([^\s]+)`)
	matches := re.FindStringSubmatch(string(output))
	if len(matches) < 2 {
		return "", errors.NewInternalError(
			errors.CodeDependencyUnavailable,
			"could not parse ffmpeg version from output",
			map[string]interface{}{
				"ffmpeg_path": f.ffmpegPath,
				"output":      string(output),
			},
		)
	}

	return matches[1], nil
}

// GetFFmpegPath returns the path to ffmpeg binary
func (f *FFmpegChecker) GetFFmpegPath() string {
	return f.ffmpegPath
}

// IsFFprobeAvailable checks if ffprobe binary is available (needed for validation)
func (f *FFmpegChecker) IsFFprobeAvailable(ctx context.Context) error {
	ffprobePath := "ffprobe"
	if f.ffmpegPath != "ffmpeg" {
		// If custom ffmpeg path is set, try to find ffprobe in the same directory
		ffprobePath = strings.Replace(f.ffmpegPath, "ffmpeg", "ffprobe", 1)
	}

	cmd := exec.CommandContext(ctx, ffprobePath, "-version")
	output, err := cmd.Output()
	if err != nil {
		return errors.NewInternalError(
			errors.CodeDependencyUnavailable,
			"ffprobe binary not found or failed to execute",
			map[string]interface{}{
				"ffprobe_path": ffprobePath,
				"error":        err.Error(),
			},
		)
	}

	// Check if output contains ffprobe version information
	outputStr := string(output)
	if !strings.Contains(outputStr, "ffprobe version") {
		return errors.NewInternalError(
			errors.CodeDependencyUnavailable,
			"ffprobe binary found but version check failed",
			map[string]interface{}{
				"ffprobe_path": ffprobePath,
				"output":       outputStr,
			},
		)
	}

	return nil
}

// CheckAllDependencies checks both ffmpeg and ffprobe availability
func (f *FFmpegChecker) CheckAllDependencies(ctx context.Context) error {
	if err := f.IsFFmpegAvailable(ctx); err != nil {
		return fmt.Errorf("ffmpeg check failed: %w", err)
	}

	if err := f.IsFFprobeAvailable(ctx); err != nil {
		return fmt.Errorf("ffprobe check failed: %w", err)
	}

	return nil
}
