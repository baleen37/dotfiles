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
}
