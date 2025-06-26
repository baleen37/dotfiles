package adapters

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHandleHealth(t *testing.T) {
	req, err := http.NewRequest("GET", "/health", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(HandleHealth)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("HandleHealth() status = %v, want %v", status, http.StatusOK)
	}

	var response map[string]interface{}
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Fatal(err)
	}

	if response["status"] != "healthy" {
		t.Errorf("HandleHealth() status = %v, want %v", response["status"], "healthy")
	}

	if response["service"] != "ssulmeta-go" {
		t.Errorf("HandleHealth() service = %v, want %v", response["service"], "ssulmeta-go")
	}
}

func TestHandleHealth_MethodNotAllowed(t *testing.T) {
	req, err := http.NewRequest("POST", "/health", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(HandleHealth)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusMethodNotAllowed {
		t.Errorf("HandleHealth() with POST method status = %v, want %v", status, http.StatusMethodNotAllowed)
	}
}

func BenchmarkHandleHealth(b *testing.B) {
	req, _ := http.NewRequest("GET", "/health", nil)
	handler := http.HandlerFunc(HandleHealth)

	for i := 0; i < b.N; i++ {
		rr := httptest.NewRecorder()
		handler.ServeHTTP(rr, req)
	}
}