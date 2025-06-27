package container

import (
	"context"
	"fmt"
	"sync"

	channelAdapters "ssulmeta-go/internal/channel/adapters"
	"ssulmeta-go/internal/channel/ports"
	channelService "ssulmeta-go/internal/channel/service"
	"ssulmeta-go/internal/config"
	storyAdapters "ssulmeta-go/internal/story/adapters"
	"ssulmeta-go/internal/story/core"
	storyPorts "ssulmeta-go/internal/story/ports"
	"ssulmeta-go/internal/tts"
	ttsPorts "ssulmeta-go/internal/tts/ports"

	"github.com/redis/go-redis/v9"
)

// ContainerImpl implements the Container interface
type ContainerImpl struct {
	config *config.Config

	// Lazy initialization with sync.Once
	redisClient     *redis.Client
	redisClientOnce sync.Once
	redisClientErr  error

	channelRepo     ports.ChannelRepository
	channelRepoOnce sync.Once
	channelRepoErr  error

	channelSvc     ports.ChannelService
	channelSvcOnce sync.Once
	channelSvcErr  error

	storyService     storyPorts.Service
	storyServiceOnce sync.Once
	storyServiceErr  error

	ttsService     ttsPorts.Service
	ttsServiceOnce sync.Once
	ttsServiceErr  error
}

// NewContainer creates a new dependency injection container
func NewContainer(cfg *config.Config) Container {
	return &ContainerImpl{
		config: cfg,
	}
}

// Config returns the application configuration
func (c *ContainerImpl) Config() *config.Config {
	return c.config
}

// getRedisClient returns the Redis client instance with lazy initialization
func (c *ContainerImpl) getRedisClient() (*redis.Client, error) {
	c.redisClientOnce.Do(func() {
		c.redisClient = redis.NewClient(&redis.Options{
			Addr: fmt.Sprintf("%s:%d", c.config.Database.Host, 6379), // TODO: Make this configurable
			DB:   0,
		})

		// Test connection
		ctx := context.Background()
		if err := c.redisClient.Ping(ctx).Err(); err != nil {
			c.redisClientErr = fmt.Errorf("failed to connect to Redis: %w", err)
		}
	})

	return c.redisClient, c.redisClientErr
}

// ChannelRepository returns the channel repository instance
func (c *ContainerImpl) ChannelRepository() ports.ChannelRepository {
	c.channelRepoOnce.Do(func() {
		redisClient, err := c.getRedisClient()
		if err != nil {
			c.channelRepoErr = fmt.Errorf("failed to create Redis client for channel repository: %w", err)
			return
		}

		c.channelRepo = channelAdapters.NewRedisChannelRepository(redisClient)
	})

	if c.channelRepoErr != nil {
		// Return a nil repository if initialization failed
		// In a real application, you might want to handle this differently
		return nil
	}

	return c.channelRepo
}

// ChannelService returns the channel service instance
func (c *ContainerImpl) ChannelService() ports.ChannelService {
	c.channelSvcOnce.Do(func() {
		repo := c.ChannelRepository()
		if repo == nil {
			c.channelSvcErr = fmt.Errorf("failed to create channel repository")
			return
		}

		c.channelSvc = channelService.NewChannelService(repo)
	})

	if c.channelSvcErr != nil {
		return nil
	}

	return c.channelSvc
}

// StoryService returns the story service instance
func (c *ContainerImpl) StoryService() storyPorts.Service {
	c.storyServiceOnce.Do(func() {
		// Create dependencies based on configuration
		var generator storyPorts.Generator
		if c.config.API.UseMock {
			generator = storyAdapters.NewMockGenerator()
		} else {
			generator = storyAdapters.NewOpenAIGenerator(&c.config.API.OpenAI)
		}

		validator := core.NewValidator()

		// Create service with dependency injection
		c.storyService = core.NewService(generator, validator)
	})

	if c.storyServiceErr != nil {
		return nil
	}

	return c.storyService
}

// TTSService returns the TTS service instance
func (c *ContainerImpl) TTSService() ttsPorts.Service {
	c.ttsServiceOnce.Do(func() {
		// Determine if we should use mock mode
		useMock := c.config.API.UseMock || c.config.API.TTS.APIKey == ""

		// Create TTS factory
		factory := tts.NewServiceFactory(
			c.config.API.TTS.APIKey,
			c.config.Storage.BasePath,
			useMock,
		)

		// Create TTS service
		c.ttsService = factory.CreateService()
	})

	if c.ttsServiceErr != nil {
		return nil
	}

	return c.ttsService
}

// Close closes all resources managed by the container
func (c *ContainerImpl) Close(ctx context.Context) error {
	var errs []error

	// Close Redis client
	if c.redisClient != nil {
		if err := c.redisClient.Close(); err != nil {
			errs = append(errs, fmt.Errorf("failed to close Redis client: %w", err))
		}
	}

	// Return any errors that occurred during cleanup
	if len(errs) > 0 {
		return fmt.Errorf("errors occurred during container cleanup: %v", errs)
	}

	return nil
}
