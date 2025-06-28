package ports

import (
	"context"
	"time"
)

// ImageFrame represents a single frame in the video with timing information
type ImageFrame struct {
	Path      string         // Path to the image file
	Duration  time.Duration  // How long to display this image
	StartTime time.Duration  // When this image starts in the video
	KenBurns  KenBurnsEffect // Ken Burns effect settings
}

// KenBurnsEffect defines zoom and pan settings for an image
type KenBurnsEffect struct {
	StartZoom float64 // Initial zoom level (1.0 = no zoom)
	EndZoom   float64 // Final zoom level
	StartX    float64 // Initial X position (0.0-1.0)
	StartY    float64 // Initial Y position (0.0-1.0)
	EndX      float64 // Final X position (0.0-1.0)
	EndY      float64 // Final Y position (0.0-1.0)
}

// KenBurnsConfig defines the configuration for Ken Burns effect
type KenBurnsConfig struct {
	StartZoom float64 // Initial zoom level (1.0 = no zoom, range: 1.0-3.0)
	EndZoom   float64 // Final zoom level (range: 1.0-3.0)
	StartX    float64 // Initial X position (0.0-1.0, 0.5 = center)
	StartY    float64 // Initial Y position (0.0-1.0, 0.5 = center)
	EndX      float64 // Final X position (0.0-1.0)
	EndY      float64 // Final Y position (0.0-1.0)
}

// KenBurnsParams defines the calculated parameters for Ken Burns effect
type KenBurnsParams struct {
	StartZoom float64       // Initial zoom level
	EndZoom   float64       // Final zoom level
	StartX    float64       // Initial X position
	StartY    float64       // Initial Y position
	EndX      float64       // Final X position
	EndY      float64       // Final Y position
	ZoomDelta float64       // Change in zoom (EndZoom - StartZoom)
	XDelta    float64       // Change in X position (EndX - StartX)
	YDelta    float64       // Change in Y position (EndY - StartY)
	Duration  time.Duration // Duration of the effect
}

// TransitionType defines the type of transition between scenes
type TransitionType string

const (
	TransitionTypeCrossfade TransitionType = "crossfade"
	TransitionTypeFadeIn    TransitionType = "fadein"
	TransitionTypeFadeOut   TransitionType = "fadeout"
	TransitionTypeWipe      TransitionType = "wipe"
	TransitionTypeSlide     TransitionType = "slide"
)

// TransitionParams defines the parameters for scene transitions
type TransitionParams struct {
	Type     TransitionType // Type of transition
	Duration time.Duration  // Duration of the transition
	Offset   time.Duration  // Time offset from start of clip
}

// SubtitlePosition defines the position of subtitles on screen
type SubtitlePosition string

const (
	SubtitlePositionBottom      SubtitlePosition = "bottom"
	SubtitlePositionTop         SubtitlePosition = "top"
	SubtitlePositionCenter      SubtitlePosition = "center"
	SubtitlePositionTopLeft     SubtitlePosition = "top-left"
	SubtitlePositionTopRight    SubtitlePosition = "top-right"
	SubtitlePositionBottomLeft  SubtitlePosition = "bottom-left"
	SubtitlePositionBottomRight SubtitlePosition = "bottom-right"
)

// SubtitleConfig defines the configuration for subtitle overlay
type SubtitleConfig struct {
	Text      string           // Text to display
	Position  SubtitlePosition // Position on screen
	FontSize  int              // Font size in pixels
	FontColor string           // Font color (hex: #FFFFFF)
	BgColor   string           // Background color (hex: #000000, empty for no background)
	Duration  time.Duration    // How long to show the subtitle
	StartTime time.Duration    // When to start showing the subtitle
}

// SubtitleParams defines the calculated parameters for subtitle overlay
type SubtitleParams struct {
	Text      string        // Text to display
	X         string        // X position expression for FFmpeg
	Y         string        // Y position expression for FFmpeg
	FontSize  int           // Font size in pixels
	FontColor string        // Font color
	BgColor   string        // Background color
	Duration  time.Duration // Duration to show
	StartTime time.Duration // Start time
}

// WatermarkPosition defines the position of watermark on screen
type WatermarkPosition string

const (
	WatermarkPositionTopLeft     WatermarkPosition = "top-left"
	WatermarkPositionTopRight    WatermarkPosition = "top-right"
	WatermarkPositionBottomLeft  WatermarkPosition = "bottom-left"
	WatermarkPositionBottomRight WatermarkPosition = "bottom-right"
	WatermarkPositionCenter      WatermarkPosition = "center"
)

// WatermarkConfig defines the configuration for watermark overlay
type WatermarkConfig struct {
	ImagePath string            // Path to watermark image
	Position  WatermarkPosition // Position on screen
	Scale     float64           // Scale factor (0.1 = 10% of original size)
	Opacity   float64           // Opacity (0.0-1.0, 1.0 = fully opaque)
}

// WatermarkParams defines the calculated parameters for watermark overlay
type WatermarkParams struct {
	ImagePath string  // Path to watermark image
	X         string  // X position expression for FFmpeg
	Y         string  // Y position expression for FFmpeg
	Scale     float64 // Scale factor
	Opacity   float64 // Opacity
}

// EffectType defines the type of video effect
type EffectType string

const (
	EffectTypeKenBurns   EffectType = "kenburns"
	EffectTypeTransition EffectType = "transition"
	EffectTypeSubtitle   EffectType = "subtitle"
	EffectTypeWatermark  EffectType = "watermark"
)

// VideoEffect defines a single video effect
type VideoEffect struct {
	Type       EffectType        // Type of effect
	KenBurns   *KenBurnsParams   // Ken Burns parameters (if applicable)
	Transition *TransitionParams // Transition parameters (if applicable)
	Subtitle   *SubtitleParams   // Subtitle parameters (if applicable)
	Watermark  *WatermarkParams  // Watermark parameters (if applicable)
}

// VideoSettings defines output video settings
type VideoSettings struct {
	Width                 int     // Video width (1080 for Shorts)
	Height                int     // Video height (1920 for Shorts)
	FPS                   int     // Frames per second (30)
	FrameRate             int     // Frames per second (30) - deprecated, use FPS
	Bitrate               string  // Video bitrate (e.g., "2M")
	VideoBitrate          string  // Video bitrate (e.g., "2M") - deprecated, use Bitrate
	AudioBitrate          string  // Audio bitrate (e.g., "128k")
	Format                string  // Output format (mp4)
	BackgroundMusicVolume float64 // Background music volume (0.0-1.0)
	NarrationVolume       float64 // Narration volume (0.0-1.0)
}

// ComposeVideoRequest contains all parameters needed for video composition
type ComposeVideoRequest struct {
	Images              []ImageFrame  // List of images with timing
	NarrationAudioPath  string        // Path to TTS narration file
	BackgroundMusicPath string        // Path to background music file
	OutputPath          string        // Where to save the final video
	Settings            VideoSettings // Video output settings
	TransitionDuration  time.Duration // Duration of crossfade transitions
}

// ComposeVideoResponse contains the result of video composition
type ComposeVideoResponse struct {
	OutputPath    string        // Path to the created video file
	Duration      time.Duration // Total video duration
	FileSize      int64         // File size in bytes
	ThumbnailPath string        // Path to generated thumbnail (optional)
}

// ValidationResult contains the result of video file validation
type ValidationResult struct {
	IsValid  bool          // Whether the video passes all checks
	Errors   []string      // List of validation errors
	Width    int           // Actual video width
	Height   int           // Actual video height
	Duration time.Duration // Actual video duration
	FileSize int64         // Actual file size
	Format   string        // Actual video format
}

// Composer defines the interface for video composition using ffmpeg
type Composer interface {
	// ComposeVideo creates a video from images and audio files
	ComposeVideo(ctx context.Context, req *ComposeVideoRequest) (*ComposeVideoResponse, error)

	// GenerateThumbnail creates a thumbnail image from the video
	GenerateThumbnail(ctx context.Context, videoPath string, outputPath string, timeOffset time.Duration) error

	// GetDuration returns the duration of a video file
	GetDuration(ctx context.Context, videoPath string) (time.Duration, error)
}

// Validator defines the interface for video file validation
type Validator interface {
	// ValidateVideo checks if a video file meets the required specifications
	ValidateVideo(ctx context.Context, videoPath string, expectedSettings VideoSettings) (*ValidationResult, error)

	// ValidateAudioFile checks if an audio file is valid
	ValidateAudioFile(ctx context.Context, audioPath string) error

	// ValidateImageFile checks if an image file is valid
	ValidateImageFile(ctx context.Context, imagePath string) error
}

// FFmpegChecker defines interface for checking ffmpeg availability
type FFmpegChecker interface {
	// IsFFmpegAvailable checks if ffmpeg binary is available in the system
	IsFFmpegAvailable(ctx context.Context) error

	// GetFFmpegVersion returns the version of ffmpeg
	GetFFmpegVersion(ctx context.Context) (string, error)

	// GetFFmpegPath returns the path to ffmpeg binary
	GetFFmpegPath() string

	// IsAvailable checks if ffmpeg is available (for compatibility)
	IsAvailable() bool
}

// EffectProcessor defines interface for video effect processing
type EffectProcessor interface {
	// ProcessEffects applies effects to video and returns FFmpeg filter string
	ProcessEffects(effects []VideoEffect, width, height, fps int) (string, error)
}

// KenBurnsProcessor defines interface for Ken Burns effect processing
type KenBurnsProcessor interface {
	// CalculateParameters calculates Ken Burns parameters from configuration
	CalculateParameters(config KenBurnsConfig, duration time.Duration) (*KenBurnsParams, error)

	// GenerateFFmpegFilter generates FFmpeg filter string for Ken Burns effect
	GenerateFFmpegFilter(params KenBurnsParams, width, height int) string
}

// TransitionProcessor defines interface for transition effect processing
type TransitionProcessor interface {
	// CalculateParameters calculates transition parameters
	CalculateParameters(transitionType TransitionType, duration time.Duration) (*TransitionParams, error)

	// GenerateFFmpegFilter generates FFmpeg filter string for transitions
	GenerateFFmpegFilter(params TransitionParams, fps int) string
}

// SubtitleProcessor defines interface for subtitle overlay processing
type SubtitleProcessor interface {
	// CalculateParameters calculates subtitle parameters from configuration
	CalculateParameters(config SubtitleConfig) (*SubtitleParams, error)

	// GenerateFFmpegFilter generates FFmpeg filter string for subtitle overlay
	GenerateFFmpegFilter(params SubtitleParams) string
}

// WatermarkProcessor defines interface for watermark overlay processing
type WatermarkProcessor interface {
	// CalculateParameters calculates watermark parameters from configuration
	CalculateParameters(config WatermarkConfig) (*WatermarkParams, error)

	// GenerateFFmpegFilter generates FFmpeg filter string for watermark overlay
	GenerateFFmpegFilter(params WatermarkParams) string
}

// EffectChain defines interface for chaining multiple effects
type EffectChain interface {
	// BuildComplexFilter builds a complex FFmpeg filter from multiple effects
	BuildComplexFilter(effects []VideoEffect, width, height, fps int) (string, error)
}
