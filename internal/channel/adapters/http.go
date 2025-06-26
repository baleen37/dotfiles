package adapters

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"ssulmeta-go/internal/channel/core"
	"ssulmeta-go/internal/channel/ports"
)

// HTTPAdapter handles HTTP requests for channel operations
type HTTPAdapter struct {
	service ports.ChannelService
}

// NewHTTPAdapter creates a new HTTP adapter with the given channel service
func NewHTTPAdapter(service ports.ChannelService) *HTTPAdapter {
	return &HTTPAdapter{service: service}
}

// CreateChannelRequest represents the request body for creating a channel
type CreateChannelRequest struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Concept string `json:"concept"`
}

// UpdateChannelInfoRequest represents the request body for updating channel info
type UpdateChannelInfoRequest struct {
	Name    string `json:"name"`
	Concept string `json:"concept"`
}

// UpdateChannelSettingsRequest represents the request body for updating channel settings
type UpdateChannelSettingsRequest struct {
	Settings core.ChannelSettings `json:"settings"`
}

// HandleCreateChannel handles HTTP requests for creating a new channel
func (h *HTTPAdapter) HandleCreateChannel(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req CreateChannelRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	if req.ID == "" {
		http.Error(w, "Channel ID is required", http.StatusBadRequest)
		return
	}

	if req.Name == "" {
		http.Error(w, "Channel name is required", http.StatusBadRequest)
		return
	}

	if req.Concept == "" {
		http.Error(w, "Channel concept is required", http.StatusBadRequest)
		return
	}

	channel, err := h.service.CreateChannel(r.Context(), req.ID, req.Name, req.Concept)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create channel: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(channel); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

// HandleGetChannel handles HTTP requests for retrieving a channel
func (h *HTTPAdapter) HandleGetChannel(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract channel ID from URL path
	// Assuming URL pattern: /channels/{id}
	path := strings.TrimPrefix(r.URL.Path, "/channels/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "Channel ID is required", http.StatusBadRequest)
		return
	}

	channelID := path

	channel, err := h.service.GetChannel(r.Context(), channelID)
	if err != nil {
		// Check if error contains "channel not found" (from wrapped error)
		if strings.Contains(err.Error(), "channel not found") {
			http.Error(w, "Channel not found", http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to get channel: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(channel); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

// HandleUpdateChannelInfo handles HTTP requests for updating channel info
func (h *HTTPAdapter) HandleUpdateChannelInfo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract channel ID from URL path
	path := strings.TrimPrefix(r.URL.Path, "/channels/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "Channel ID is required", http.StatusBadRequest)
		return
	}

	channelID := path

	var req UpdateChannelInfoRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	if req.Name == "" {
		http.Error(w, "Channel name is required", http.StatusBadRequest)
		return
	}

	if req.Concept == "" {
		http.Error(w, "Channel concept is required", http.StatusBadRequest)
		return
	}

	channel, err := h.service.UpdateChannelInfo(r.Context(), channelID, req.Name, req.Concept)
	if err != nil {
		if strings.Contains(err.Error(), "channel not found") {
			http.Error(w, "Channel not found", http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to update channel: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(channel); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

// HandleUpdateChannelSettings handles HTTP requests for updating channel settings
func (h *HTTPAdapter) HandleUpdateChannelSettings(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract channel ID from URL path
	path := strings.TrimPrefix(r.URL.Path, "/channels/")
	pathParts := strings.Split(path, "/")
	if len(pathParts) < 2 || pathParts[1] != "settings" {
		http.Error(w, "Invalid URL path", http.StatusBadRequest)
		return
	}

	channelID := pathParts[0]

	var req UpdateChannelSettingsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	channel, err := h.service.UpdateChannelSettings(r.Context(), channelID, req.Settings)
	if err != nil {
		if strings.Contains(err.Error(), "channel not found") {
			http.Error(w, "Channel not found", http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to update channel settings: %v", err), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(channel); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

// HandleListChannels handles HTTP requests for listing channels
func (h *HTTPAdapter) HandleListChannels(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Check for active_only query parameter
	activeOnly := r.URL.Query().Get("active_only") == "true"

	channels, err := h.service.ListChannels(r.Context(), activeOnly)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to list channels: %v", err), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"channels": channels,
		"count":    len(channels),
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

// HandleDeleteChannel handles HTTP requests for deleting a channel
func (h *HTTPAdapter) HandleDeleteChannel(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract channel ID from URL path
	path := strings.TrimPrefix(r.URL.Path, "/channels/")
	if path == "" || path == r.URL.Path {
		http.Error(w, "Channel ID is required", http.StatusBadRequest)
		return
	}

	channelID := path

	err := h.service.DeleteChannel(r.Context(), channelID)
	if err != nil {
		if strings.Contains(err.Error(), "channel not found") {
			http.Error(w, "Channel not found", http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to delete channel: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleActivateChannel handles HTTP requests for activating a channel
func (h *HTTPAdapter) HandleActivateChannel(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract channel ID from URL path
	// Assuming URL pattern: /channels/{id}/activate
	path := strings.TrimPrefix(r.URL.Path, "/channels/")
	pathParts := strings.Split(path, "/")
	if len(pathParts) < 2 || pathParts[1] != "activate" {
		http.Error(w, "Invalid URL path", http.StatusBadRequest)
		return
	}

	channelID := pathParts[0]

	channel, err := h.service.ActivateChannel(r.Context(), channelID)
	if err != nil {
		if strings.Contains(err.Error(), "channel not found") {
			http.Error(w, "Channel not found", http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to activate channel: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(channel); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

// HandleDeactivateChannel handles HTTP requests for deactivating a channel
func (h *HTTPAdapter) HandleDeactivateChannel(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Extract channel ID from URL path
	// Assuming URL pattern: /channels/{id}/deactivate
	path := strings.TrimPrefix(r.URL.Path, "/channels/")
	pathParts := strings.Split(path, "/")
	if len(pathParts) < 2 || pathParts[1] != "deactivate" {
		http.Error(w, "Invalid URL path", http.StatusBadRequest)
		return
	}

	channelID := pathParts[0]

	channel, err := h.service.DeactivateChannel(r.Context(), channelID)
	if err != nil {
		if strings.Contains(err.Error(), "channel not found") {
			http.Error(w, "Channel not found", http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to deactivate channel: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(channel); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}
