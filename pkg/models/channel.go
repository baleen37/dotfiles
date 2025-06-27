package models

import (
	"time"
)

// Channel represents a YouTube channel configuration
type Channel struct {
	ID               int       `json:"id"`
	Name             string    `json:"name"`
	YouTubeChannelID string    `json:"youtube_channel_id"`
	PromptTemplate   string    `json:"prompt_template"`
	Tags             []string  `json:"tags"`
	IsActive         bool      `json:"is_active"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

// NewChannel creates a new channel instance
func NewChannel(name string) *Channel {
	now := time.Now()
	return &Channel{
		Name:      name,
		IsActive:  true,
		Tags:      []string{},
		CreatedAt: now,
		UpdatedAt: now,
	}
}
