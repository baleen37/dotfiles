package core

import (
	"errors"
	"time"
)

// Channel represents a YouTube channel in the system
type Channel struct {
	ID        string          // Unique identifier for the channel
	Name      string          // Display name of the channel
	Concept   string          // Channel concept/theme description
	Settings  ChannelSettings // Channel-specific settings
	IsActive  bool            // Whether the channel is active
	CreatedAt time.Time       // Creation timestamp
	UpdatedAt time.Time       // Last update timestamp
}

// ChannelSettings contains channel-specific configuration
type ChannelSettings struct {
	MaxVideoDuration int    // Maximum video duration in seconds
	VideoWidth       int    // Video width in pixels
	VideoHeight      int    // Video height in pixels
	VideoFPS         int    // Video frames per second
	Language         string // Primary language for content
}

// NewChannel creates a new channel with validation
func NewChannel(id, name, concept string) (*Channel, error) {
	if id == "" {
		return nil, errors.New("channel ID cannot be empty")
	}

	if name == "" {
		return nil, errors.New("channel name cannot be empty")
	}

	if concept == "" {
		return nil, errors.New("channel concept cannot be empty")
	}

	now := time.Now()

	return &Channel{
		ID:        id,
		Name:      name,
		Concept:   concept,
		Settings:  getDefaultSettings(),
		IsActive:  true,
		CreatedAt: now,
		UpdatedAt: now,
	}, nil
}

// UpdateSettings updates the channel settings with validation
func (c *Channel) UpdateSettings(settings ChannelSettings) error {
	if settings.MaxVideoDuration <= 0 {
		return errors.New("max video duration must be greater than 0")
	}

	if settings.VideoWidth <= 0 || settings.VideoHeight <= 0 {
		return errors.New("video width and height must be greater than 0")
	}

	if settings.VideoFPS <= 0 {
		return errors.New("video FPS must be greater than 0")
	}

	if settings.Language == "" {
		return errors.New("language cannot be empty")
	}

	c.Settings = settings
	c.UpdatedAt = time.Now()

	return nil
}

// Deactivate marks the channel as inactive
func (c *Channel) Deactivate() {
	c.IsActive = false
	c.UpdatedAt = time.Now()
}

// Activate marks the channel as active
func (c *Channel) Activate() {
	c.IsActive = true
	c.UpdatedAt = time.Now()
}

// getDefaultSettings returns default channel settings
func getDefaultSettings() ChannelSettings {
	return ChannelSettings{
		MaxVideoDuration: 60,   // YouTube Shorts max duration
		VideoWidth:       1080, // 9:16 aspect ratio
		VideoHeight:      1920,
		VideoFPS:         30,
		Language:         "ko", // Default to Korean
	}
}
