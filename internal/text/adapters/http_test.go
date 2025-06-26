package adapters

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"ssulmeta-go/internal/text/core"
	"testing"
)

func TestHTTPAdapter_HandleReverse(t *testing.T) {
	proc := core.NewProcessor()
	adapter := NewHTTPAdapter(proc)

	tests := []struct {
		name       string
		queryText  string
		wantStatus int
		wantResult string
		wantError  bool
	}{
		{
			name:       "valid text",
			queryText:  "hello",
			wantStatus: http.StatusOK,
			wantResult: "olleh",
		},
		{
			name:       "empty text",
			queryText:  "",
			wantStatus: http.StatusBadRequest,
			wantError:  true,
		},
		{
			name:       "unicode text",
			queryText:  "안녕",
			wantStatus: http.StatusOK,
			wantResult: "녕안",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req, err := http.NewRequest("GET", "/reverse?text="+tt.queryText, nil)
			if err != nil {
				t.Fatal(err)
			}

			rr := httptest.NewRecorder()
			handler := http.HandlerFunc(adapter.HandleReverse)
			handler.ServeHTTP(rr, req)

			if rr.Code != tt.wantStatus {
				t.Errorf("HandleReverse() status = %v, want %v", rr.Code, tt.wantStatus)
			}

			if !tt.wantError && rr.Code == http.StatusOK {
				var response map[string]interface{}
				if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
					t.Fatal(err)
				}

				result := response["result"].(string)
				if result != tt.wantResult {
					t.Errorf("HandleReverse() result = %v, want %v", result, tt.wantResult)
				}
			}
		})
	}
}

func TestHTTPAdapter_HandleReverse_MethodNotAllowed(t *testing.T) {
	proc := core.NewProcessor()
	adapter := NewHTTPAdapter(proc)

	req, err := http.NewRequest("POST", "/reverse?text=hello", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(adapter.HandleReverse)
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Errorf("HandleReverse() with POST method status = %v, want %v", rr.Code, http.StatusMethodNotAllowed)
	}
}

func TestHTTPAdapter_HandleCapitalize(t *testing.T) {
	proc := core.NewProcessor()
	adapter := NewHTTPAdapter(proc)

	tests := []struct {
		name       string
		queryText  string
		wantStatus int
		wantResult string
		wantError  bool
	}{
		{
			name:       "lowercase text",
			queryText:  "hello world",
			wantStatus: http.StatusOK,
			wantResult: "Hello World",
		},
		{
			name:       "mixed case text",
			queryText:  "hELLo WORld",
			wantStatus: http.StatusOK,
			wantResult: "Hello World",
		},
		{
			name:       "empty text",
			queryText:  "",
			wantStatus: http.StatusBadRequest,
			wantError:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req, err := http.NewRequest("GET", "/capitalize?text="+tt.queryText, nil)
			if err != nil {
				t.Fatal(err)
			}

			rr := httptest.NewRecorder()
			handler := http.HandlerFunc(adapter.HandleCapitalize)
			handler.ServeHTTP(rr, req)

			if rr.Code != tt.wantStatus {
				t.Errorf("HandleCapitalize() status = %v, want %v", rr.Code, tt.wantStatus)
			}

			if !tt.wantError && rr.Code == http.StatusOK {
				var response map[string]interface{}
				if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
					t.Fatal(err)
				}

				result := response["result"].(string)
				if result != tt.wantResult {
					t.Errorf("HandleCapitalize() result = %v, want %v", result, tt.wantResult)
				}
			}
		})
	}
}

func BenchmarkHTTPAdapter_HandleReverse(b *testing.B) {
	proc := core.NewProcessor()
	adapter := NewHTTPAdapter(proc)

	req, _ := http.NewRequest("GET", "/reverse?text=hello+world", nil)
	handler := http.HandlerFunc(adapter.HandleReverse)

	for i := 0; i < b.N; i++ {
		rr := httptest.NewRecorder()
		handler.ServeHTTP(rr, req)
	}
}
