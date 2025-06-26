package ports

import (
	"context"
	"ssulmeta-go/internal/channel/core"
)

// ChannelRepository defines the interface for channel data persistence
type ChannelRepository interface {
	// Create stores a new channel
	Create(ctx context.Context, channel *core.Channel) error
	
	// GetByID retrieves a channel by its ID
	GetByID(ctx context.Context, id string) (*core.Channel, error)
	
	// Update updates an existing channel
	Update(ctx context.Context, channel *core.Channel) error
	
	// Delete removes a channel by its ID
	Delete(ctx context.Context, id string) error
	
	// List retrieves all channels with optional filtering
	List(ctx context.Context, activeOnly bool) ([]*core.Channel, error)
	
	// Exists checks if a channel exists by ID
	Exists(ctx context.Context, id string) (bool, error)
}