package adapters

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"ssulmeta-go/internal/video/ports"
	"ssulmeta-go/pkg/errors"
)

// FFmpegAdapter implements video composition using ffmpeg binary
type FFmpegAdapter struct {
	logger *slog.Logger
}

// NewFFmpegAdapter creates a new FFmpeg adapter instance
func NewFFmpegAdapter(logger *slog.Logger) *FFmpegAdapter {
	return &FFmpegAdapter{
		logger: logger,
	}
}

// NewFFmpegComposer creates a new FFmpeg composer with default logger
func NewFFmpegComposer() ports.Composer {
	logger := slog.Default()
	return &FFmpegAdapter{
		logger: logger,
	}
}

// ComposeVideo creates a video from images and audio using ffmpeg
func (f *FFmpegAdapter) ComposeVideo(ctx context.Context, req *ports.ComposeVideoRequest) (*ports.ComposeVideoResponse, error) {
	f.logger.Info("Starting ffmpeg video composition",
		"images_count", len(req.Images),
		"output_path", req.OutputPath,
		"narration_audio_path", req.NarrationAudioPath,
		"background_music_path", req.BackgroundMusicPath,
	)

	// Validate inputs
	if err := f.validateInputs(req); err != nil {
		return nil, err
	}

	// Create output directory if it doesn't exist
	if err := os.MkdirAll(filepath.Dir(req.OutputPath), 0755); err != nil {
		return nil, errors.NewInternalError(
			errors.CodeVideoCompositionFailed,
			"failed to create output directory",
			map[string]interface{}{
				"output_path": req.OutputPath,
				"error":       err.Error(),
			},
		)
	}

	// For now, implement a simple version that creates a video from the first image and audio
	startTime := time.Now()
	if err := f.executeSimpleFFmpegCommand(ctx, req); err != nil {
		return nil, err
	}

	// Get output file info
	fileInfo, err := os.Stat(req.OutputPath)
	if err != nil {
		return nil, errors.NewInternalError(
			errors.CodeVideoCompositionFailed,
			"failed to get output file info",
			map[string]interface{}{
				"output_path": req.OutputPath,
				"error":       err.Error(),
			},
		)
	}

	// Get video duration
	duration, err := f.GetDuration(ctx, req.OutputPath)
	if err != nil {
		f.logger.Warn("Failed to get video duration", "error", err)
		// Calculate expected duration from images
		duration = f.calculateExpectedDuration(req.Images)
	}

	processingTime := time.Since(startTime)
	f.logger.Info("Video composition completed",
		"output_path", req.OutputPath,
		"file_size", fileInfo.Size(),
		"duration", duration,
		"processing_time", processingTime,
	)

	return &ports.ComposeVideoResponse{
		OutputPath: req.OutputPath,
		Duration:   duration,
		FileSize:   fileInfo.Size(),
	}, nil
}

// GenerateThumbnail creates a thumbnail from video at specified time offset
func (f *FFmpegAdapter) GenerateThumbnail(ctx context.Context, videoPath, outputPath string, timeOffset time.Duration) error {
	f.logger.Info("Generating thumbnail",
		"video_path", videoPath,
		"output_path", outputPath,
		"time_offset", timeOffset,
	)

	// Validate inputs
	if _, err := os.Stat(videoPath); os.IsNotExist(err) {
		return errors.NewInternalError(
			errors.CodeVideoCompositionFailed,
			"video file does not exist",
			map[string]interface{}{
				"video_path": videoPath,
			},
		)
	}

	// Create output directory if needed
	if err := os.MkdirAll(filepath.Dir(outputPath), 0755); err != nil {
		return errors.NewInternalError(
			errors.CodeVideoCompositionFailed,
			"failed to create output directory",
			map[string]interface{}{
				"output_path": outputPath,
				"error":       err.Error(),
			},
		)
	}

	// Build ffmpeg command for thumbnail generation
	cmd := exec.CommandContext(ctx, "ffmpeg",
		"-i", videoPath,
		"-ss", fmt.Sprintf("%.2f", timeOffset.Seconds()),
		"-vframes", "1",
		"-q:v", "2",
		"-y", // Overwrite output files
		outputPath,
	)

	// Execute command
	// Skip actual ffmpeg execution in test environment
	if os.Getenv("SKIP_FFMPEG_EXECUTION") == "true" {
		f.logger.Debug("Skipping ffmpeg execution for testing")
		// Create a dummy thumbnail file for testing
		file, err := os.Create(outputPath)
		if err != nil {
			return errors.NewInternalError(
				errors.CodeVideoCompositionFailed,
				"failed to create test thumbnail file",
				map[string]interface{}{
					"output_path": outputPath,
					"error":       err.Error(),
				},
			)
		}
		defer func() {
			if err := file.Close(); err != nil {
				f.logger.Error("Failed to close file", "error", err)
			}
		}()
		_, err = file.WriteString("fake thumbnail content")
		if err != nil {
			return errors.NewInternalError(
				errors.CodeVideoCompositionFailed,
				"failed to write test thumbnail file",
				map[string]interface{}{
					"output_path": outputPath,
					"error":       err.Error(),
				},
			)
		}
		return nil
	}

	if err := cmd.Run(); err != nil {
		return errors.NewInternalError(
			errors.CodeVideoCompositionFailed,
			"failed to generate thumbnail",
			map[string]interface{}{
				"video_path":  videoPath,
				"output_path": outputPath,
				"time_offset": timeOffset,
				"error":       err.Error(),
			},
		)
	}

	f.logger.Info("Thumbnail generated successfully", "output_path", outputPath)
	return nil
}

// GetDuration returns the duration of a video file
func (f *FFmpegAdapter) GetDuration(ctx context.Context, videoPath string) (time.Duration, error) {
	f.logger.Debug("Getting video duration", "video_path", videoPath)

	// Use ffprobe to get video duration
	cmd := exec.CommandContext(ctx, "ffprobe",
		"-v", "quiet",
		"-print_format", "json",
		"-show_format",
		videoPath,
	)

	// Skip actual ffprobe execution in test environment
	if os.Getenv("SKIP_FFMPEG_EXECUTION") == "true" {
		f.logger.Debug("Skipping ffprobe execution for testing")
		// Check if file exists even in test mode
		if _, err := os.Stat(videoPath); os.IsNotExist(err) {
			return 0, errors.NewInternalError(
				errors.CodeVideoCompositionFailed,
				"video file does not exist",
				map[string]interface{}{
					"video_path": videoPath,
				},
			)
		}
		// Return a fake duration for testing
		return time.Second * 5, nil
	}

	output, err := cmd.Output()
	if err != nil {
		return 0, errors.NewInternalError(
			errors.CodeVideoCompositionFailed,
			"failed to get video duration",
			map[string]interface{}{
				"video_path": videoPath,
				"error":      err.Error(),
			},
		)
	}

	// Parse duration from output
	duration, err := f.parseDurationFromProbeOutput(string(output))
	if err != nil {
		return 0, err
	}

	f.logger.Debug("Video duration retrieved", "duration", duration)
	return duration, nil
}

// validateInputs validates the compose video request
func (f *FFmpegAdapter) validateInputs(req *ports.ComposeVideoRequest) error {
	// Check if all image files exist
	for i, img := range req.Images {
		if _, err := os.Stat(img.Path); os.IsNotExist(err) {
			return errors.NewInternalError(
				errors.CodeVideoCompositionFailed,
				"image file does not exist",
				map[string]interface{}{
					"image_index": i,
					"image_path":  img.Path,
				},
			)
		}
	}

	// Check if audio files exist
	if req.NarrationAudioPath != "" {
		if _, err := os.Stat(req.NarrationAudioPath); os.IsNotExist(err) {
			return errors.NewInternalError(
				errors.CodeVideoCompositionFailed,
				"narration audio file does not exist",
				map[string]interface{}{
					"narration_audio_path": req.NarrationAudioPath,
				},
			)
		}
	}

	if req.BackgroundMusicPath != "" {
		if _, err := os.Stat(req.BackgroundMusicPath); os.IsNotExist(err) {
			return errors.NewInternalError(
				errors.CodeVideoCompositionFailed,
				"background music file does not exist",
				map[string]interface{}{
					"background_music_path": req.BackgroundMusicPath,
				},
			)
		}
	}

	return nil
}

// executeSimpleFFmpegCommand executes a simple ffmpeg command for basic video creation
func (f *FFmpegAdapter) executeSimpleFFmpegCommand(ctx context.Context, req *ports.ComposeVideoRequest) error {
	if len(req.Images) == 0 {
		return errors.NewInternalError(
			errors.CodeVideoCompositionFailed,
			"no images provided",
			nil,
		)
	}

	// Handle multiple images case
	if len(req.Images) > 1 {
		return f.executeMultiImageFFmpegCommand(ctx, req)
	}

	// Simple implementation: create video from first image with audio
	args := []string{
		"-loop", "1",
		"-i", req.Images[0].Path,
	}

	// Add audio if provided
	if req.NarrationAudioPath != "" {
		args = append(args, "-i", req.NarrationAudioPath)
	}

	// Add output settings
	args = append(args,
		"-c:v", "libx264",
		"-preset", "medium",
		"-crf", "23",
		"-pix_fmt", "yuv420p",
		"-vf", fmt.Sprintf("scale=%d:%d", req.Settings.Width, req.Settings.Height),
		"-r", strconv.Itoa(req.Settings.FPS),
	)

	if req.NarrationAudioPath != "" {
		args = append(args,
			"-c:a", "aac",
			"-b:a", req.Settings.AudioBitrate,
			"-shortest",
		)
	} else {
		// If no audio, create video with fixed duration
		totalDuration := f.calculateExpectedDuration(req.Images)
		args = append(args, "-t", fmt.Sprintf("%.2f", totalDuration.Seconds()))
	}

	args = append(args, "-y", req.OutputPath)

	cmd := exec.CommandContext(ctx, "ffmpeg", args...)

	f.logger.Debug("Executing ffmpeg command", "args", strings.Join(args, " "))

	// Skip actual ffmpeg execution in test environment
	if os.Getenv("SKIP_FFMPEG_EXECUTION") == "true" {
		f.logger.Debug("Skipping ffmpeg execution for testing")
		// Create a dummy output file for testing
		file, err := os.Create(req.OutputPath)
		if err != nil {
			return errors.NewInternalError(
				errors.CodeVideoCompositionFailed,
				"failed to create test output file",
				map[string]interface{}{
					"output_path": req.OutputPath,
					"error":       err.Error(),
				},
			)
		}
		defer func() {
			if err := file.Close(); err != nil {
				f.logger.Error("Failed to close file", "error", err)
			}
		}()
		_, err = file.WriteString("fake video content")
		if err != nil {
			return errors.NewInternalError(
				errors.CodeVideoCompositionFailed,
				"failed to write test output file",
				map[string]interface{}{
					"output_path": req.OutputPath,
					"error":       err.Error(),
				},
			)
		}
		return nil
	}

	if err := cmd.Run(); err != nil {
		return errors.NewInternalError(
			errors.CodeVideoCompositionFailed,
			"ffmpeg execution failed",
			map[string]interface{}{
				"output_path": req.OutputPath,
				"error":       err.Error(),
			},
		)
	}

	return nil
}

// executeMultiImageFFmpegCommand handles video creation from multiple images
func (f *FFmpegAdapter) executeMultiImageFFmpegCommand(ctx context.Context, req *ports.ComposeVideoRequest) error {
	// Build complex filter for multiple images
	var inputFiles []string
	var filterParts []string

	// Add all image inputs
	for _, img := range req.Images {
		inputFiles = append(inputFiles, "-loop", "1", "-t", fmt.Sprintf("%.2f", img.Duration.Seconds()), "-i", img.Path)
	}

	// Add audio inputs
	audioIndex := len(req.Images)
	if req.NarrationAudioPath != "" {
		inputFiles = append(inputFiles, "-i", req.NarrationAudioPath)
	}
	if req.BackgroundMusicPath != "" {
		inputFiles = append(inputFiles, "-i", req.BackgroundMusicPath)
	}

	// Build video filter chain
	for i := range req.Images {
		filterParts = append(filterParts, fmt.Sprintf("[%d:v]scale=%d:%d,setsar=1[v%d]",
			i, req.Settings.Width, req.Settings.Height, i))
	}

	// Concatenate all video streams
	var concatInputs string
	for i := range req.Images {
		concatInputs += fmt.Sprintf("[v%d]", i)
	}
	filterParts = append(filterParts, fmt.Sprintf("%sconcat=n=%d:v=1:a=0[outv]", concatInputs, len(req.Images)))

	// Handle audio mixing if both narration and background music exist
	audioFilter := ""
	if req.NarrationAudioPath != "" && req.BackgroundMusicPath != "" {
		narrationIdx := audioIndex
		bgMusicIdx := audioIndex + 1
		audioFilter = fmt.Sprintf("[%d:a]volume=%.2f[a1];[%d:a]volume=%.2f[a2];[a1][a2]amix=inputs=2:duration=longest[outa]",
			narrationIdx, req.Settings.NarrationVolume,
			bgMusicIdx, req.Settings.BackgroundMusicVolume)
		filterParts = append(filterParts, audioFilter)
	}

	// Combine all filter parts
	filterComplex := strings.Join(filterParts, ";")

	// Build ffmpeg command
	args := inputFiles
	args = append(args, "-filter_complex", filterComplex)
	args = append(args, "-map", "[outv]")

	if audioFilter != "" {
		args = append(args, "-map", "[outa]")
	} else if req.NarrationAudioPath != "" {
		args = append(args, "-map", fmt.Sprintf("%d:a", audioIndex))
	}

	// Output settings
	args = append(args,
		"-c:v", "libx264",
		"-preset", "medium",
		"-crf", "23",
		"-pix_fmt", "yuv420p",
		"-r", strconv.Itoa(req.Settings.FPS),
	)

	if req.NarrationAudioPath != "" || req.BackgroundMusicPath != "" {
		args = append(args,
			"-c:a", "aac",
			"-b:a", req.Settings.AudioBitrate,
		)
	}

	args = append(args, "-y", req.OutputPath)

	cmd := exec.CommandContext(ctx, "ffmpeg", args...)

	f.logger.Debug("Executing multi-image ffmpeg command", "args", strings.Join(args, " "))

	// Skip actual ffmpeg execution in test environment
	if os.Getenv("SKIP_FFMPEG_EXECUTION") == "true" {
		f.logger.Debug("Skipping ffmpeg execution for testing")
		// Create a dummy output file for testing
		file, err := os.Create(req.OutputPath)
		if err != nil {
			return errors.NewInternalError(
				errors.CodeVideoCompositionFailed,
				"failed to create test output file",
				map[string]interface{}{
					"output_path": req.OutputPath,
					"error":       err.Error(),
				},
			)
		}
		defer func() {
			if err := file.Close(); err != nil {
				f.logger.Error("Failed to close file", "error", err)
			}
		}()
		_, err = file.WriteString("fake video content")
		if err != nil {
			return errors.NewInternalError(
				errors.CodeVideoCompositionFailed,
				"failed to write test output file",
				map[string]interface{}{
					"output_path": req.OutputPath,
					"error":       err.Error(),
				},
			)
		}
		return nil
	}

	if err := cmd.Run(); err != nil {
		return errors.NewInternalError(
			errors.CodeVideoCompositionFailed,
			"ffmpeg execution failed",
			map[string]interface{}{
				"output_path": req.OutputPath,
				"error":       err.Error(),
			},
		)
	}

	return nil
}

// calculateExpectedDuration calculates total duration from image durations
func (f *FFmpegAdapter) calculateExpectedDuration(images []ports.ImageFrame) time.Duration {
	var total time.Duration
	for _, img := range images {
		total += img.Duration
	}
	return total
}

// parseDurationFromProbeOutput parses duration from ffprobe JSON output
func (f *FFmpegAdapter) parseDurationFromProbeOutput(output string) (time.Duration, error) {
	// Simple regex to extract duration from JSON output
	// In production, you'd want to use proper JSON parsing
	re := regexp.MustCompile(`"duration":\s*"([^"]+)"`)
	matches := re.FindStringSubmatch(output)

	if len(matches) < 2 {
		return 0, errors.NewInternalError(
			errors.CodeVideoCompositionFailed,
			"failed to parse duration from ffprobe output",
			map[string]interface{}{
				"output": output,
			},
		)
	}

	durationStr := matches[1]
	duration, err := strconv.ParseFloat(durationStr, 64)
	if err != nil {
		return 0, errors.NewInternalError(
			errors.CodeVideoCompositionFailed,
			"failed to parse duration value",
			map[string]interface{}{
				"duration_str": durationStr,
				"error":        err.Error(),
			},
		)
	}

	return time.Duration(duration * float64(time.Second)), nil
}
