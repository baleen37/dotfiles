package adapters

import (
	"encoding/json"
	"net/http"
	"ssulmeta-go/internal/text/ports"
)

// HTTPAdapter handles HTTP requests for text processing operations
type HTTPAdapter struct {
	processor ports.TextProcessor
}

// NewHTTPAdapter creates a new HTTP adapter with the given text processor
func NewHTTPAdapter(processor ports.TextProcessor) *HTTPAdapter {
	return &HTTPAdapter{processor: processor}
}

// HandleReverse handles HTTP requests for text reversal
func (h *HTTPAdapter) HandleReverse(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	text := r.URL.Query().Get("text")
	if text == "" {
		http.Error(w, "Text parameter is required", http.StatusBadRequest)
		return
	}

	result := h.processor.Reverse(text)

	response := map[string]interface{}{
		"result": result,
		"operation": "reverse",
		"original": text,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

// HandleCapitalize handles HTTP requests for text capitalization
func (h *HTTPAdapter) HandleCapitalize(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	text := r.URL.Query().Get("text")
	if text == "" {
		http.Error(w, "Text parameter is required", http.StatusBadRequest)
		return
	}

	result := h.processor.Capitalize(text)

	response := map[string]interface{}{
		"result": result,
		"operation": "capitalize",
		"original": text,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}