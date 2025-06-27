package errors_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"ssulmeta-go/pkg/errors"
	"ssulmeta-go/pkg/middleware"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Example handler that uses our error system
func exampleHandler(w http.ResponseWriter, r *http.Request) {
	action := r.URL.Query().Get("action")

	switch action {
	case "validation":
		err := errors.New(errors.ErrorTypeValidation, errors.CodeInvalidInput, "Invalid input provided").
			WithDetails("field", "email").
			WithDetails("value", "not-an-email")
		middleware.WriteErrorResponse(w, err)

	case "notfound":
		err := errors.New(errors.ErrorTypeNotFound, errors.CodeChannelNotFound, "Channel not found").
			WithDetails("channelId", "ch_123")
		middleware.WriteErrorResponse(w, err)

	case "external":
		err := errors.New(errors.ErrorTypeExternal, errors.CodeOpenAIAPIError, "OpenAI API error").
			WithDetails("statusCode", 429).
			WithDetails("error", "Rate limit exceeded")
		middleware.WriteErrorResponse(w, err)

	case "unauthorized":
		err := errors.New(errors.ErrorTypeUnauthorized, errors.CodeUnauthorized, "Authentication required")
		middleware.WriteErrorResponse(w, err)

	default:
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("OK"))
	}
}

func TestErrorIntegration(t *testing.T) {
	tests := []struct {
		name           string
		action         string
		expectedStatus int
		expectedType   string
		expectedCode   string
	}{
		{
			name:           "Validation error returns 400",
			action:         "validation",
			expectedStatus: http.StatusBadRequest,
			expectedType:   "VALIDATION",
			expectedCode:   errors.CodeInvalidInput,
		},
		{
			name:           "Not found error returns 404",
			action:         "notfound",
			expectedStatus: http.StatusNotFound,
			expectedType:   "NOT_FOUND",
			expectedCode:   errors.CodeChannelNotFound,
		},
		{
			name:           "External error returns 502",
			action:         "external",
			expectedStatus: http.StatusBadGateway,
			expectedType:   "EXTERNAL",
			expectedCode:   errors.CodeOpenAIAPIError,
		},
		{
			name:           "Unauthorized error returns 401",
			action:         "unauthorized",
			expectedStatus: http.StatusUnauthorized,
			expectedType:   "UNAUTHORIZED",
			expectedCode:   errors.CodeUnauthorized,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/?action="+tt.action, nil)
			rec := httptest.NewRecorder()

			exampleHandler(rec, req)

			assert.Equal(t, tt.expectedStatus, rec.Code)
			assert.Equal(t, "application/json", rec.Header().Get("Content-Type"))

			var response middleware.HTTPErrorResponse
			err := json.NewDecoder(rec.Body).Decode(&response)
			assert.NoError(t, err)

			assert.Equal(t, tt.expectedType, response.Error.Type)
			assert.Equal(t, tt.expectedCode, response.Error.Code)
			assert.NotEmpty(t, response.Error.Message)
		})
	}
}

// TestErrorPropagation tests error propagation through layers
func TestErrorPropagation(t *testing.T) {
	ctx := context.Background()

	// Simulate an error from a lower layer
	originalErr := errors.New(errors.ErrorTypeExternal, errors.CodeRedisConnectionFail, "Redis connection failed")

	// Wrap it at a higher layer
	wrappedErr := errors.Wrap(originalErr, errors.ErrorTypeInternal, errors.CodeChannelListFailed, "Failed to list channels")

	// The wrapped error should maintain the original error type and code
	appErr, ok := errors.GetAppError(wrappedErr)
	assert.True(t, ok)
	assert.Equal(t, errors.ErrorTypeInternal, appErr.Type)
	assert.Equal(t, errors.CodeChannelListFailed, appErr.Code)
	assert.Equal(t, originalErr, appErr.Cause)

	// When converted to HTTP response, it should use the wrapper's type
	statusCode := middleware.HTTPStatusCode(appErr.Type)
	assert.Equal(t, http.StatusInternalServerError, statusCode)

	_ = ctx // Silence unused variable warning
}
