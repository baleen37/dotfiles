package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	calcAdapters "ssulmeta-go/internal/calculator/adapters"
	calcCore "ssulmeta-go/internal/calculator/core"
	channelAdapters "ssulmeta-go/internal/channel/adapters"
	channelService "ssulmeta-go/internal/channel/service"
	"ssulmeta-go/internal/channel/test"
	healthAdapters "ssulmeta-go/internal/health/adapters"
	textAdapters "ssulmeta-go/internal/text/adapters"
	textCore "ssulmeta-go/internal/text/core"
)

// setupTestServer creates a server with mock dependencies for testing
func setupTestServer() *http.Server {
	// Create core services
	calculator := calcCore.NewCalculator()
	textProcessor := textCore.NewProcessor()

	// Create mock channel repository and service
	mockRepo := test.NewMockRepository()
	channelSvc := channelService.NewChannelService(mockRepo)

	// Create HTTP adapters
	calcAdapter := calcAdapters.NewHTTPAdapter(calculator)
	textAdapter := textAdapters.NewHTTPAdapter(textProcessor)
	channelAdapter := channelAdapters.NewHTTPAdapter(channelSvc)

	// Setup routes
	mux := http.NewServeMux()

	// Health check
	mux.HandleFunc("/health", healthAdapters.HandleHealth)

	// Calculator endpoints
	mux.HandleFunc("/calculator/add", calcAdapter.HandleAdd)
	mux.HandleFunc("/calculator/multiply", calcAdapter.HandleMultiply)

	// Text processing endpoints
	mux.HandleFunc("/text/reverse", textAdapter.HandleReverse)
	mux.HandleFunc("/text/capitalize", textAdapter.HandleCapitalize)

	// Channel endpoints
	mux.HandleFunc("/channels", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodPost:
			channelAdapter.HandleCreateChannel(w, r)
		case http.MethodGet:
			channelAdapter.HandleListChannels(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})

	mux.HandleFunc("/channels/", func(w http.ResponseWriter, r *http.Request) {
		// Route based on path and method
		path := r.URL.Path
		method := r.Method

		// Handle /channels/{id}/activate
		if method == http.MethodPost && len(path) > 10 && path[len(path)-9:] == "/activate" {
			channelAdapter.HandleActivateChannel(w, r)
			return
		}

		// Handle /channels/{id}/deactivate
		if method == http.MethodPost && len(path) > 12 && path[len(path)-11:] == "/deactivate" {
			channelAdapter.HandleDeactivateChannel(w, r)
			return
		}

		// Handle /channels/{id}/settings
		if method == http.MethodPut && len(path) > 10 && path[len(path)-9:] == "/settings" {
			channelAdapter.HandleUpdateChannelSettings(w, r)
			return
		}

		// Handle /channels/{id}
		switch method {
		case http.MethodGet:
			channelAdapter.HandleGetChannel(w, r)
		case http.MethodPut:
			channelAdapter.HandleUpdateChannelInfo(w, r)
		case http.MethodDelete:
			channelAdapter.HandleDeleteChannel(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})

	// Create server
	srv := &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}

	return srv
}

func TestServerRoutes(t *testing.T) {
	// Start server in test mode with mock dependencies
	srv := setupTestServer()
	ts := httptest.NewServer(srv.Handler)
	defer ts.Close()

	tests := []struct {
		name       string
		path       string
		wantStatus int
	}{
		{
			name:       "health check",
			path:       "/health",
			wantStatus: http.StatusOK,
		},
		{
			name:       "calculator add",
			path:       "/calculator/add?a=5&b=3",
			wantStatus: http.StatusOK,
		},
		{
			name:       "calculator multiply",
			path:       "/calculator/multiply?a=5&b=3",
			wantStatus: http.StatusOK,
		},
		{
			name:       "text reverse",
			path:       "/text/reverse?text=hello",
			wantStatus: http.StatusOK,
		},
		{
			name:       "text capitalize",
			path:       "/text/capitalize?text=hello",
			wantStatus: http.StatusOK,
		},
		{
			name:       "channels list",
			path:       "/channels",
			wantStatus: http.StatusOK,
		},
		{
			name:       "not found",
			path:       "/unknown",
			wantStatus: http.StatusNotFound,
		},
	}

	client := &http.Client{Timeout: 5 * time.Second}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			resp, err := client.Get(ts.URL + tt.path)
			if err != nil {
				t.Fatal(err)
			}
			defer func() {
				if err := resp.Body.Close(); err != nil {
					t.Logf("Error closing response body: %v", err)
				}
			}()

			if resp.StatusCode != tt.wantStatus {
				t.Errorf("GET %s status = %v, want %v", tt.path, resp.StatusCode, tt.wantStatus)
			}
		})
	}
}

func TestChannelAPIIntegration(t *testing.T) {
	// Start server in test mode with mock repository
	srv := setupTestServer()
	ts := httptest.NewServer(srv.Handler)
	defer ts.Close()

	client := &http.Client{Timeout: 10 * time.Second}

	// Test channel creation
	t.Run("create channel", func(t *testing.T) {
		createReq := map[string]string{
			"id":      "test-channel-1",
			"name":    "Test Channel 1",
			"concept": "Educational programming content",
		}

		body, _ := json.Marshal(createReq)
		resp, err := client.Post(ts.URL+"/channels", "application/json", bytes.NewReader(body))
		if err != nil {
			t.Fatal(err)
		}
		defer func() {
			if err := resp.Body.Close(); err != nil {
				t.Logf("Error closing response body: %v", err)
			}
		}()

		if resp.StatusCode != http.StatusCreated {
			t.Errorf("Create channel status = %v, want %v", resp.StatusCode, http.StatusCreated)
		}
	})

	// Test listing channels
	t.Run("list channels", func(t *testing.T) {
		resp, err := client.Get(ts.URL + "/channels")
		if err != nil {
			t.Fatal(err)
		}
		defer func() {
			if err := resp.Body.Close(); err != nil {
				t.Logf("Error closing response body: %v", err)
			}
		}()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("List channels status = %v, want %v", resp.StatusCode, http.StatusOK)
		}

		var result map[string]interface{}
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			t.Fatal(err)
		}

		// Should have at least the channel we created
		if count, ok := result["count"].(float64); !ok || count < 1 {
			t.Errorf("Expected at least 1 channel, got %v", result["count"])
		}
	})

	// Test getting specific channel
	t.Run("get channel", func(t *testing.T) {
		resp, err := client.Get(ts.URL + "/channels/test-channel-1")
		if err != nil {
			t.Fatal(err)
		}
		defer func() {
			if err := resp.Body.Close(); err != nil {
				t.Logf("Error closing response body: %v", err)
			}
		}()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("Get channel status = %v, want %v", resp.StatusCode, http.StatusOK)
		}
	})

	// Test updating channel info
	t.Run("update channel info", func(t *testing.T) {
		updateReq := map[string]string{
			"name":    "Updated Test Channel",
			"concept": "Updated programming content",
		}

		body, _ := json.Marshal(updateReq)
		req, _ := http.NewRequest(http.MethodPut, ts.URL+"/channels/test-channel-1", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")

		resp, err := client.Do(req)
		if err != nil {
			t.Fatal(err)
		}
		defer func() {
			if err := resp.Body.Close(); err != nil {
				t.Logf("Error closing response body: %v", err)
			}
		}()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("Update channel status = %v, want %v", resp.StatusCode, http.StatusOK)
		}
	})

	// Test channel not found
	t.Run("get nonexistent channel", func(t *testing.T) {
		resp, err := client.Get(ts.URL + "/channels/nonexistent")
		if err != nil {
			t.Fatal(err)
		}
		defer func() {
			if err := resp.Body.Close(); err != nil {
				t.Logf("Error closing response body: %v", err)
			}
		}()

		if resp.StatusCode != http.StatusNotFound {
			t.Errorf("Get nonexistent channel status = %v, want %v", resp.StatusCode, http.StatusNotFound)
		}
	})

	// Test channel deletion
	t.Run("delete channel", func(t *testing.T) {
		req, _ := http.NewRequest(http.MethodDelete, ts.URL+"/channels/test-channel-1", nil)
		resp, err := client.Do(req)
		if err != nil {
			t.Fatal(err)
		}
		defer func() {
			if err := resp.Body.Close(); err != nil {
				t.Logf("Error closing response body: %v", err)
			}
		}()

		if resp.StatusCode != http.StatusNoContent {
			t.Errorf("Delete channel status = %v, want %v", resp.StatusCode, http.StatusNoContent)
		}
	})
}
