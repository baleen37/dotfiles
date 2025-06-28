package core

import (
	"fmt"
	"strings"
	"time"

	"ssulmeta-go/internal/video/ports"
	"ssulmeta-go/pkg/errors"
)

// KenBurnsEffect implements Ken Burns effect processing
type KenBurnsEffect struct{}

// NewKenBurnsEffect creates a new Ken Burns effect processor
func NewKenBurnsEffect() ports.KenBurnsProcessor {
	return &KenBurnsEffect{}
}

// CalculateParameters calculates Ken Burns parameters from configuration
func (k *KenBurnsEffect) CalculateParameters(config ports.KenBurnsConfig, duration time.Duration) (*ports.KenBurnsParams, error) {
	// Validate zoom values (1.0 to 3.0)
	if config.StartZoom < 1.0 || config.StartZoom > 3.0 {
		return nil, errors.NewValidationError(
			errors.CodeInvalidInput,
			"start zoom must be between 1.0 and 3.0",
			map[string]interface{}{
				"start_zoom": config.StartZoom,
			},
		)
	}

	if config.EndZoom < 1.0 || config.EndZoom > 3.0 {
		return nil, errors.NewValidationError(
			errors.CodeInvalidInput,
			"end zoom must be between 1.0 and 3.0",
			map[string]interface{}{
				"end_zoom": config.EndZoom,
			},
		)
	}

	// Validate position values (0.0 to 1.0)
	if config.StartX < 0.0 || config.StartX > 1.0 || config.StartY < 0.0 || config.StartY > 1.0 {
		return nil, errors.NewValidationError(
			errors.CodeInvalidInput,
			"start position must be between 0.0 and 1.0",
			map[string]interface{}{
				"start_x": config.StartX,
				"start_y": config.StartY,
			},
		)
	}

	if config.EndX < 0.0 || config.EndX > 1.0 || config.EndY < 0.0 || config.EndY > 1.0 {
		return nil, errors.NewValidationError(
			errors.CodeInvalidInput,
			"end position must be between 0.0 and 1.0",
			map[string]interface{}{
				"end_x": config.EndX,
				"end_y": config.EndY,
			},
		)
	}

	// Calculate deltas
	params := &ports.KenBurnsParams{
		StartZoom: config.StartZoom,
		EndZoom:   config.EndZoom,
		StartX:    config.StartX,
		StartY:    config.StartY,
		EndX:      config.EndX,
		EndY:      config.EndY,
		ZoomDelta: config.EndZoom - config.StartZoom,
		XDelta:    config.EndX - config.StartX,
		YDelta:    config.EndY - config.StartY,
		Duration:  duration,
	}

	return params, nil
}

// GenerateFFmpegFilter generates FFmpeg filter string for Ken Burns effect
func (k *KenBurnsEffect) GenerateFFmpegFilter(params ports.KenBurnsParams, width, height int) string {
	// Convert relative positions to pixel coordinates
	startPixelX := params.StartX * float64(width)
	startPixelY := params.StartY * float64(height)
	endPixelX := params.EndX * float64(width)
	endPixelY := params.EndY * float64(height)

	// Calculate pixel deltas
	xPixelDelta := endPixelX - startPixelX
	yPixelDelta := endPixelY - startPixelY

	// Calculate duration in frames (assuming 30fps)
	durationFrames := int(params.Duration.Seconds() * 30)
	durationSeconds := params.Duration.Seconds()

	// Build zoompan filter using the expected format from the test
	// Format: zoompan=z='zoom_expression':x='x_expression':y='y_expression':d=duration_frames:s=size
	zoomExpr := fmt.Sprintf("if(lte(on,0),%.1f,%.1f+(%.1f-%.1f)*on/%.1f)",
		params.StartZoom, params.StartZoom, params.EndZoom, params.StartZoom, durationSeconds)
	xExpr := fmt.Sprintf("if(lte(on,0),%.1f,%.1f+(%.1f)*on/%.1f)",
		startPixelX, startPixelX, xPixelDelta, durationSeconds)
	yExpr := fmt.Sprintf("if(lte(on,0),%.1f,%.1f+(%.1f)*on/%.1f)",
		startPixelY, startPixelY, yPixelDelta, durationSeconds)

	return fmt.Sprintf("zoompan=z='%s':x='%s':y='%s':d=%d:s=%dx%d",
		zoomExpr, xExpr, yExpr, durationFrames, width, height)
}

// TransitionEffect implements transition effect processing
type TransitionEffect struct{}

// NewTransitionEffect creates a new transition effect processor
func NewTransitionEffect() ports.TransitionProcessor {
	return &TransitionEffect{}
}

// CalculateParameters calculates transition parameters
func (t *TransitionEffect) CalculateParameters(transitionType ports.TransitionType, duration time.Duration) (*ports.TransitionParams, error) {
	if duration <= 0 {
		return nil, errors.NewValidationError(
			errors.CodeInvalidInput,
			"transition duration must be greater than 0",
			map[string]interface{}{
				"duration": duration,
			},
		)
	}

	// Validate transition type
	validTypes := map[ports.TransitionType]bool{
		ports.TransitionTypeCrossfade: true,
		ports.TransitionTypeFadeIn:    true,
		ports.TransitionTypeFadeOut:   true,
		ports.TransitionTypeWipe:      true,
		ports.TransitionTypeSlide:     true,
	}

	if !validTypes[transitionType] {
		return nil, errors.NewValidationError(
			errors.CodeInvalidInput,
			"invalid transition type",
			map[string]interface{}{
				"transition_type": transitionType,
			},
		)
	}

	params := &ports.TransitionParams{
		Type:     transitionType,
		Duration: duration,
		Offset:   0, // Default offset
	}

	return params, nil
}

// GenerateFFmpegFilter generates FFmpeg filter string for transitions
func (t *TransitionEffect) GenerateFFmpegFilter(params ports.TransitionParams, fps int) string {
	durationSeconds := params.Duration.Seconds()
	offsetSeconds := params.Offset.Seconds()

	switch params.Type {
	case ports.TransitionTypeCrossfade:
		return fmt.Sprintf("xfade=transition=fade:duration=%.1f:offset=%.0f", durationSeconds, offsetSeconds)
	case ports.TransitionTypeFadeIn:
		// fade=in:start_frame:num_frames
		return fmt.Sprintf("fade=in:0:%d", int(durationSeconds*float64(fps)))
	case ports.TransitionTypeFadeOut:
		// fade=out:start_frame:num_frames
		startFrame := int(offsetSeconds * float64(fps))
		numFrames := int(durationSeconds * float64(fps))
		return fmt.Sprintf("fade=out:%d:%d", startFrame, numFrames)
	default:
		// Default to crossfade
		return fmt.Sprintf("xfade=transition=fade:duration=%.1f:offset=%.0f", durationSeconds, offsetSeconds)
	}
}

// SubtitleOverlay implements subtitle overlay processing
type SubtitleOverlay struct{}

// NewSubtitleOverlay creates a new subtitle overlay processor
func NewSubtitleOverlay() ports.SubtitleProcessor {
	return &SubtitleOverlay{}
}

// CalculateParameters calculates subtitle parameters from configuration
func (s *SubtitleOverlay) CalculateParameters(config ports.SubtitleConfig) (*ports.SubtitleParams, error) {
	// Validate text
	if config.Text == "" {
		return nil, errors.NewValidationError(
			errors.CodeInvalidInput,
			"subtitle text cannot be empty",
			map[string]interface{}{
				"text": config.Text,
			},
		)
	}

	// Validate font size
	if config.FontSize <= 0 {
		return nil, errors.NewValidationError(
			errors.CodeInvalidInput,
			"font size must be greater than 0",
			map[string]interface{}{
				"font_size": config.FontSize,
			},
		)
	}

	// Calculate position expressions based on position
	var x, y string
	switch config.Position {
	case ports.SubtitlePositionBottom:
		x = "(w-text_w)/2" // Center horizontally
		y = "h-text_h-50"  // Bottom with padding
	case ports.SubtitlePositionTop:
		x = "(w-text_w)/2" // Center horizontally
		y = "50"           // Top with padding
	case ports.SubtitlePositionCenter:
		x = "(w-text_w)/2" // Center horizontally
		y = "(h-text_h)/2" // Center vertically
	case ports.SubtitlePositionTopLeft:
		x = "50" // Left padding
		y = "50" // Top padding
	case ports.SubtitlePositionTopRight:
		x = "w-text_w-50" // Right padding
		y = "50"          // Top padding
	case ports.SubtitlePositionBottomLeft:
		x = "50"          // Left padding
		y = "h-text_h-50" // Bottom padding
	case ports.SubtitlePositionBottomRight:
		x = "w-text_w-50" // Right padding
		y = "h-text_h-50" // Bottom padding
	default:
		// Default to bottom center
		x = "(w-text_w)/2"
		y = "h-text_h-50"
	}

	params := &ports.SubtitleParams{
		Text:      config.Text,
		X:         x,
		Y:         y,
		FontSize:  config.FontSize,
		FontColor: config.FontColor,
		BgColor:   config.BgColor,
		Duration:  config.Duration,
		StartTime: config.StartTime,
	}

	return params, nil
}

// GenerateFFmpegFilter generates FFmpeg filter string for subtitle overlay
func (s *SubtitleOverlay) GenerateFFmpegFilter(params ports.SubtitleParams) string {
	// Build drawtext filter with the expected parameter order
	filter := fmt.Sprintf("drawtext=text='%s':fontsize=%d:fontcolor=%s",
		params.Text, params.FontSize, params.FontColor)

	// Add background if specified (before position parameters)
	if params.BgColor != "" {
		filter += fmt.Sprintf(":box=1:boxcolor=%s", params.BgColor)
	}

	// Add position parameters
	filter += fmt.Sprintf(":x=%s:y=%s", params.X, params.Y)

	// Add timing
	endTime := params.StartTime.Seconds() + params.Duration.Seconds()
	filter += fmt.Sprintf(":enable='between(t,%.1f,%.1f)'", params.StartTime.Seconds(), endTime)

	return filter
}

// WatermarkOverlay implements watermark overlay processing
type WatermarkOverlay struct{}

// NewWatermarkOverlay creates a new watermark overlay processor
func NewWatermarkOverlay() ports.WatermarkProcessor {
	return &WatermarkOverlay{}
}

// CalculateParameters calculates watermark parameters from configuration
func (w *WatermarkOverlay) CalculateParameters(config ports.WatermarkConfig) (*ports.WatermarkParams, error) {
	// Validate image path
	if config.ImagePath == "" {
		return nil, errors.NewValidationError(
			errors.CodeInvalidInput,
			"watermark image path cannot be empty",
			map[string]interface{}{
				"image_path": config.ImagePath,
			},
		)
	}

	// Validate scale (0.01 to 1.0)
	if config.Scale <= 0.0 || config.Scale > 1.0 {
		return nil, errors.NewValidationError(
			errors.CodeInvalidInput,
			"watermark scale must be between 0.01 and 1.0",
			map[string]interface{}{
				"scale": config.Scale,
			},
		)
	}

	// Validate opacity (0.0 to 1.0)
	if config.Opacity < 0.0 || config.Opacity > 1.0 {
		return nil, errors.NewValidationError(
			errors.CodeInvalidInput,
			"watermark opacity must be between 0.0 and 1.0",
			map[string]interface{}{
				"opacity": config.Opacity,
			},
		)
	}

	// Calculate position expressions based on position
	var x, y string
	switch config.Position {
	case ports.WatermarkPositionTopLeft:
		x = "20" // Left padding
		y = "20" // Top padding
	case ports.WatermarkPositionTopRight:
		x = "main_w-overlay_w-20" // Right padding
		y = "20"                  // Top padding
	case ports.WatermarkPositionBottomLeft:
		x = "20"                  // Left padding
		y = "main_h-overlay_h-20" // Bottom padding
	case ports.WatermarkPositionBottomRight:
		x = "main_w-overlay_w-20" // Right padding
		y = "main_h-overlay_h-20" // Bottom padding
	case ports.WatermarkPositionCenter:
		x = "(main_w-overlay_w)/2" // Center horizontally
		y = "(main_h-overlay_h)/2" // Center vertically
	default:
		// Default to bottom right
		x = "main_w-overlay_w-20"
		y = "main_h-overlay_h-20"
	}

	params := &ports.WatermarkParams{
		ImagePath: config.ImagePath,
		X:         x,
		Y:         y,
		Scale:     config.Scale,
		Opacity:   config.Opacity,
	}

	return params, nil
}

// GenerateFFmpegFilter generates FFmpeg filter string for watermark overlay
func (w *WatermarkOverlay) GenerateFFmpegFilter(params ports.WatermarkParams) string {
	// Build overlay filter
	// Format: [0:v][1:v]overlay=x:y:format=auto:alpha=1
	return fmt.Sprintf("[0:v][1:v]overlay=%s:%s:format=auto:alpha=1", params.X, params.Y)
}

// EffectChain implements effect chain processing
type EffectChain struct {
	kenBurns   ports.KenBurnsProcessor
	transition ports.TransitionProcessor
	subtitle   ports.SubtitleProcessor
	watermark  ports.WatermarkProcessor
}

// NewEffectChain creates a new effect chain processor
func NewEffectChain() ports.EffectChain {
	return &EffectChain{
		kenBurns:   NewKenBurnsEffect(),
		transition: NewTransitionEffect(),
		subtitle:   NewSubtitleOverlay(),
		watermark:  NewWatermarkOverlay(),
	}
}

// BuildComplexFilter builds a complex FFmpeg filter from multiple effects
func (e *EffectChain) BuildComplexFilter(effects []ports.VideoEffect, width, height, fps int) (string, error) {
	if len(effects) == 0 {
		// No effects, just copy the input
		return "[0:v]copy[out]", nil
	}

	var filterParts []string
	var inputLabel = "[0:v]"
	var outputLabel string

	for i, effect := range effects {
		var filterPart string

		// Generate output label for this effect
		if i == len(effects)-1 {
			outputLabel = "[out]" // Final output
		} else {
			outputLabel = fmt.Sprintf("[kb%d]", i) // Intermediate output
		}

		switch effect.Type {
		case ports.EffectTypeKenBurns:
			if effect.KenBurns == nil {
				return "", errors.NewValidationError(
					errors.CodeInvalidInput,
					"Ken Burns effect parameters are required",
					nil,
				)
			}
			filter := e.kenBurns.GenerateFFmpegFilter(*effect.KenBurns, width, height)
			filterPart = fmt.Sprintf("%s%s%s", inputLabel, filter, outputLabel)

		case ports.EffectTypeTransition:
			if effect.Transition == nil {
				return "", errors.NewValidationError(
					errors.CodeInvalidInput,
					"Transition effect parameters are required",
					nil,
				)
			}
			filter := e.transition.GenerateFFmpegFilter(*effect.Transition, fps)
			// Transitions need two inputs
			filterPart = fmt.Sprintf("%s[1:v]%s%s", inputLabel, filter, outputLabel)

		case ports.EffectTypeSubtitle:
			if effect.Subtitle == nil {
				return "", errors.NewValidationError(
					errors.CodeInvalidInput,
					"Subtitle effect parameters are required",
					nil,
				)
			}
			filter := e.subtitle.GenerateFFmpegFilter(*effect.Subtitle)
			filterPart = fmt.Sprintf("%s%s%s", inputLabel, filter, outputLabel)

		case ports.EffectTypeWatermark:
			if effect.Watermark == nil {
				return "", errors.NewValidationError(
					errors.CodeInvalidInput,
					"Watermark effect parameters are required",
					nil,
				)
			}
			filter := e.watermark.GenerateFFmpegFilter(*effect.Watermark)
			filterPart = fmt.Sprintf("%s%s", filter, outputLabel)

		default:
			return "", errors.NewValidationError(
				errors.CodeInvalidInput,
				"unknown effect type",
				map[string]interface{}{
					"effect_type": effect.Type,
				},
			)
		}

		filterParts = append(filterParts, filterPart)

		// Next effect takes the output of this effect as input
		inputLabel = outputLabel
	}

	// Join all filter parts with semicolons
	return strings.Join(filterParts, ";"), nil
}
