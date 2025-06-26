package adapters

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"ssulmeta-go/internal/channel/core"
)

// mockChannelService implements ports.ChannelService for testing
type mockChannelService struct {
	channels map[string]*core.Channel
}

func newMockChannelService() *mockChannelService {
	return &mockChannelService{
		channels: make(map[string]*core.Channel),
	}
}

func (m *mockChannelService) CreateChannel(ctx context.Context, id, name, concept string) (*core.Channel, error) {
	channel, err := core.NewChannel(id, name, concept)
	if err != nil {
		return nil, err
	}
	m.channels[id] = channel
	return channel, nil
}

func (m *mockChannelService) GetChannel(ctx context.Context, id string) (*core.Channel, error) {
	channel, exists := m.channels[id]
	if !exists {
		return nil, errors.New("channel not found")
	}
	return channel, nil
}

func (m *mockChannelService) UpdateChannelSettings(ctx context.Context, id string, settings core.ChannelSettings) (*core.Channel, error) {
	channel, exists := m.channels[id]
	if !exists {
		return nil, errors.New("channel not found")
	}
	err := channel.UpdateSettings(settings)
	if err != nil {
		return nil, err
	}
	return channel, nil
}

func (m *mockChannelService) UpdateChannelInfo(ctx context.Context, id, name, concept string) (*core.Channel, error) {
	channel, exists := m.channels[id]
	if !exists {
		return nil, errors.New("channel not found")
	}

	// Since UpdateInfo doesn't exist, we'll simulate it by creating a new channel with updated info
	updatedChannel, err := core.NewChannel(id, name, concept)
	if err != nil {
		return nil, err
	}

	// Preserve existing data
	updatedChannel.Settings = channel.Settings
	updatedChannel.IsActive = channel.IsActive
	updatedChannel.CreatedAt = channel.CreatedAt

	m.channels[id] = updatedChannel
	return updatedChannel, nil
}

func (m *mockChannelService) ActivateChannel(ctx context.Context, id string) (*core.Channel, error) {
	channel, exists := m.channels[id]
	if !exists {
		return nil, errors.New("channel not found")
	}
	channel.Activate()
	return channel, nil
}

func (m *mockChannelService) DeactivateChannel(ctx context.Context, id string) (*core.Channel, error) {
	channel, exists := m.channels[id]
	if !exists {
		return nil, errors.New("channel not found")
	}
	channel.Deactivate()
	return channel, nil
}

func (m *mockChannelService) DeleteChannel(ctx context.Context, id string) error {
	_, exists := m.channels[id]
	if !exists {
		return errors.New("channel not found")
	}
	delete(m.channels, id)
	return nil
}

func (m *mockChannelService) ListChannels(ctx context.Context, activeOnly bool) ([]*core.Channel, error) {
	var channels []*core.Channel
	for _, channel := range m.channels {
		if !activeOnly || channel.IsActive {
			channels = append(channels, channel)
		}
	}
	return channels, nil
}

func (m *mockChannelService) ChannelExists(ctx context.Context, id string) (bool, error) {
	_, exists := m.channels[id]
	return exists, nil
}

// Test data structures are defined in http.go

func TestHTTPAdapter_HandleCreateChannel(t *testing.T) {
	service := newMockChannelService()
	adapter := NewHTTPAdapter(service)

	tests := []struct {
		name           string
		method         string
		requestBody    CreateChannelRequest
		expectedStatus int
		expectedError  string
	}{
		{
			name:   "successful channel creation",
			method: http.MethodPost,
			requestBody: CreateChannelRequest{
				ID:      "test-channel-1",
				Name:    "Test Channel",
				Concept: "Educational content about programming",
			},
			expectedStatus: http.StatusCreated,
		},
		{
			name:   "invalid method",
			method: http.MethodGet,
			requestBody: CreateChannelRequest{
				ID:      "test-channel-2",
				Name:    "Test Channel",
				Concept: "Educational content",
			},
			expectedStatus: http.StatusMethodNotAllowed,
		},
		{
			name:   "missing ID",
			method: http.MethodPost,
			requestBody: CreateChannelRequest{
				Name:    "Test Channel",
				Concept: "Educational content",
			},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:   "missing name",
			method: http.MethodPost,
			requestBody: CreateChannelRequest{
				ID:      "test-channel-3",
				Concept: "Educational content",
			},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:   "missing concept",
			method: http.MethodPost,
			requestBody: CreateChannelRequest{
				ID:   "test-channel-4",
				Name: "Test Channel",
			},
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			body, _ := json.Marshal(tt.requestBody)
			req := httptest.NewRequest(tt.method, "/channels", bytes.NewReader(body))
			req.Header.Set("Content-Type", "application/json")

			rr := httptest.NewRecorder()
			adapter.HandleCreateChannel(rr, req)

			if rr.Code != tt.expectedStatus {
				t.Errorf("HandleCreateChannel() status = %v, want %v", rr.Code, tt.expectedStatus)
			}

			if tt.expectedStatus == http.StatusCreated {
				var channel core.Channel
				err := json.NewDecoder(rr.Body).Decode(&channel)
				if err != nil {
					t.Errorf("Failed to decode response: %v", err)
					t.Logf("Response body: %s", rr.Body.String())
				}

				if channel.ID != tt.requestBody.ID {
					t.Errorf("Response ID = %v, want %v", channel.ID, tt.requestBody.ID)
				}
			}
		})
	}
}

func TestHTTPAdapter_HandleGetChannel(t *testing.T) {
	service := newMockChannelService()
	adapter := NewHTTPAdapter(service)

	// Create a test channel
	channel, _ := service.CreateChannel(context.Background(), "test-channel", "Test Channel", "Test concept")

	tests := []struct {
		name           string
		method         string
		channelID      string
		expectedStatus int
	}{
		{
			name:           "successful channel retrieval",
			method:         http.MethodGet,
			channelID:      "test-channel",
			expectedStatus: http.StatusOK,
		},
		{
			name:           "invalid method",
			method:         http.MethodPost,
			channelID:      "test-channel",
			expectedStatus: http.StatusMethodNotAllowed,
		},
		{
			name:           "channel not found",
			method:         http.MethodGet,
			channelID:      "nonexistent",
			expectedStatus: http.StatusNotFound,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, "/channels/"+tt.channelID, nil)

			rr := httptest.NewRecorder()
			adapter.HandleGetChannel(rr, req)

			if rr.Code != tt.expectedStatus {
				t.Errorf("HandleGetChannel() status = %v, want %v", rr.Code, tt.expectedStatus)
			}

			if tt.expectedStatus == http.StatusOK {
				var responseChannel core.Channel
				err := json.NewDecoder(rr.Body).Decode(&responseChannel)
				if err != nil {
					t.Errorf("Failed to decode response: %v", err)
					t.Logf("Response body: %s", rr.Body.String())
				}

				if responseChannel.ID != channel.ID {
					t.Errorf("Response ID = %v, want %v", responseChannel.ID, channel.ID)
				}
			}
		})
	}
}

func TestHTTPAdapter_HandleUpdateChannelInfo(t *testing.T) {
	service := newMockChannelService()
	adapter := NewHTTPAdapter(service)

	// Create a test channel
	_, err := service.CreateChannel(context.Background(), "test-channel", "Test Channel", "Test concept")
	if err != nil {
		t.Fatalf("Failed to create test channel: %v", err)
	}

	tests := []struct {
		name           string
		method         string
		channelID      string
		requestBody    UpdateChannelInfoRequest
		expectedStatus int
	}{
		{
			name:      "successful channel info update",
			method:    http.MethodPut,
			channelID: "test-channel",
			requestBody: UpdateChannelInfoRequest{
				Name:    "Updated Channel Name",
				Concept: "Updated concept",
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:      "invalid method",
			method:    http.MethodGet,
			channelID: "test-channel",
			requestBody: UpdateChannelInfoRequest{
				Name:    "Updated Channel Name",
				Concept: "Updated concept",
			},
			expectedStatus: http.StatusMethodNotAllowed,
		},
		{
			name:      "channel not found",
			method:    http.MethodPut,
			channelID: "nonexistent",
			requestBody: UpdateChannelInfoRequest{
				Name:    "Updated Channel Name",
				Concept: "Updated concept",
			},
			expectedStatus: http.StatusNotFound,
		},
		{
			name:      "missing name",
			method:    http.MethodPut,
			channelID: "test-channel",
			requestBody: UpdateChannelInfoRequest{
				Concept: "Updated concept",
			},
			expectedStatus: http.StatusBadRequest,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			body, _ := json.Marshal(tt.requestBody)
			req := httptest.NewRequest(tt.method, "/channels/"+tt.channelID, bytes.NewReader(body))
			req.Header.Set("Content-Type", "application/json")

			rr := httptest.NewRecorder()
			adapter.HandleUpdateChannelInfo(rr, req)

			if rr.Code != tt.expectedStatus {
				t.Errorf("HandleUpdateChannelInfo() status = %v, want %v", rr.Code, tt.expectedStatus)
			}
		})
	}
}

func TestHTTPAdapter_HandleListChannels(t *testing.T) {
	service := newMockChannelService()
	adapter := NewHTTPAdapter(service)

	// Create test channels
	_, err := service.CreateChannel(context.Background(), "channel-1", "Channel 1", "Concept 1")
	if err != nil {
		t.Fatalf("Failed to create test channel 1: %v", err)
	}
	_, err = service.CreateChannel(context.Background(), "channel-2", "Channel 2", "Concept 2")
	if err != nil {
		t.Fatalf("Failed to create test channel 2: %v", err)
	}

	// Deactivate one channel
	_, err = service.DeactivateChannel(context.Background(), "channel-2")
	if err != nil {
		t.Fatalf("Failed to deactivate test channel: %v", err)
	}

	tests := []struct {
		name           string
		method         string
		queryParam     string
		expectedStatus int
		expectedCount  int
	}{
		{
			name:           "list all channels",
			method:         http.MethodGet,
			queryParam:     "",
			expectedStatus: http.StatusOK,
			expectedCount:  2,
		},
		{
			name:           "list active channels only",
			method:         http.MethodGet,
			queryParam:     "?active_only=true",
			expectedStatus: http.StatusOK,
			expectedCount:  1,
		},
		{
			name:           "invalid method",
			method:         http.MethodPost,
			queryParam:     "",
			expectedStatus: http.StatusMethodNotAllowed,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, "/channels"+tt.queryParam, nil)

			rr := httptest.NewRecorder()
			adapter.HandleListChannels(rr, req)

			if rr.Code != tt.expectedStatus {
				t.Errorf("HandleListChannels() status = %v, want %v", rr.Code, tt.expectedStatus)
			}

			if tt.expectedStatus == http.StatusOK {
				var response map[string]interface{}
				err := json.NewDecoder(rr.Body).Decode(&response)
				if err != nil {
					t.Errorf("Failed to decode response: %v", err)
				}

				channels, ok := response["channels"].([]interface{})
				if !ok {
					t.Errorf("Response channels is not an array")
				}

				if len(channels) != tt.expectedCount {
					t.Errorf("Channel count = %v, want %v", len(channels), tt.expectedCount)
				}
			}
		})
	}
}

func TestHTTPAdapter_HandleDeleteChannel(t *testing.T) {
	service := newMockChannelService()
	adapter := NewHTTPAdapter(service)

	// Create a test channel
	_, err := service.CreateChannel(context.Background(), "test-channel", "Test Channel", "Test concept")
	if err != nil {
		t.Fatalf("Failed to create test channel: %v", err)
	}

	tests := []struct {
		name           string
		method         string
		channelID      string
		expectedStatus int
	}{
		{
			name:           "successful channel deletion",
			method:         http.MethodDelete,
			channelID:      "test-channel",
			expectedStatus: http.StatusNoContent,
		},
		{
			name:           "invalid method",
			method:         http.MethodGet,
			channelID:      "test-channel",
			expectedStatus: http.StatusMethodNotAllowed,
		},
		{
			name:           "channel not found",
			method:         http.MethodDelete,
			channelID:      "nonexistent",
			expectedStatus: http.StatusNotFound,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, "/channels/"+tt.channelID, nil)

			rr := httptest.NewRecorder()
			adapter.HandleDeleteChannel(rr, req)

			if rr.Code != tt.expectedStatus {
				t.Errorf("HandleDeleteChannel() status = %v, want %v", rr.Code, tt.expectedStatus)
			}
		})
	}
}
