package container

import (
	"context"
	"ssulmeta-go/internal/channel/ports"
	"ssulmeta-go/internal/config"
	storyPorts "ssulmeta-go/internal/story/ports"
	ttsPorts "ssulmeta-go/internal/tts/ports"
)

// Container defines the dependency injection container interface
type Container interface {
	// Config returns the application configuration
	Config() *config.Config

	// StoryService returns the story service instance
	StoryService() storyPorts.Service

	// ChannelService returns the channel service instance
	ChannelService() ports.ChannelService

	// ChannelRepository returns the channel repository instance
	ChannelRepository() ports.ChannelRepository

	// TTSService returns the TTS service instance
	TTSService() ttsPorts.Service

	// Close closes all resources managed by the container
	Close(ctx context.Context) error
}
