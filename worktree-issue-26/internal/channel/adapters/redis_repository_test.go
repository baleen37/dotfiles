package adapters

import (
	"context"
	"ssulmeta-go/internal/channel/core"
	"testing"
	"time"

	"github.com/redis/go-redis/v9"
)

func setupTestRedis(t *testing.T) *redis.Client {
	// Use Redis DB 15 for testing to avoid conflicts
	client := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
		DB:   15,
	})

	// Clear the test database
	ctx := context.Background()
	client.FlushDB(ctx)

	// Test connection
	if err := client.Ping(ctx).Err(); err != nil {
		t.Skipf("Redis not available: %v", err)
	}

	return client
}

func TestNewRedisChannelRepository(t *testing.T) {
	client := setupTestRedis(t)
	defer func() {
		if err := client.Close(); err != nil {
			t.Logf("Failed to close Redis client: %v", err)
		}
	}()

	repo := NewRedisChannelRepository(client)
	if repo == nil {
		t.Error("NewRedisChannelRepository() should not return nil")
	}
}

func TestRedisChannelRepository_Create(t *testing.T) {
	client := setupTestRedis(t)
	defer func() {
		if err := client.Close(); err != nil {
			t.Logf("Failed to close Redis client: %v", err)
		}
	}()

	repo := NewRedisChannelRepository(client)
	ctx := context.Background()

	channel, _ := core.NewChannel("ch_123", "Tech Channel", "Technology content")

	// Test successful creation
	err := repo.Create(ctx, channel)
	if err != nil {
		t.Errorf("Create() error = %v, want nil", err)
	}

	// Test duplicate creation should fail
	err = repo.Create(ctx, channel)
	if err == nil {
		t.Error("Create() should fail for duplicate channel")
	}
}

func TestRedisChannelRepository_GetByID(t *testing.T) {
	client := setupTestRedis(t)
	defer func() {
		if err := client.Close(); err != nil {
			t.Logf("Failed to close Redis client: %v", err)
		}
	}()

	repo := NewRedisChannelRepository(client)
	ctx := context.Background()

	channel, _ := core.NewChannel("ch_123", "Tech Channel", "Technology content")
	if err := repo.Create(ctx, channel); err != nil {
		t.Fatalf("Failed to create channel: %v", err)
	}

	// Test successful retrieval
	retrieved, err := repo.GetByID(ctx, "ch_123")
	if err != nil {
		t.Errorf("GetByID() error = %v, want nil", err)
	}

	if retrieved.ID != channel.ID {
		t.Errorf("Retrieved channel ID = %v, want %v", retrieved.ID, channel.ID)
	}

	if retrieved.Name != channel.Name {
		t.Errorf("Retrieved channel Name = %v, want %v", retrieved.Name, channel.Name)
	}

	if retrieved.Concept != channel.Concept {
		t.Errorf("Retrieved channel Concept = %v, want %v", retrieved.Concept, channel.Concept)
	}

	// Test non-existent channel
	_, err = repo.GetByID(ctx, "non_existent")
	if err == nil {
		t.Error("GetByID() should fail for non-existent channel")
	}
}

func TestRedisChannelRepository_Update(t *testing.T) {
	client := setupTestRedis(t)
	defer func() {
		if err := client.Close(); err != nil {
			t.Logf("Failed to close Redis client: %v", err)
		}
	}()

	repo := NewRedisChannelRepository(client)
	ctx := context.Background()

	channel, _ := core.NewChannel("ch_123", "Tech Channel", "Technology content")
	if err := repo.Create(ctx, channel); err != nil {
		t.Fatalf("Failed to create channel: %v", err)
	}

	// Update channel
	time.Sleep(1 * time.Millisecond) // Ensure UpdatedAt difference
	channel.Name = "Updated Tech Channel"
	channel.UpdatedAt = time.Now()

	err := repo.Update(ctx, channel)
	if err != nil {
		t.Errorf("Update() error = %v, want nil", err)
	}

	// Verify update
	retrieved, _ := repo.GetByID(ctx, "ch_123")
	if retrieved.Name != "Updated Tech Channel" {
		t.Errorf("Channel Name not updated: got %v, want %v", retrieved.Name, "Updated Tech Channel")
	}

	// Test updating non-existent channel
	nonExistent, _ := core.NewChannel("ch_999", "Non Existent", "Concept")
	err = repo.Update(ctx, nonExistent)
	if err == nil {
		t.Error("Update() should fail for non-existent channel")
	}
}

func TestRedisChannelRepository_Delete(t *testing.T) {
	client := setupTestRedis(t)
	defer func() {
		if err := client.Close(); err != nil {
			t.Logf("Failed to close Redis client: %v", err)
		}
	}()

	repo := NewRedisChannelRepository(client)
	ctx := context.Background()

	channel, _ := core.NewChannel("ch_123", "Tech Channel", "Technology content")
	if err := repo.Create(ctx, channel); err != nil {
		t.Fatalf("Failed to create channel: %v", err)
	}

	// Test successful deletion
	err := repo.Delete(ctx, "ch_123")
	if err != nil {
		t.Errorf("Delete() error = %v, want nil", err)
	}

	// Verify deletion
	_, err = repo.GetByID(ctx, "ch_123")
	if err == nil {
		t.Error("Channel should be deleted")
	}

	// Test deleting non-existent channel
	err = repo.Delete(ctx, "non_existent")
	if err == nil {
		t.Error("Delete() should fail for non-existent channel")
	}
}

func TestRedisChannelRepository_List(t *testing.T) {
	client := setupTestRedis(t)
	defer func() {
		if err := client.Close(); err != nil {
			t.Logf("Failed to close Redis client: %v", err)
		}
	}()

	repo := NewRedisChannelRepository(client)
	ctx := context.Background()

	// Create test channels
	active, _ := core.NewChannel("ch_active", "Active Channel", "Active concept")
	inactive, _ := core.NewChannel("ch_inactive", "Inactive Channel", "Inactive concept")
	inactive.Deactivate()

	if err := repo.Create(ctx, active); err != nil {
		t.Fatalf("Failed to create active channel: %v", err)
	}
	if err := repo.Create(ctx, inactive); err != nil {
		t.Fatalf("Failed to create inactive channel: %v", err)
	}

	// Test listing all channels
	allChannels, err := repo.List(ctx, false)
	if err != nil {
		t.Errorf("List() error = %v, want nil", err)
	}

	if len(allChannels) != 2 {
		t.Errorf("List() returned %d channels, want 2", len(allChannels))
	}

	// Test listing only active channels
	activeChannels, err := repo.List(ctx, true)
	if err != nil {
		t.Errorf("List() error = %v, want nil", err)
	}

	if len(activeChannels) != 1 {
		t.Errorf("List(activeOnly=true) returned %d channels, want 1", len(activeChannels))
	}

	if !activeChannels[0].IsActive {
		t.Error("Listed channel should be active")
	}
}

func TestRedisChannelRepository_Exists(t *testing.T) {
	client := setupTestRedis(t)
	defer func() {
		if err := client.Close(); err != nil {
			t.Logf("Failed to close Redis client: %v", err)
		}
	}()

	repo := NewRedisChannelRepository(client)
	ctx := context.Background()

	channel, _ := core.NewChannel("ch_123", "Tech Channel", "Technology content")
	if err := repo.Create(ctx, channel); err != nil {
		t.Fatalf("Failed to create channel: %v", err)
	}

	// Test existing channel
	exists, err := repo.Exists(ctx, "ch_123")
	if err != nil {
		t.Errorf("Exists() error = %v, want nil", err)
	}

	if !exists {
		t.Error("Exists() should return true for existing channel")
	}

	// Test non-existing channel
	exists, err = repo.Exists(ctx, "non_existent")
	if err != nil {
		t.Errorf("Exists() error = %v, want nil", err)
	}

	if exists {
		t.Error("Exists() should return false for non-existing channel")
	}
}
