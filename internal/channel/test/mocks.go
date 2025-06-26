package test

import (
	"context"
	"errors"
	"ssulmeta-go/internal/channel/core"
)

// MockRepository implements ChannelRepository for testing
type MockRepository struct {
	channels map[string]*core.Channel

	// Control mock behavior
	ShouldFailCreate bool
	ShouldFailGet    bool
	ShouldFailUpdate bool
	ShouldFailDelete bool
	ShouldFailList   bool
	ShouldFailExists bool
}

func NewMockRepository() *MockRepository {
	return &MockRepository{
		channels: make(map[string]*core.Channel),
	}
}

func (m *MockRepository) Create(ctx context.Context, channel *core.Channel) error {
	if m.ShouldFailCreate {
		return errors.New("mock create error")
	}

	if _, exists := m.channels[channel.ID]; exists {
		return errors.New("channel already exists")
	}

	channelCopy := *channel
	m.channels[channel.ID] = &channelCopy
	return nil
}

func (m *MockRepository) GetByID(ctx context.Context, id string) (*core.Channel, error) {
	if m.ShouldFailGet {
		return nil, errors.New("mock get error")
	}

	channel, exists := m.channels[id]
	if !exists {
		return nil, errors.New("channel not found")
	}

	channelCopy := *channel
	return &channelCopy, nil
}

func (m *MockRepository) Update(ctx context.Context, channel *core.Channel) error {
	if m.ShouldFailUpdate {
		return errors.New("mock update error")
	}

	if _, exists := m.channels[channel.ID]; !exists {
		return errors.New("channel not found")
	}

	channelCopy := *channel
	m.channels[channel.ID] = &channelCopy
	return nil
}

func (m *MockRepository) Delete(ctx context.Context, id string) error {
	if m.ShouldFailDelete {
		return errors.New("mock delete error")
	}

	if _, exists := m.channels[id]; !exists {
		return errors.New("channel not found")
	}

	delete(m.channels, id)
	return nil
}

func (m *MockRepository) List(ctx context.Context, activeOnly bool) ([]*core.Channel, error) {
	if m.ShouldFailList {
		return nil, errors.New("mock list error")
	}

	var channels []*core.Channel
	for _, channel := range m.channels {
		if activeOnly && !channel.IsActive {
			continue
		}

		channelCopy := *channel
		channels = append(channels, &channelCopy)
	}

	return channels, nil
}

func (m *MockRepository) Exists(ctx context.Context, id string) (bool, error) {
	if m.ShouldFailExists {
		return false, errors.New("mock exists error")
	}

	_, exists := m.channels[id]
	return exists, nil
}

func (m *MockRepository) Reset() {
	m.channels = make(map[string]*core.Channel)
	m.ShouldFailCreate = false
	m.ShouldFailGet = false
	m.ShouldFailUpdate = false
	m.ShouldFailDelete = false
	m.ShouldFailList = false
	m.ShouldFailExists = false
}
