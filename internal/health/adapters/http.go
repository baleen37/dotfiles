package adapters

import (
	"encoding/json"
	"net/http"
)

// HandleHealth is a simple health check handler
func HandleHealth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response := map[string]interface{}{
		"status": "healthy",
		"service": "ssulmeta-go",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(response); err != nil {
		// Response header already written, can't change status
		// Log would be appropriate here in production
		return
	}
}