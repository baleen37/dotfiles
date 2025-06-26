package adapters

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"ssulmeta-go/internal/calculator/core"
	"testing"
)

func TestHTTPAdapter_HandleAdd(t *testing.T) {
	calc := core.NewCalculator()
	adapter := NewHTTPAdapter(calc)

	tests := []struct {
		name       string
		queryA     string
		queryB     string
		wantStatus int
		wantResult int
		wantError  bool
	}{
		{
			name:       "valid addition",
			queryA:     "5",
			queryB:     "3",
			wantStatus: http.StatusOK,
			wantResult: 8,
		},
		{
			name:       "invalid parameter a",
			queryA:     "invalid",
			queryB:     "3",
			wantStatus: http.StatusBadRequest,
			wantError:  true,
		},
		{
			name:       "invalid parameter b",
			queryA:     "5",
			queryB:     "invalid",
			wantStatus: http.StatusBadRequest,
			wantError:  true,
		},
		{
			name:       "negative numbers",
			queryA:     "-10",
			queryB:     "5",
			wantStatus: http.StatusOK,
			wantResult: -5,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req, err := http.NewRequest("GET", "/add?a="+tt.queryA+"&b="+tt.queryB, nil)
			if err != nil {
				t.Fatal(err)
			}

			rr := httptest.NewRecorder()
			handler := http.HandlerFunc(adapter.HandleAdd)
			handler.ServeHTTP(rr, req)

			if rr.Code != tt.wantStatus {
				t.Errorf("HandleAdd() status = %v, want %v", rr.Code, tt.wantStatus)
			}

			if !tt.wantError && rr.Code == http.StatusOK {
				var response map[string]interface{}
				if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
					t.Fatal(err)
				}

				result := int(response["result"].(float64))
				if result != tt.wantResult {
					t.Errorf("HandleAdd() result = %v, want %v", result, tt.wantResult)
				}
			}
		})
	}
}

func TestHTTPAdapter_HandleAdd_MethodNotAllowed(t *testing.T) {
	calc := core.NewCalculator()
	adapter := NewHTTPAdapter(calc)

	req, err := http.NewRequest("POST", "/add?a=5&b=3", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(adapter.HandleAdd)
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusMethodNotAllowed {
		t.Errorf("HandleAdd() with POST method status = %v, want %v", rr.Code, http.StatusMethodNotAllowed)
	}
}

func TestHTTPAdapter_HandleMultiply(t *testing.T) {
	calc := core.NewCalculator()
	adapter := NewHTTPAdapter(calc)

	tests := []struct {
		name       string
		queryA     string
		queryB     string
		wantStatus int
		wantResult int
		wantError  bool
	}{
		{
			name:       "valid multiplication",
			queryA:     "5",
			queryB:     "3",
			wantStatus: http.StatusOK,
			wantResult: 15,
		},
		{
			name:       "multiplication with zero",
			queryA:     "100",
			queryB:     "0",
			wantStatus: http.StatusOK,
			wantResult: 0,
		},
		{
			name:       "negative numbers",
			queryA:     "-5",
			queryB:     "-3",
			wantStatus: http.StatusOK,
			wantResult: 15,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req, err := http.NewRequest("GET", "/multiply?a="+tt.queryA+"&b="+tt.queryB, nil)
			if err != nil {
				t.Fatal(err)
			}

			rr := httptest.NewRecorder()
			handler := http.HandlerFunc(adapter.HandleMultiply)
			handler.ServeHTTP(rr, req)

			if rr.Code != tt.wantStatus {
				t.Errorf("HandleMultiply() status = %v, want %v", rr.Code, tt.wantStatus)
			}

			if !tt.wantError && rr.Code == http.StatusOK {
				var response map[string]interface{}
				if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
					t.Fatal(err)
				}

				result := int(response["result"].(float64))
				if result != tt.wantResult {
					t.Errorf("HandleMultiply() result = %v, want %v", result, tt.wantResult)
				}
			}
		})
	}
}

func BenchmarkHTTPAdapter_HandleAdd(b *testing.B) {
	calc := core.NewCalculator()
	adapter := NewHTTPAdapter(calc)

	req, _ := http.NewRequest("GET", "/add?a=100&b=200", nil)
	handler := http.HandlerFunc(adapter.HandleAdd)

	for i := 0; i < b.N; i++ {
		rr := httptest.NewRecorder()
		handler.ServeHTTP(rr, req)
	}
}