package adapters

import (
	"encoding/json"
	"fmt"
	"net/http"
	"ssulmeta-go/internal/calculator/ports"
	"strconv"
)

// HTTPAdapter handles HTTP requests for calculator operations
type HTTPAdapter struct {
	calc ports.CalculatorService
}

// NewHTTPAdapter creates a new HTTP adapter with the given calculator service
func NewHTTPAdapter(calc ports.CalculatorService) *HTTPAdapter {
	return &HTTPAdapter{calc: calc}
}

// HandleAdd handles HTTP requests for addition
func (h *HTTPAdapter) HandleAdd(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	aStr := r.URL.Query().Get("a")
	bStr := r.URL.Query().Get("b")

	a, err := strconv.Atoi(aStr)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid parameter a: %v", err), http.StatusBadRequest)
		return
	}

	b, err := strconv.Atoi(bStr)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid parameter b: %v", err), http.StatusBadRequest)
		return
	}

	result := h.calc.Add(a, b)

	response := map[string]interface{}{
		"result": result,
		"operation": "add",
		"a": a,
		"b": b,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

// HandleMultiply handles HTTP requests for multiplication
func (h *HTTPAdapter) HandleMultiply(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	aStr := r.URL.Query().Get("a")
	bStr := r.URL.Query().Get("b")

	a, err := strconv.Atoi(aStr)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid parameter a: %v", err), http.StatusBadRequest)
		return
	}

	b, err := strconv.Atoi(bStr)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid parameter b: %v", err), http.StatusBadRequest)
		return
	}

	result := h.calc.Multiply(a, b)

	response := map[string]interface{}{
		"result": result,
		"operation": "multiply",
		"a": a,
		"b": b,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}