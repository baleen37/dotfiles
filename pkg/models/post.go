package models

import (
	"time"
)

// PostStatus represents the status of a post
type PostStatus string

const (
	PostStatusDraft      PostStatus = "draft"
	PostStatusGenerating PostStatus = "generating"
	PostStatusReady      PostStatus = "ready"
	PostStatusUploaded   PostStatus = "uploaded"
	PostStatusFailed     PostStatus = "failed"
)

// Post represents a YouTube video post
type Post struct {
	ID        int `json:"id"`
	ChannelID int `json:"channel_id"`

	// Story data
	Title        string `json:"title"`
	StoryContent string `json:"story_content"`

	// Generated assets paths
	AudioFilePath string `json:"audio_file_path"`
	VideoFilePath string `json:"video_file_path"`
	ThumbnailPath string `json:"thumbnail_path"`

	// YouTube data
	YouTubeVideoID string   `json:"youtube_video_id"`
	YouTubeURL     string   `json:"youtube_url"`
	Description    string   `json:"description"`
	Tags           []string `json:"tags"`

	// Status tracking
	Status       PostStatus `json:"status"`
	ErrorMessage string     `json:"error_message"`

	// Timestamps
	CreatedAt   time.Time  `json:"created_at"`
	GeneratedAt *time.Time `json:"generated_at"`
	UploadedAt  *time.Time `json:"uploaded_at"`
}

// NewPost creates a new post instance
func NewPost(channelID int) *Post {
	return &Post{
		ChannelID: channelID,
		Status:    PostStatusDraft,
		Tags:      []string{},
		CreatedAt: time.Now(),
	}
}

// SetGenerating marks the post as generating
func (p *Post) SetGenerating() {
	p.Status = PostStatusGenerating
}

// SetReady marks the post as ready with generated assets
func (p *Post) SetReady(audioPath, videoPath, thumbnailPath string) {
	p.Status = PostStatusReady
	p.AudioFilePath = audioPath
	p.VideoFilePath = videoPath
	p.ThumbnailPath = thumbnailPath
	now := time.Now()
	p.GeneratedAt = &now
}

// SetUploaded marks the post as uploaded
func (p *Post) SetUploaded(videoID, url string) {
	p.Status = PostStatusUploaded
	p.YouTubeVideoID = videoID
	p.YouTubeURL = url
	now := time.Now()
	p.UploadedAt = &now
}

// SetFailed marks the post as failed
func (p *Post) SetFailed(err error) {
	p.Status = PostStatusFailed
	p.ErrorMessage = err.Error()
}
