package adapters

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"ssulmeta-go/internal/channel/core"
	"strings"
	"testing"
)

// Enhanced mock service for more comprehensive testing
type enhancedMockChannelService struct {
	channels   map[string]*core.Channel
	shouldFail map[string]bool // Controls which methods should fail
	callCount  map[string]int  // Tracks method calls
}

func newEnhancedMockChannelService() *enhancedMockChannelService {
	return &enhancedMockChannelService{
		channels:   make(map[string]*core.Channel),
		shouldFail: make(map[string]bool),
		callCount:  make(map[string]int),
	}
}

func (m *enhancedMockChannelService) CreateChannel(ctx context.Context, id, name, concept string) (*core.Channel, error) {
	m.callCount["CreateChannel"]++
	if m.shouldFail["CreateChannel"] {
		return nil, errors.New("service error")
	}
	
	if _, exists := m.channels[id]; exists {
		return nil, errors.New("channel already exists")
	}
	
	channel, err := core.NewChannel(id, name, concept)
	if err != nil {
		return nil, err
	}
	m.channels[id] = channel
	return channel, nil
}

func (m *enhancedMockChannelService) GetChannel(ctx context.Context, id string) (*core.Channel, error) {
	m.callCount["GetChannel"]++
	if m.shouldFail["GetChannel"] {
		return nil, errors.New("service error")
	}
	
	channel, exists := m.channels[id]
	if !exists {
		return nil, errors.New("channel not found")
	}
	return channel, nil
}

func (m *enhancedMockChannelService) UpdateChannelSettings(ctx context.Context, id string, settings core.ChannelSettings) (*core.Channel, error) {
	m.callCount["UpdateChannelSettings"]++
	if m.shouldFail["UpdateChannelSettings"] {
		return nil, errors.New("service error")
	}
	
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

func (m *enhancedMockChannelService) UpdateChannelInfo(ctx context.Context, id, name, concept string) (*core.Channel, error) {
	m.callCount["UpdateChannelInfo"]++
	if m.shouldFail["UpdateChannelInfo"] {
		return nil, errors.New("service error")
	}
	
	channel, exists := m.channels[id]
	if !exists {
		return nil, errors.New("channel not found")
	}
	channel.Name = name
	channel.Concept = concept
	return channel, nil
}

func (m *enhancedMockChannelService) ActivateChannel(ctx context.Context, id string) (*core.Channel, error) {
	m.callCount["ActivateChannel"]++
	if m.shouldFail["ActivateChannel"] {
		return nil, errors.New("service error")
	}
	
	channel, exists := m.channels[id]
	if !exists {
		return nil, errors.New("channel not found")
	}
	channel.Activate()
	return channel, nil
}

func (m *enhancedMockChannelService) DeactivateChannel(ctx context.Context, id string) (*core.Channel, error) {
	m.callCount["DeactivateChannel"]++
	if m.shouldFail["DeactivateChannel"] {
		return nil, errors.New("service error")
	}
	
	channel, exists := m.channels[id]
	if !exists {
		return nil, errors.New("channel not found")
	}
	channel.Deactivate()
	return channel, nil
}

func (m *enhancedMockChannelService) DeleteChannel(ctx context.Context, id string) error {
	m.callCount["DeleteChannel"]++
	if m.shouldFail["DeleteChannel"] {
		return errors.New("service error")
	}
	
	if _, exists := m.channels[id]; !exists {
		return errors.New("channel not found")
	}
	delete(m.channels, id)
	return nil
}

func (m *enhancedMockChannelService) ListChannels(ctx context.Context, activeOnly bool) ([]*core.Channel, error) {
	m.callCount["ListChannels"]++
	if m.shouldFail["ListChannels"] {
		return nil, errors.New("service error")
	}
	
	var result []*core.Channel
	for _, ch := range m.channels {
		if !activeOnly || ch.IsActive {
			result = append(result, ch)
		}
	}
	return result, nil
}

func (m *enhancedMockChannelService) ChannelExists(ctx context.Context, id string) (bool, error) {
	m.callCount["ChannelExists"]++
	if m.shouldFail["ChannelExists"] {
		return false, errors.New("service error")
	}
	
	_, exists := m.channels[id]
	return exists, nil
}

func TestHTTPAdapter_HandleUpdateChannelSettings(t *testing.T) {
	service := newEnhancedMockChannelService()
	adapter := NewHTTPAdapter(service)
	
	// Create a test channel
	ch, _ := core.NewChannel("ch_123", "Test Channel", "Test concept")
	service.channels["ch_123"] = ch
	
	tests := []struct {
		name           string
		channelID      string
		requestBody    interface{}
		method         string
		setupService   func()
		expectedStatus int
		expectedError  string
	}{
		{
			name:      "successful settings update",
			channelID: "ch_123",
			requestBody: map[string]interface{}{
				"settings": map[string]interface{}{
					"max_video_duration": 30,
					"video_width":        1920,
					"video_height":       1080,
					"video_fps":          30,
					"language":           "en",
				},
			},
			method:         http.MethodPut,
			expectedStatus: http.StatusOK,
		},
		{
			name:      "invalid method",
			channelID: "ch_123",
			requestBody: map[string]interface{}{
				"settings": map[string]interface{}{
					"max_video_duration": 30,
				},
			},
			method:         http.MethodGet,
			expectedStatus: http.StatusMethodNotAllowed,
		},
		{
			name:           "invalid JSON",
			channelID:      "ch_123",
			requestBody:    "invalid json",
			method:         http.MethodPut,
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:      "missing max_video_duration",
			channelID: "ch_123",
			requestBody: map[string]interface{}{
				"settings": map[string]interface{}{
					"video_width":  1920,
					"video_height": 1080,
					"video_fps":    30,
					"language":     "en",
				},
			},
			method:         http.MethodPut,
			expectedStatus: http.StatusBadRequest,
			expectedError:  "max video duration must be greater than 0",
		},
		{
			name:      "channel not found",
			channelID: "ch_nonexistent",
			requestBody: map[string]interface{}{
				"settings": map[string]interface{}{
					"max_video_duration": 30,
					"video_width":        1920,
					"video_height":       1080,
					"video_fps":          30,
					"language":           "en",
				},
			},
			method:         http.MethodPut,
			expectedStatus: http.StatusNotFound,
		},
		{
			name:      "service error",
			channelID: "ch_123",
			requestBody: map[string]interface{}{
				"settings": map[string]interface{}{
					"max_video_duration": 30,
					"video_width":        1920,
					"video_height":       1080,
					"video_fps":          30,
					"language":           "en",
				},
			},
			method: http.MethodPut,
			setupService: func() {
				service.shouldFail["UpdateChannelSettings"] = true
			},
			expectedStatus: http.StatusBadRequest,
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset service state
			service.shouldFail = make(map[string]bool)
			
			if tt.setupService != nil {
				tt.setupService()
			}
			
			var body []byte
			if str, ok := tt.requestBody.(string); ok {
				body = []byte(str)
			} else {
				body, _ = json.Marshal(tt.requestBody)
			}
			
			req := httptest.NewRequest(tt.method, "/channels/"+tt.channelID+"/settings", bytes.NewReader(body))
			rec := httptest.NewRecorder()
			
			adapter.HandleUpdateChannelSettings(rec, req)
			
			if rec.Code != tt.expectedStatus {
				t.Errorf("HandleUpdateChannelSettings() status = %v, want %v; response body: %s", rec.Code, tt.expectedStatus, rec.Body.String())
			}
			
			if tt.expectedError != "" {
				body := rec.Body.String()
				if !strings.Contains(body, tt.expectedError) {
					t.Errorf("HandleUpdateChannelSettings() error response = %v, want containing %v", body, tt.expectedError)
				}
			}
		})
	}
}

func TestHTTPAdapter_HandleActivateChannel(t *testing.T) {
	service := newEnhancedMockChannelService()
	adapter := NewHTTPAdapter(service)
	
	// Create test channels
	ch1, _ := core.NewChannel("ch_active", "Active Channel", "Test")
	ch1.Deactivate() // Start as inactive
	service.channels["ch_active"] = ch1
	
	tests := []struct {
		name           string
		channelID      string
		method         string
		setupService   func()
		expectedStatus int
		checkResult    func(t *testing.T)
	}{
		{
			name:           "successful activation",
			channelID:      "ch_active",
			method:         http.MethodPost,
			expectedStatus: http.StatusOK,
			checkResult: func(t *testing.T) {
				if !service.channels["ch_active"].IsActive {
					t.Error("Channel should be active")
				}
			},
		},
		{
			name:           "invalid method",
			channelID:      "ch_active",
			method:         http.MethodGet,
			expectedStatus: http.StatusMethodNotAllowed,
		},
		{
			name:           "channel not found",
			channelID:      "ch_nonexistent",
			method:         http.MethodPost,
			expectedStatus: http.StatusNotFound,
		},
		{
			name:      "service error",
			channelID: "ch_active",
			method:    http.MethodPost,
			setupService: func() {
				service.shouldFail["ActivateChannel"] = true
			},
			expectedStatus: http.StatusInternalServerError,
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset service state
			service.shouldFail = make(map[string]bool)
			
			if tt.setupService != nil {
				tt.setupService()
			}
			
			req := httptest.NewRequest(tt.method, "/channels/"+tt.channelID+"/activate", nil)
			rec := httptest.NewRecorder()
			
			adapter.HandleActivateChannel(rec, req)
			
			if rec.Code != tt.expectedStatus {
				t.Errorf("HandleActivateChannel() status = %v, want %v", rec.Code, tt.expectedStatus)
			}
			
			if tt.checkResult != nil {
				tt.checkResult(t)
			}
		})
	}
}

func TestHTTPAdapter_HandleDeactivateChannel(t *testing.T) {
	service := newEnhancedMockChannelService()
	adapter := NewHTTPAdapter(service)
	
	// Create test channels
	ch1, _ := core.NewChannel("ch_active", "Active Channel", "Test")
	// Channel is active by default
	service.channels["ch_active"] = ch1
	
	tests := []struct {
		name           string
		channelID      string
		method         string
		setupService   func()
		expectedStatus int
		checkResult    func(t *testing.T)
	}{
		{
			name:           "successful deactivation",
			channelID:      "ch_active",
			method:         http.MethodPost,
			expectedStatus: http.StatusOK,
			checkResult: func(t *testing.T) {
				if service.channels["ch_active"].IsActive {
					t.Error("Channel should be inactive")
				}
			},
		},
		{
			name:           "invalid method",
			channelID:      "ch_active",
			method:         http.MethodGet,
			expectedStatus: http.StatusMethodNotAllowed,
		},
		{
			name:           "channel not found",
			channelID:      "ch_nonexistent",
			method:         http.MethodPost,
			expectedStatus: http.StatusNotFound,
		},
		{
			name:      "service error",
			channelID: "ch_active",
			method:    http.MethodPost,
			setupService: func() {
				service.shouldFail["DeactivateChannel"] = true
			},
			expectedStatus: http.StatusInternalServerError,
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset service state
			service.shouldFail = make(map[string]bool)
			// Reset channel to active state
			if ch, exists := service.channels["ch_active"]; exists {
				ch.Activate()
			}
			
			if tt.setupService != nil {
				tt.setupService()
			}
			
			req := httptest.NewRequest(tt.method, "/channels/"+tt.channelID+"/deactivate", nil)
			rec := httptest.NewRecorder()
			
			adapter.HandleDeactivateChannel(rec, req)
			
			if rec.Code != tt.expectedStatus {
				t.Errorf("HandleDeactivateChannel() status = %v, want %v", rec.Code, tt.expectedStatus)
			}
			
			if tt.checkResult != nil {
				tt.checkResult(t)
			}
		})
	}
}

// Additional edge case tests for existing handlers
func TestHTTPAdapter_HandleCreateChannel_EdgeCases(t *testing.T) {
	service := newEnhancedMockChannelService()
	adapter := NewHTTPAdapter(service)
	
	t.Run("service error during creation", func(t *testing.T) {
		service.shouldFail["CreateChannel"] = true
		
		reqBody := map[string]string{
			"id":      "ch_123",
			"name":    "Test Channel",
			"concept": "Test concept",
		}
		body, _ := json.Marshal(reqBody)
		
		req := httptest.NewRequest(http.MethodPost, "/channels", bytes.NewReader(body))
		rec := httptest.NewRecorder()
		
		adapter.HandleCreateChannel(rec, req)
		
		if rec.Code != http.StatusInternalServerError {
			t.Errorf("HandleCreateChannel() status = %v, want %v", rec.Code, http.StatusInternalServerError)
		}
	})
	
	t.Run("malformed JSON with extra fields", func(t *testing.T) {
		// Reset service state
		service.shouldFail = make(map[string]bool)
		
		reqBody := map[string]interface{}{
			"id":          "ch_extra",
			"name":        "Test Channel",
			"concept":     "Test concept",
			"extra_field": "should be ignored",
		}
		body, _ := json.Marshal(reqBody)
		
		req := httptest.NewRequest(http.MethodPost, "/channels", bytes.NewReader(body))
		rec := httptest.NewRecorder()
		
		adapter.HandleCreateChannel(rec, req)
		
		if rec.Code != http.StatusCreated {
			t.Errorf("HandleCreateChannel() should ignore extra fields, status = %v, body = %s", rec.Code, rec.Body.String())
		}
	})
}

func TestHTTPAdapter_HandleGetChannel_EdgeCases(t *testing.T) {
	service := newEnhancedMockChannelService()
	adapter := NewHTTPAdapter(service)
	
	t.Run("service error", func(t *testing.T) {
		service.channels["ch_123"], _ = core.NewChannel("ch_123", "Test", "Test")
		service.shouldFail["GetChannel"] = true
		
		req := httptest.NewRequest(http.MethodGet, "/channels/ch_123", nil)
		rec := httptest.NewRecorder()
		
		adapter.HandleGetChannel(rec, req)
		
		if rec.Code != http.StatusInternalServerError {
			t.Errorf("HandleGetChannel() status = %v, want %v", rec.Code, http.StatusInternalServerError)
		}
	})
}

func TestHTTPAdapter_HandleUpdateChannelInfo_EdgeCases(t *testing.T) {
	service := newEnhancedMockChannelService()
	adapter := NewHTTPAdapter(service)
	
	// Create a test channel
	ch, _ := core.NewChannel("ch_123", "Test Channel", "Test concept")
	service.channels["ch_123"] = ch
	
	t.Run("service error", func(t *testing.T) {
		service.shouldFail["UpdateChannelInfo"] = true
		
		reqBody := map[string]string{
			"name":    "New Name",
			"concept": "New Concept",
		}
		body, _ := json.Marshal(reqBody)
		
		req := httptest.NewRequest(http.MethodPut, "/channels/ch_123", bytes.NewReader(body))
		rec := httptest.NewRecorder()
		
		adapter.HandleUpdateChannelInfo(rec, req)
		
		if rec.Code != http.StatusInternalServerError {
			t.Errorf("HandleUpdateChannelInfo() status = %v, want %v", rec.Code, http.StatusInternalServerError)
		}
	})
	
	t.Run("empty concept field", func(t *testing.T) {
		reqBody := map[string]string{
			"name":    "New Name",
			"concept": "",
		}
		body, _ := json.Marshal(reqBody)
		
		req := httptest.NewRequest(http.MethodPut, "/channels/ch_123", bytes.NewReader(body))
		rec := httptest.NewRecorder()
		
		adapter.HandleUpdateChannelInfo(rec, req)
		
		if rec.Code != http.StatusBadRequest {
			t.Errorf("HandleUpdateChannelInfo() status = %v, want %v", rec.Code, http.StatusBadRequest)
		}
	})
}

func TestHTTPAdapter_HandleListChannels_EdgeCases(t *testing.T) {
	service := newEnhancedMockChannelService()
	adapter := NewHTTPAdapter(service)
	
	t.Run("service error", func(t *testing.T) {
		service.shouldFail["ListChannels"] = true
		
		req := httptest.NewRequest(http.MethodGet, "/channels", nil)
		rec := httptest.NewRecorder()
		
		adapter.HandleListChannels(rec, req)
		
		if rec.Code != http.StatusInternalServerError {
			t.Errorf("HandleListChannels() status = %v, want %v", rec.Code, http.StatusInternalServerError)
		}
	})
}

func TestHTTPAdapter_HandleDeleteChannel_EdgeCases(t *testing.T) {
	service := newEnhancedMockChannelService()
	adapter := NewHTTPAdapter(service)
	
	// Create a test channel
	ch, _ := core.NewChannel("ch_123", "Test Channel", "Test concept")
	service.channels["ch_123"] = ch
	
	t.Run("service error", func(t *testing.T) {
		service.shouldFail["DeleteChannel"] = true
		
		req := httptest.NewRequest(http.MethodDelete, "/channels/ch_123", nil)
		rec := httptest.NewRecorder()
		
		adapter.HandleDeleteChannel(rec, req)
		
		if rec.Code != http.StatusInternalServerError {
			t.Errorf("HandleDeleteChannel() status = %v, want %v", rec.Code, http.StatusInternalServerError)
		}
	})
}