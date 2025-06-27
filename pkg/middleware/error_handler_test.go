package middleware

import (
	"net/http"
	"testing"

	"ssulmeta-go/pkg/errors"

	"github.com/stretchr/testify/assert"
)

func TestHTTPStatusCode(t *testing.T) {
	tests := []struct {
		name       string
		errorType  errors.ErrorType
		wantStatus int
	}{
		{
			name:       "ValidationError returns BadRequest",
			errorType:  errors.ErrorTypeValidation,
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "NotFoundError returns NotFound",
			errorType:  errors.ErrorTypeNotFound,
			wantStatus: http.StatusNotFound,
		},
		{
			name:       "UnauthorizedError returns Unauthorized",
			errorType:  errors.ErrorTypeUnauthorized,
			wantStatus: http.StatusUnauthorized,
		},
		{
			name:       "ForbiddenError returns Forbidden",
			errorType:  errors.ErrorTypeForbidden,
			wantStatus: http.StatusForbidden,
		},
		{
			name:       "ConflictError returns Conflict",
			errorType:  errors.ErrorTypeConflict,
			wantStatus: http.StatusConflict,
		},
		{
			name:       "ExternalError returns BadGateway",
			errorType:  errors.ErrorTypeExternal,
			wantStatus: http.StatusBadGateway,
		},
		{
			name:       "InternalError returns InternalServerError",
			errorType:  errors.ErrorTypeInternal,
			wantStatus: http.StatusInternalServerError,
		},
		{
			name:       "UnknownError returns InternalServerError",
			errorType:  errors.ErrorType("UNKNOWN"),
			wantStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := HTTPStatusCode(tt.errorType)
			assert.Equal(t, tt.wantStatus, got)
		})
	}
}

func TestToHTTPResponse(t *testing.T) {
	t.Run("converts AppError without details", func(t *testing.T) {
		appErr := errors.New(errors.ErrorTypeValidation, errors.CodeStoryTooShort, "Story is too short")
		response := ToHTTPResponse(appErr)

		assert.Equal(t, "VALIDATION", response.Error.Type)
		assert.Equal(t, errors.CodeStoryTooShort, response.Error.Code)
		assert.Equal(t, "Story is too short", response.Error.Message)
		assert.Nil(t, response.Error.Details)
	})

	t.Run("converts AppError with details", func(t *testing.T) {
		appErr := errors.New(errors.ErrorTypeValidation, errors.CodeStoryTooShort, "Story is too short")
		_ = appErr.WithDetails("minLength", 270).WithDetails("actualLength", 250)

		response := ToHTTPResponse(appErr)

		assert.Equal(t, "VALIDATION", response.Error.Type)
		assert.Equal(t, errors.CodeStoryTooShort, response.Error.Code)
		assert.Equal(t, "Story is too short", response.Error.Message)
		assert.NotNil(t, response.Error.Details)
		assert.Equal(t, 270, response.Error.Details["minLength"])
		assert.Equal(t, 250, response.Error.Details["actualLength"])
	})
}
