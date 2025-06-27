package core

import (
	"context"
	"fmt"
	"log/slog"
	"math"
	"math/rand"
	"path/filepath"
	"strings"
	"time"

	"ssulmeta-go/internal/video/ports"
	"ssulmeta-go/pkg/errors"
)

// Service implements the video composition business logic
type Service struct {
	composer  ports.Composer
	validator ports.Validator
	logger    *slog.Logger
}

// NewService creates a new video service instance
func NewService(composer ports.Composer, validator ports.Validator, logger *slog.Logger) *Service {
	return &Service{
		composer:  composer,
		validator: validator,
		logger:    logger,
	}
}

// ComposeVideo creates a video from images and audio files
func (s *Service) ComposeVideo(ctx context.Context, req *ports.ComposeVideoRequest) (*ports.ComposeVideoResponse, error) {
	s.logger.Info("Starting video composition",
		"images_count", len(req.Images),
		"output_path", req.OutputPath,
	)

	// Validate input
	if err := s.validateComposeVideoRequest(req); err != nil {
		return nil, fmt.Errorf("invalid request: %w", err)
	}

	// Validate video settings
	if err := s.validateVideoSettings(&req.Settings); err != nil {
		return nil, fmt.Errorf("invalid video settings: %w", err)
	}

	// Validate input files
	if err := s.validateInputFiles(ctx, req); err != nil {
		return nil, fmt.Errorf("input validation failed: %w", err)
	}

	// Calculate timing for images if not provided
	processedImages := s.prepareImages(req)

	// Create processed request
	processedReq := &ports.ComposeVideoRequest{
		Images:              processedImages,
		NarrationAudioPath:  req.NarrationAudioPath,
		BackgroundMusicPath: req.BackgroundMusicPath,
		OutputPath:          req.OutputPath,
		Settings:            req.Settings,
		TransitionDuration:  req.TransitionDuration,
	}

	// Delegate to composer
	response, err := s.composer.ComposeVideo(ctx, processedReq)
	if err != nil {
		return nil, fmt.Errorf("video composition failed: %w", err)
	}

	s.logger.Info("Video composition completed successfully",
		"output_path", response.OutputPath,
		"duration", response.Duration,
		"file_size", response.FileSize,
	)

	return response, nil
}

// validateComposeVideoRequest validates the basic structure of the request
func (s *Service) validateComposeVideoRequest(req *ports.ComposeVideoRequest) error {
	if len(req.Images) == 0 {
		return errors.NewValidationError(
			errors.CodeInvalidInput,
			"at least one image is required",
			map[string]interface{}{
				"images_count": len(req.Images),
			},
		)
	}

	if req.OutputPath == "" {
		return errors.NewValidationError(
			errors.CodeInvalidInput,
			"output path is required",
			nil,
		)
	}

	if req.NarrationAudioPath == "" {
		return errors.NewValidationError(
			errors.CodeInvalidInput,
			"narration audio path is required",
			nil,
		)
	}

	// Validate output path extension
	ext := strings.ToLower(filepath.Ext(req.OutputPath))
	if ext != ".mp4" {
		return errors.NewValidationError(
			errors.CodeInvalidInput,
			"output path must have .mp4 extension",
			map[string]interface{}{
				"output_path": req.OutputPath,
				"extension":   ext,
			},
		)
	}

	return nil
}

// validateVideoSettings validates video output settings
func (s *Service) validateVideoSettings(settings *ports.VideoSettings) error {
	if settings.Width <= 0 {
		return errors.NewValidationError(
			errors.CodeInvalidInput,
			"width must be greater than 0",
			map[string]interface{}{
				"width": settings.Width,
			},
		)
	}

	if settings.Height <= 0 {
		return errors.NewValidationError(
			errors.CodeInvalidInput,
			"height must be greater than 0",
			map[string]interface{}{
				"height": settings.Height,
			},
		)
	}

	if settings.FrameRate <= 0 {
		return errors.NewValidationError(
			errors.CodeInvalidInput,
			"frame rate must be greater than 0",
			map[string]interface{}{
				"frame_rate": settings.FrameRate,
			},
		)
	}

	if settings.BackgroundMusicVolume < 0.0 || settings.BackgroundMusicVolume > 1.0 {
		return errors.NewValidationError(
			errors.CodeInvalidInput,
			"background music volume must be between 0.0 and 1.0",
			map[string]interface{}{
				"volume": settings.BackgroundMusicVolume,
			},
		)
	}

	if settings.NarrationVolume < 0.0 || settings.NarrationVolume > 1.0 {
		return errors.NewValidationError(
			errors.CodeInvalidInput,
			"narration volume must be between 0.0 and 1.0",
			map[string]interface{}{
				"volume": settings.NarrationVolume,
			},
		)
	}

	return nil
}

// validateInputFiles validates that all input files exist and are valid
func (s *Service) validateInputFiles(ctx context.Context, req *ports.ComposeVideoRequest) error {
	// Validate images
	for i, img := range req.Images {
		if err := s.validator.ValidateImageFile(ctx, img.Path); err != nil {
			return fmt.Errorf("failed to validate image %d (%s): %w", i, img.Path, err)
		}
	}

	// Validate narration audio
	if err := s.validator.ValidateAudioFile(ctx, req.NarrationAudioPath); err != nil {
		return fmt.Errorf("failed to validate narration audio (%s): %w", req.NarrationAudioPath, err)
	}

	// Validate background music if provided
	if req.BackgroundMusicPath != "" {
		if err := s.validator.ValidateAudioFile(ctx, req.BackgroundMusicPath); err != nil {
			return fmt.Errorf("failed to validate background music (%s): %w", req.BackgroundMusicPath, err)
		}
	}

	return nil
}

// prepareImages processes images, calculating timing and Ken Burns effects
func (s *Service) prepareImages(req *ports.ComposeVideoRequest) []ports.ImageFrame {
	images := make([]ports.ImageFrame, len(req.Images))
	copy(images, req.Images)

	// Calculate total narration duration (simplified - in real implementation would get from audio file)
	totalDuration := s.estimateTotalDuration(req)

	// If images don't have duration set, calculate equal distribution
	needsTimingCalculation := false
	for _, img := range images {
		if img.Duration == 0 {
			needsTimingCalculation = true
			break
		}
	}

	if needsTimingCalculation {
		images = s.calculateImageTiming(images, totalDuration, req.TransitionDuration)
	}

	// Generate Ken Burns effects for images that don't have them
	for i := range images {
		if images[i].KenBurns == (ports.KenBurnsEffect{}) {
			images[i].KenBurns = s.generateKenBurnsEffect(i, len(images))
		}
	}

	return images
}

// estimateTotalDuration estimates total video duration (placeholder implementation)
func (s *Service) estimateTotalDuration(req *ports.ComposeVideoRequest) time.Duration {
	// In real implementation, would analyze audio file duration
	// For now, use a reasonable default based on image count
	baseTime := time.Duration(len(req.Images)) * 3 * time.Second
	transitionTime := time.Duration(len(req.Images)-1) * req.TransitionDuration
	return baseTime + transitionTime
}

// calculateImageTiming distributes total duration equally among images
func (s *Service) calculateImageTiming(images []ports.ImageFrame, totalDuration, transitionDuration time.Duration) []ports.ImageFrame {
	if len(images) == 0 {
		return images
	}

	// Calculate time available for images (minus transitions)
	totalTransitionTime := time.Duration(len(images)-1) * transitionDuration
	availableTime := totalDuration - totalTransitionTime

	// Distribute equally
	imageDuration := availableTime / time.Duration(len(images))

	result := make([]ports.ImageFrame, len(images))
	currentTime := time.Duration(0)

	for i, img := range images {
		result[i] = img
		result[i].Duration = imageDuration
		result[i].StartTime = currentTime
		currentTime += imageDuration
	}

	return result
}

// generateKenBurnsEffect creates a Ken Burns effect for an image
func (s *Service) generateKenBurnsEffect(sceneIndex, totalScenes int) ports.KenBurnsEffect {
	// Create varied effects based on scene position
	source := rand.NewSource(time.Now().UnixNano() + int64(sceneIndex))
	rng := rand.New(source)

	// Zoom settings - subtle zoom in/out
	startZoom := 1.0 + rng.Float64()*0.1 // 1.0 to 1.1
	endZoom := 1.0 + rng.Float64()*0.1   // 1.0 to 1.1

	// Ensure some zoom movement
	if math.Abs(endZoom-startZoom) < 0.05 {
		if rng.Float64() > 0.5 {
			endZoom = startZoom + 0.08
		} else {
			endZoom = startZoom - 0.08
		}
	}

	// Clamp zoom values
	startZoom = math.Max(1.0, math.Min(1.2, startZoom))
	endZoom = math.Max(1.0, math.Min(1.2, endZoom))

	// Pan settings - start and end positions
	startX := 0.3 + rng.Float64()*0.4 // 0.3 to 0.7
	startY := 0.3 + rng.Float64()*0.4 // 0.3 to 0.7
	endX := 0.3 + rng.Float64()*0.4   // 0.3 to 0.7
	endY := 0.3 + rng.Float64()*0.4   // 0.3 to 0.7

	// Ensure some movement
	if math.Abs(endX-startX) < 0.1 && math.Abs(endY-startY) < 0.1 {
		switch sceneIndex % 4 {
		case 0: // Pan right
			endX = math.Min(1.0, startX+0.2)
		case 1: // Pan left
			endX = math.Max(0.0, startX-0.2)
		case 2: // Pan down
			endY = math.Min(1.0, startY+0.2)
		case 3: // Pan up
			endY = math.Max(0.0, startY-0.2)
		}
	}

	return ports.KenBurnsEffect{
		StartZoom: startZoom,
		EndZoom:   endZoom,
		StartX:    startX,
		StartY:    startY,
		EndX:      endX,
		EndY:      endY,
	}
}
