package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestServerRoutes(t *testing.T) {
	// Start server in test mode
	srv := setupServer()
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
