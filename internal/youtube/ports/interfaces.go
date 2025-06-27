package ports

import (
	"context"
	"time"
)

// Video represents a video to be uploaded to YouTube
type Video struct {
	Title       string
	Description string
	Tags        []string
	CategoryID  string
	Privacy     string // "private", "public", "unlisted"
	Thumbnail   string // Path to thumbnail image
	VideoPath   string // Path to video file
}

// UploadResult contains the result of a YouTube video upload
type UploadResult struct {
	VideoID      string    // YouTube video ID
	URL          string    // YouTube video URL
	Title        string    // Video title
	UploadedAt   time.Time // Upload timestamp
	Status       string    // Upload status
	Duration     string    // Video duration
	FileSize     int64     // Video file size
	ThumbnailURL string    // Thumbnail URL
}

// UploadProgress represents upload progress information
type UploadProgress struct {
	BytesUploaded int64   // Bytes uploaded so far
	TotalBytes    int64   // Total bytes to upload
	Percentage    float64 // Upload percentage (0-100)
	Speed         string  // Upload speed (e.g., "1.2 MB/s")
	ETA           string  // Estimated time to completion
}

// Metadata contains video metadata for SEO and categorization
type Metadata struct {
	Title           string     // Video title (max 100 chars)
	Description     string     // Video description (max 5000 chars)
	Tags            []string   // Video tags (max 500 chars total)
	CategoryID      string     // YouTube category ID
	DefaultLanguage string     // Default language code (e.g., "ko", "en")
	Thumbnail       string     // Custom thumbnail path
	Privacy         string     // Privacy setting
	PublishAt       *time.Time // Scheduled publish time (optional)
}

// ChannelInfo represents YouTube channel information
type ChannelInfo struct {
	ID          string // Channel ID
	Title       string // Channel title
	Description string // Channel description
	Subscribers int64  // Subscriber count
	VideoCount  int64  // Total video count
	ViewCount   int64  // Total view count
}

// OAuthConfig represents OAuth2 configuration for YouTube API
type OAuthConfig struct {
	ClientID     string   // OAuth2 client ID
	ClientSecret string   // OAuth2 client secret
	RedirectURLs []string // Authorized redirect URLs
	Scopes       []string // Required OAuth2 scopes
}

// AuthToken represents an OAuth2 authentication token
type AuthToken struct {
	AccessToken  string    // Access token
	RefreshToken string    // Refresh token
	TokenType    string    // Token type (usually "Bearer")
	ExpiresAt    time.Time // Token expiration time
	Scopes       []string  // Granted scopes
}

// Uploader defines the interface for uploading videos to YouTube
type Uploader interface {
	// UploadVideo uploads a video to YouTube
	UploadVideo(ctx context.Context, video *Video, progressCallback func(*UploadProgress)) (*UploadResult, error)

	// UpdateVideo updates an existing video's metadata
	UpdateVideo(ctx context.Context, videoID string, metadata *Metadata) error

	// DeleteVideo deletes a video from YouTube
	DeleteVideo(ctx context.Context, videoID string) error

	// GetVideo retrieves video information
	GetVideo(ctx context.Context, videoID string) (*UploadResult, error)
}

// MetadataGenerator defines the interface for generating video metadata
type MetadataGenerator interface {
	// GenerateMetadata generates metadata from video content and story
	GenerateMetadata(ctx context.Context, storyContent string, channelType string) (*Metadata, error)

	// GenerateTitle generates a compelling video title
	GenerateTitle(ctx context.Context, storyContent string, channelType string) (string, error)

	// GenerateDescription generates a video description
	GenerateDescription(ctx context.Context, storyContent string, title string, channelType string) (string, error)

	// GenerateTags generates relevant tags for the video
	GenerateTags(ctx context.Context, storyContent string, channelType string) ([]string, error)
}

// AuthService defines the interface for YouTube OAuth2 authentication
type AuthService interface {
	// GetAuthURL generates an OAuth2 authorization URL
	GetAuthURL(state string) string

	// ExchangeCode exchanges an authorization code for tokens
	ExchangeCode(ctx context.Context, code string) (*AuthToken, error)

	// RefreshToken refreshes an expired access token
	RefreshToken(ctx context.Context, refreshToken string) (*AuthToken, error)

	// ValidateToken validates an access token
	ValidateToken(ctx context.Context, accessToken string) error

	// RevokeToken revokes an access token
	RevokeToken(ctx context.Context, token string) error
}

// ChannelService defines the interface for YouTube channel operations
type ChannelService interface {
	// GetChannelInfo retrieves channel information
	GetChannelInfo(ctx context.Context, accessToken string) (*ChannelInfo, error)

	// ListVideos lists videos from a channel
	ListVideos(ctx context.Context, accessToken string, maxResults int) ([]*UploadResult, error)

	// GetChannelAnalytics retrieves channel analytics
	GetChannelAnalytics(ctx context.Context, accessToken string, startDate, endDate time.Time) (map[string]interface{}, error)
}

// UploadStoryRequest represents a request to upload a story video to YouTube
type UploadStoryRequest struct {
	StoryContent  string     // Story content text
	ChannelType   string     // Channel type (fairy_tale, horror, romance)
	VideoPath     string     // Path to the video file
	ThumbnailPath string     // Path to the thumbnail image (optional)
	AccessToken   string     // YouTube access token
	ScheduledTime *time.Time // Scheduled publish time (optional)
}

// UploadStoryResult represents the result of uploading a story video
type UploadStoryResult struct {
	VideoID      string    // YouTube video ID
	URL          string    // YouTube video URL
	Title        string    // Video title
	UploadedAt   time.Time // Upload timestamp
	Status       string    // Upload status
	Duration     string    // Video duration
	FileSize     int64     // Video file size
	ThumbnailURL string    // Thumbnail URL
}

// YouTubeService defines the main interface for YouTube operations
type YouTubeService interface {
	// UploadStory uploads a story video to YouTube with generated metadata
	UploadStory(ctx context.Context, request *UploadStoryRequest) (*UploadStoryResult, error)

	// GetChannelInfo retrieves channel information
	GetChannelInfo(ctx context.Context, accessToken string) (*ChannelInfo, error)

	// UpdateVideoMetadata updates an existing video's metadata
	UpdateVideoMetadata(ctx context.Context, videoID string, metadata *Metadata, accessToken string) error

	// DeleteVideo deletes a video from YouTube
	DeleteVideo(ctx context.Context, videoID string, accessToken string) error

	// GetVideoAnalytics retrieves video analytics
	GetVideoAnalytics(ctx context.Context, videoID string, accessToken string) (map[string]interface{}, error)
}
