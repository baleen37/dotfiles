package ports

import (
	"context"
	"errors"
	"ssulmeta-go/internal/channel/core"
	"testing"
)

// MockChannelRepository is a mock implementation for testing
type MockChannelRepository struct {
	channels map[string]*core.Channel

	// Control mock behavior
	shouldFailCreate bool
	shouldFailGet    bool
	shouldFailUpdate bool
	shouldFailDelete bool
	shouldFailList   bool
	shouldFailExists bool
}

func NewMockChannelRepository() *MockChannelRepository {
	return &MockChannelRepository{
		channels: make(map[string]*core.Channel),
	}
}

func (m *MockChannelRepository) Create(ctx context.Context, channel *core.Channel) error {
	if m.shouldFailCreate {
		return errors.New("mock create error")
	}

	// Check if channel already exists
	if _, exists := m.channels[channel.ID]; exists {
		return errors.New("channel already exists")
	}

	// Create a copy to avoid reference issues
	channelCopy := *channel
	m.channels[channel.ID] = &channelCopy

	return nil
}

func (m *MockChannelRepository) GetByID(ctx context.Context, id string) (*core.Channel, error) {
	if m.shouldFailGet {
		return nil, errors.New("mock get error")
	}

	channel, exists := m.channels[id]
	if !exists {
		return nil, errors.New("channel not found")
	}

	// Return a copy to avoid reference issues
	channelCopy := *channel
	return &channelCopy, nil
}

func (m *MockChannelRepository) Update(ctx context.Context, channel *core.Channel) error {
	if m.shouldFailUpdate {
		return errors.New("mock update error")
	}

	// Check if channel exists
	if _, exists := m.channels[channel.ID]; !exists {
		return errors.New("channel not found")
	}

	// Update the channel
	channelCopy := *channel
	m.channels[channel.ID] = &channelCopy

	return nil
}

func (m *MockChannelRepository) Delete(ctx context.Context, id string) error {
	if m.shouldFailDelete {
		return errors.New("mock delete error")
	}

	// Check if channel exists
	if _, exists := m.channels[id]; !exists {
		return errors.New("channel not found")
	}

	delete(m.channels, id)

	return nil
}

func (m *MockChannelRepository) List(ctx context.Context, activeOnly bool) ([]*core.Channel, error) {
	if m.shouldFailList {
		return nil, errors.New("mock list error")
	}

	var channels []*core.Channel

	for _, channel := range m.channels {
		if activeOnly && !channel.IsActive {
			continue
		}

		// Return copies to avoid reference issues
		channelCopy := *channel
		channels = append(channels, &channelCopy)
	}

	return channels, nil
}

func (m *MockChannelRepository) Exists(ctx context.Context, id string) (bool, error) {
	if m.shouldFailExists {
		return false, errors.New("mock exists error")
	}

	_, exists := m.channels[id]
	return exists, nil
}

// Test Repository Interface Contract
func TestChannelRepository_Create(t *testing.T) {
	repo := NewMockChannelRepository()
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

	// Test with failure mock
	repo.shouldFailCreate = true
	channel2, _ := core.NewChannel("ch_456", "Another Channel", "Another concept")
	err = repo.Create(ctx, channel2)
	if err == nil {
		t.Error("Create() should fail when mock is set to fail")
	}
}

func TestChannelRepository_GetByID(t *testing.T) {
	repo := NewMockChannelRepository()
	ctx := context.Background()

	channel, _ := core.NewChannel("ch_123", "Tech Channel", "Technology content")
	_ = repo.Create(ctx, channel)

	// Test successful retrieval
	retrieved, err := repo.GetByID(ctx, "ch_123")
	if err != nil {
		t.Errorf("GetByID() error = %v, want nil", err)
	}

	if retrieved.ID != channel.ID || retrieved.Name != channel.Name {
		t.Errorf("Retrieved channel doesn't match original")
	}

	// Test non-existent channel
	_, err = repo.GetByID(ctx, "non_existent")
	if err == nil {
		t.Error("GetByID() should fail for non-existent channel")
	}

	// Test with failure mock
	repo.shouldFailGet = true
	_, err = repo.GetByID(ctx, "ch_123")
	if err == nil {
		t.Error("GetByID() should fail when mock is set to fail")
	}
}

func TestChannelRepository_Update(t *testing.T) {
	repo := NewMockChannelRepository()
	ctx := context.Background()

	channel, _ := core.NewChannel("ch_123", "Tech Channel", "Technology content")
	_ = repo.Create(ctx, channel)

	// Update channel
	channel.Name = "Updated Tech Channel"
	err := repo.Update(ctx, channel)
	if err != nil {
		t.Errorf("Update() error = %v, want nil", err)
	}

	// Verify update
	retrieved, _ := repo.GetByID(ctx, "ch_123")
	if retrieved.Name != "Updated Tech Channel" {
		t.Error("Channel was not updated properly")
	}

	// Test updating non-existent channel
	nonExistent, _ := core.NewChannel("ch_999", "Non Existent", "Concept")
	err = repo.Update(ctx, nonExistent)
	if err == nil {
		t.Error("Update() should fail for non-existent channel")
	}

	// Test with failure mock
	repo.shouldFailUpdate = true
	err = repo.Update(ctx, channel)
	if err == nil {
		t.Error("Update() should fail when mock is set to fail")
	}
}

func TestChannelRepository_Delete(t *testing.T) {
	repo := NewMockChannelRepository()
	ctx := context.Background()

	channel, _ := core.NewChannel("ch_123", "Tech Channel", "Technology content")
	_ = repo.Create(ctx, channel)

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

	// Test with failure mock
	repo.shouldFailDelete = true
	channel2, _ := core.NewChannel("ch_456", "Another Channel", "Another concept")
	_ = repo.Create(ctx, channel2)
	err = repo.Delete(ctx, "ch_456")
	if err == nil {
		t.Error("Delete() should fail when mock is set to fail")
	}
}

func TestChannelRepository_List(t *testing.T) {
	repo := NewMockChannelRepository()
	ctx := context.Background()

	// Create test channels
	active, _ := core.NewChannel("ch_active", "Active Channel", "Active concept")
	inactive, _ := core.NewChannel("ch_inactive", "Inactive Channel", "Inactive concept")
	inactive.Deactivate()

	_ = repo.Create(ctx, active)
	_ = repo.Create(ctx, inactive)

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

	// Test with failure mock
	repo.shouldFailList = true
	_, err = repo.List(ctx, false)
	if err == nil {
		t.Error("List() should fail when mock is set to fail")
	}
}

func TestChannelRepository_Exists(t *testing.T) {
	repo := NewMockChannelRepository()
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

	// Test with failure mock
	repo.shouldFailExists = true
	_, err = repo.Exists(ctx, "ch_123")
	if err == nil {
		t.Error("Exists() should fail when mock is set to fail")
	}
}
