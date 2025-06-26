package service

import (
	"context"
	"fmt"
	"ssulmeta-go/internal/channel/core"
	"ssulmeta-go/internal/channel/ports"
	"time"
)

// ChannelService implements the business logic for channel operations
type ChannelService struct {
	repo ports.ChannelRepository
}

// NewChannelService creates a new channel service
func NewChannelService(repo ports.ChannelRepository) ports.ChannelService {
	return &ChannelService{
		repo: repo,
	}
}

// CreateChannel creates a new channel with validation
func (s *ChannelService) CreateChannel(ctx context.Context, id, name, concept string) (*core.Channel, error) {
	// Create channel entity (includes validation)
	channel, err := core.NewChannel(id, name, concept)
	if err != nil {
		return nil, fmt.Errorf("failed to create channel: %w", err)
	}

	// Check if channel already exists
	exists, err := s.repo.Exists(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to check if channel exists: %w", err)
	}

	if exists {
		return nil, fmt.Errorf("channel with ID %s already exists", id)
	}

	// Save to repository
	if err := s.repo.Create(ctx, channel); err != nil {
		return nil, fmt.Errorf("failed to save channel: %w", err)
	}

	return channel, nil
}

// GetChannel retrieves a channel by its ID
func (s *ChannelService) GetChannel(ctx context.Context, id string) (*core.Channel, error) {
	if id == "" {
		return nil, fmt.Errorf("channel ID cannot be empty")
	}

	channel, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get channel: %w", err)
	}

	return channel, nil
}

// UpdateChannelSettings updates channel settings with validation
func (s *ChannelService) UpdateChannelSettings(ctx context.Context, id string, settings core.ChannelSettings) (*core.Channel, error) {
	// Get existing channel
	channel, err := s.GetChannel(ctx, id)
	if err != nil {
		return nil, err
	}

	// Update settings (includes validation)
	if err := channel.UpdateSettings(settings); err != nil {
		return nil, fmt.Errorf("failed to update channel settings: %w", err)
	}

	// Save updated channel
	if err := s.repo.Update(ctx, channel); err != nil {
		return nil, fmt.Errorf("failed to save updated channel: %w", err)
	}

	return channel, nil
}

// UpdateChannelInfo updates channel name and concept
func (s *ChannelService) UpdateChannelInfo(ctx context.Context, id, name, concept string) (*core.Channel, error) {
	// Validate input
	if name == "" {
		return nil, fmt.Errorf("channel name cannot be empty")
	}
	if concept == "" {
		return nil, fmt.Errorf("channel concept cannot be empty")
	}

	// Get existing channel
	channel, err := s.GetChannel(ctx, id)
	if err != nil {
		return nil, err
	}

	// Update info
	channel.Name = name
	channel.Concept = concept
	channel.UpdatedAt = time.Now()

	// Save updated channel
	if err := s.repo.Update(ctx, channel); err != nil {
		return nil, fmt.Errorf("failed to save updated channel: %w", err)
	}

	return channel, nil
}

// ActivateChannel activates a channel
func (s *ChannelService) ActivateChannel(ctx context.Context, id string) (*core.Channel, error) {
	// Get existing channel
	channel, err := s.GetChannel(ctx, id)
	if err != nil {
		return nil, err
	}

	// Activate channel
	channel.Activate()

	// Save updated channel
	if err := s.repo.Update(ctx, channel); err != nil {
		return nil, fmt.Errorf("failed to save activated channel: %w", err)
	}

	return channel, nil
}

// DeactivateChannel deactivates a channel
func (s *ChannelService) DeactivateChannel(ctx context.Context, id string) (*core.Channel, error) {
	// Get existing channel
	channel, err := s.GetChannel(ctx, id)
	if err != nil {
		return nil, err
	}

	// Deactivate channel
	channel.Deactivate()

	// Save updated channel
	if err := s.repo.Update(ctx, channel); err != nil {
		return nil, fmt.Errorf("failed to save deactivated channel: %w", err)
	}

	return channel, nil
}

// DeleteChannel removes a channel
func (s *ChannelService) DeleteChannel(ctx context.Context, id string) error {
	if id == "" {
		return fmt.Errorf("channel ID cannot be empty")
	}

	// Check if channel exists
	exists, err := s.repo.Exists(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to check if channel exists: %w", err)
	}

	if !exists {
		return fmt.Errorf("channel with ID %s not found", id)
	}

	// Delete from repository
	if err := s.repo.Delete(ctx, id); err != nil {
		return fmt.Errorf("failed to delete channel: %w", err)
	}

	return nil
}

// ListChannels retrieves all channels with optional filtering
func (s *ChannelService) ListChannels(ctx context.Context, activeOnly bool) ([]*core.Channel, error) {
	channels, err := s.repo.List(ctx, activeOnly)
	if err != nil {
		return nil, fmt.Errorf("failed to list channels: %w", err)
	}

	return channels, nil
}

// ChannelExists checks if a channel exists
func (s *ChannelService) ChannelExists(ctx context.Context, id string) (bool, error) {
	if id == "" {
		return false, fmt.Errorf("channel ID cannot be empty")
	}

	exists, err := s.repo.Exists(ctx, id)
	if err != nil {
		return false, fmt.Errorf("failed to check if channel exists: %w", err)
	}

	return exists, nil
}
