package middleware

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"ssulmeta-go/pkg/errors"
)

// ErrorHandlingMiddleware wraps HTTP handlers to provide standardized error handling
func ErrorHandlingMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Create a custom response writer to intercept errors
		rw := &responseWriter{
			ResponseWriter: w,
			statusCode:     http.StatusOK,
		}

		// Call the next handler
		next(rw, r)
	}
}

// responseWriter wraps http.ResponseWriter to capture status codes
type responseWriter struct {
	http.ResponseWriter
	statusCode int
	written    bool
}

func (rw *responseWriter) WriteHeader(code int) {
	if !rw.written {
		rw.statusCode = code
		rw.ResponseWriter.WriteHeader(code)
		rw.written = true
	}
}

func (rw *responseWriter) Write(b []byte) (int, error) {
	if !rw.written {
		rw.WriteHeader(http.StatusOK)
	}
	return rw.ResponseWriter.Write(b)
}

// HTTPStatusCode maps ErrorType to HTTP status code
func HTTPStatusCode(errorType errors.ErrorType) int {
	switch errorType {
	case errors.ErrorTypeValidation:
		return http.StatusBadRequest
	case errors.ErrorTypeNotFound:
		return http.StatusNotFound
	case errors.ErrorTypeUnauthorized:
		return http.StatusUnauthorized
	case errors.ErrorTypeForbidden:
		return http.StatusForbidden
	case errors.ErrorTypeConflict:
		return http.StatusConflict
	case errors.ErrorTypeExternal:
		return http.StatusBadGateway
	case errors.ErrorTypeInternal:
		return http.StatusInternalServerError
	default:
		return http.StatusInternalServerError
	}
}

// HTTPErrorResponse represents the standardized HTTP error response
type HTTPErrorResponse struct {
	Error HTTPError `json:"error"`
}

// HTTPError represents the error details in HTTP response
type HTTPError struct {
	Type    string                 `json:"type"`
	Code    string                 `json:"code"`
	Message string                 `json:"message"`
	Details map[string]interface{} `json:"details,omitempty"`
}

// ToHTTPResponse converts AppError to HTTPErrorResponse
func ToHTTPResponse(err *errors.AppError) HTTPErrorResponse {
	return HTTPErrorResponse{
		Error: HTTPError{
			Type:    string(err.Type),
			Code:    err.Code,
			Message: err.Message,
			Details: err.Details,
		},
	}
}

// WriteErrorResponse writes a standardized error response
func WriteErrorResponse(w http.ResponseWriter, err error) {
	// Check if it's an AppError
	appErr, ok := errors.GetAppError(err)
	if !ok {
		// If not an AppError, create a generic internal error
		appErr = errors.New(errors.ErrorTypeInternal, errors.CodeInternalError, "An unexpected error occurred")
		slog.Error("Unexpected error", "error", err)
	}

	// Get HTTP status code
	statusCode := HTTPStatusCode(appErr.Type)

	// Create error response
	response := ToHTTPResponse(appErr)

	// Set headers
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	// Write response
	if encodeErr := json.NewEncoder(w).Encode(response); encodeErr != nil {
		slog.Error("Failed to encode error response", "error", encodeErr)
		// Fall back to plain text
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
	}
}

// WriteValidationError writes a validation error response
func WriteValidationError(w http.ResponseWriter, code string, message string, details map[string]interface{}) {
	appErr := errors.New(errors.ErrorTypeValidation, code, message)
	for k, v := range details {
		_ = appErr.WithDetails(k, v)
	}
	WriteErrorResponse(w, appErr)
}
