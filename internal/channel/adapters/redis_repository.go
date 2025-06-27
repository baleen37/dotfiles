package adapters

import (
	"context"
	"encoding/json"
	"fmt"
	"ssulmeta-go/internal/channel/core"
	"ssulmeta-go/internal/channel/ports"
	"ssulmeta-go/pkg/errors"
	"time"

	"github.com/redis/go-redis/v9"
)

// RedisChannelRepository implements ChannelRepository using Redis
type RedisChannelRepository struct {
	client    *redis.Client
	keyPrefix string
}

// NewRedisChannelRepository creates a new Redis-based channel repository
func NewRedisChannelRepository(client *redis.Client) ports.ChannelRepository {
	return &RedisChannelRepository{
		client:    client,
		keyPrefix: "channel:",
	}
}

// channelData represents the structure stored in Redis
type channelData struct {
	ID        string               `json:"id"`
	Name      string               `json:"name"`
	Concept   string               `json:"concept"`
	Settings  core.ChannelSettings `json:"settings"`
	IsActive  bool                 `json:"is_active"`
	CreatedAt time.Time            `json:"created_at"`
	UpdatedAt time.Time            `json:"updated_at"`
}

// toChannelData converts Channel to channelData for storage
func toChannelData(channel *core.Channel) *channelData {
	return &channelData{
		ID:        channel.ID,
		Name:      channel.Name,
		Concept:   channel.Concept,
		Settings:  channel.Settings,
		IsActive:  channel.IsActive,
		CreatedAt: channel.CreatedAt,
		UpdatedAt: channel.UpdatedAt,
	}
}

// toChannel converts channelData back to Channel
func (cd *channelData) toChannel() (*core.Channel, error) {
	// We can't use NewChannel because it would reset timestamps and settings
	// Instead, create the struct directly with validation
	if cd.ID == "" {
		return nil, errors.New(errors.ErrorTypeInternal, errors.CodeInternalError, "channel ID cannot be empty")
	}
	if cd.Name == "" {
		return nil, errors.New(errors.ErrorTypeInternal, errors.CodeInternalError, "channel name cannot be empty")
	}
	if cd.Concept == "" {
		return nil, errors.New(errors.ErrorTypeInternal, errors.CodeInternalError, "channel concept cannot be empty")
	}

	return &core.Channel{
		ID:        cd.ID,
		Name:      cd.Name,
		Concept:   cd.Concept,
		Settings:  cd.Settings,
		IsActive:  cd.IsActive,
		CreatedAt: cd.CreatedAt,
		UpdatedAt: cd.UpdatedAt,
	}, nil
}

// getKey returns the Redis key for a channel ID
func (r *RedisChannelRepository) getKey(id string) string {
	return r.keyPrefix + id
}

// getIndexKey returns the Redis key for the channel index
func (r *RedisChannelRepository) getIndexKey() string {
	return r.keyPrefix + "index"
}

// Create stores a new channel
func (r *RedisChannelRepository) Create(ctx context.Context, channel *core.Channel) error {
	key := r.getKey(channel.ID)

	// Check if channel already exists
	exists, err := r.client.Exists(ctx, key).Result()
	if err != nil {
		return errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeRedisOperationFail, "failed to check if channel exists")
	}

	if exists > 0 {
		return errors.New(errors.ErrorTypeConflict, errors.CodeChannelAlreadyExists, "channel already exists").
			WithDetails("channelId", channel.ID)
	}

	// Convert to storage format
	data := toChannelData(channel)

	// Serialize to JSON
	jsonData, err := json.Marshal(data)
	if err != nil {
		return errors.Wrap(err, errors.ErrorTypeInternal, errors.CodeInternalError, "failed to marshal channel data")
	}

	// Store in Redis using a transaction
	pipe := r.client.TxPipeline()
	pipe.Set(ctx, key, jsonData, 0)
	pipe.SAdd(ctx, r.getIndexKey(), channel.ID)

	_, err = pipe.Exec(ctx)
	if err != nil {
		return errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeRedisOperationFail, "failed to create channel")
	}

	return nil
}

// GetByID retrieves a channel by its ID
func (r *RedisChannelRepository) GetByID(ctx context.Context, id string) (*core.Channel, error) {
	key := r.getKey(id)

	// Get from Redis
	jsonData, err := r.client.Get(ctx, key).Result()
	if err != nil {
		if err == redis.Nil {
			return nil, errors.New(errors.ErrorTypeNotFound, errors.CodeChannelNotFound, "channel not found").
				WithDetails("channelId", id)
		}
		return nil, errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeRedisOperationFail, "failed to get channel")
	}

	// Deserialize from JSON
	var data channelData
	if err := json.Unmarshal([]byte(jsonData), &data); err != nil {
		return nil, errors.Wrap(err, errors.ErrorTypeInternal, errors.CodeInternalError, "failed to unmarshal channel data")
	}

	// Convert back to Channel
	return data.toChannel()
}

// Update updates an existing channel
func (r *RedisChannelRepository) Update(ctx context.Context, channel *core.Channel) error {
	key := r.getKey(channel.ID)

	// Check if channel exists
	exists, err := r.client.Exists(ctx, key).Result()
	if err != nil {
		return errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeRedisOperationFail, "failed to check if channel exists")
	}

	if exists == 0 {
		return errors.New(errors.ErrorTypeNotFound, errors.CodeChannelNotFound, "channel not found").
			WithDetails("channelId", channel.ID)
	}

	// Convert to storage format
	data := toChannelData(channel)

	// Serialize to JSON
	jsonData, err := json.Marshal(data)
	if err != nil {
		return errors.Wrap(err, errors.ErrorTypeInternal, errors.CodeInternalError, "failed to marshal channel data")
	}

	// Update in Redis
	err = r.client.Set(ctx, key, jsonData, 0).Err()
	if err != nil {
		return errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeRedisOperationFail, "failed to update channel")
	}

	return nil
}

// Delete removes a channel by its ID
func (r *RedisChannelRepository) Delete(ctx context.Context, id string) error {
	key := r.getKey(id)

	// Check if channel exists
	exists, err := r.client.Exists(ctx, key).Result()
	if err != nil {
		return errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeRedisOperationFail, "failed to check if channel exists")
	}

	if exists == 0 {
		return errors.New(errors.ErrorTypeNotFound, errors.CodeChannelNotFound, "channel not found").
			WithDetails("channelId", id)
	}

	// Delete from Redis using a transaction
	pipe := r.client.TxPipeline()
	pipe.Del(ctx, key)
	pipe.SRem(ctx, r.getIndexKey(), id)

	_, err = pipe.Exec(ctx)
	if err != nil {
		return errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeRedisOperationFail, "failed to delete channel")
	}

	return nil
}

// List retrieves all channels with optional filtering
func (r *RedisChannelRepository) List(ctx context.Context, activeOnly bool) ([]*core.Channel, error) {
	// Get all channel IDs from the index
	channelIDs, err := r.client.SMembers(ctx, r.getIndexKey()).Result()
	if err != nil {
		return nil, errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeRedisOperationFail, "failed to get channel index")
	}

	var channels []*core.Channel

	// Get each channel
	for _, id := range channelIDs {
		channel, err := r.GetByID(ctx, id)
		if err != nil {
			// Skip channels that can't be retrieved (they might have been deleted)
			continue
		}

		// Apply active filter
		if activeOnly && !channel.IsActive {
			continue
		}

		channels = append(channels, channel)
	}

	return channels, nil
}

// Exists checks if a channel exists by ID
func (r *RedisChannelRepository) Exists(ctx context.Context, id string) (bool, error) {
	key := r.getKey(id)

	exists, err := r.client.Exists(ctx, key).Result()
	if err != nil {
		return false, fmt.Errorf("failed to check if channel exists: %w", err)
	}

	return exists > 0, nil
}
