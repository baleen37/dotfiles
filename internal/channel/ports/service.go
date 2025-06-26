package ports

import (
	"context"
	"ssulmeta-go/internal/channel/core"
)

// ChannelService defines the business logic interface for channel operations
type ChannelService interface {
	// CreateChannel creates a new channel with validation
	CreateChannel(ctx context.Context, id, name, concept string) (*core.Channel, error)

	// GetChannel retrieves a channel by its ID
	GetChannel(ctx context.Context, id string) (*core.Channel, error)

	// UpdateChannelSettings updates channel settings with validation
	UpdateChannelSettings(ctx context.Context, id string, settings core.ChannelSettings) (*core.Channel, error)

	// UpdateChannelInfo updates channel name and concept
	UpdateChannelInfo(ctx context.Context, id, name, concept string) (*core.Channel, error)

	// ActivateChannel activates a channel
	ActivateChannel(ctx context.Context, id string) (*core.Channel, error)

	// DeactivateChannel deactivates a channel
	DeactivateChannel(ctx context.Context, id string) (*core.Channel, error)

	// DeleteChannel removes a channel
	DeleteChannel(ctx context.Context, id string) error

	// ListChannels retrieves all channels with optional filtering
	ListChannels(ctx context.Context, activeOnly bool) ([]*core.Channel, error)

	// ChannelExists checks if a channel exists
	ChannelExists(ctx context.Context, id string) (bool, error)
}
