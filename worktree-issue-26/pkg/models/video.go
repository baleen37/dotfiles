package models

// VideoMetadata represents video file metadata
type VideoMetadata struct {
	FilePath      string  `json:"file_path"`
	Duration      float64 `json:"duration"` // seconds
	Width         int     `json:"width"`
	Height        int     `json:"height"`
	FPS           int     `json:"fps"`
	FileSizeBytes int64   `json:"file_size_bytes"`
}

// YouTubeMetadata represents YouTube upload metadata
type YouTubeMetadata struct {
	Title       string   `json:"title"`
	Description string   `json:"description"`
	Tags        []string `json:"tags"`
	CategoryID  string   `json:"category_id"`
	Privacy     string   `json:"privacy"` // private, unlisted, public
}
