package errors

import (
	"fmt"
)

// ErrorType represents the type of error
type ErrorType string

const (
	// ErrorTypeValidation indicates a validation error
	ErrorTypeValidation ErrorType = "VALIDATION"
	// ErrorTypeNotFound indicates a resource not found error
	ErrorTypeNotFound ErrorType = "NOT_FOUND"
	// ErrorTypeExternal indicates an external system error
	ErrorTypeExternal ErrorType = "EXTERNAL"
	// ErrorTypeInternal indicates an internal system error
	ErrorTypeInternal ErrorType = "INTERNAL"
	// ErrorTypeUnauthorized indicates an authentication error
	ErrorTypeUnauthorized ErrorType = "UNAUTHORIZED"
	// ErrorTypeForbidden indicates an authorization error
	ErrorTypeForbidden ErrorType = "FORBIDDEN"
	// ErrorTypeConflict indicates a conflict error
	ErrorTypeConflict ErrorType = "CONFLICT"
)

// AppError represents a standardized application error
type AppError struct {
	Type    ErrorType              `json:"type"`
	Code    string                 `json:"code"`
	Message string                 `json:"message"`
	Cause   error                  `json:"-"`
	Details map[string]interface{} `json:"details,omitempty"`
}

// Error implements the error interface
func (e *AppError) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("%s: %s (caused by: %v)", e.Code, e.Message, e.Cause)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// Unwrap implements the errors.Unwrap interface
func (e *AppError) Unwrap() error {
	return e.Cause
}

// WithDetails adds details to the error
func (e *AppError) WithDetails(key string, value interface{}) *AppError {
	if e.Details == nil {
		e.Details = make(map[string]interface{})
	}
	e.Details[key] = value
	return e
}

// New creates a new AppError
func New(errorType ErrorType, code string, message string) *AppError {
	return &AppError{
		Type:    errorType,
		Code:    code,
		Message: message,
	}
}

// Wrap wraps an existing error with AppError
func Wrap(err error, errorType ErrorType, code string, message string) *AppError {
	return &AppError{
		Type:    errorType,
		Code:    code,
		Message: message,
		Cause:   err,
	}
}

// IsAppError checks if an error is an AppError
func IsAppError(err error) bool {
	_, ok := err.(*AppError)
	return ok
}

// GetAppError converts an error to AppError if possible
func GetAppError(err error) (*AppError, bool) {
	appErr, ok := err.(*AppError)
	return appErr, ok
}
