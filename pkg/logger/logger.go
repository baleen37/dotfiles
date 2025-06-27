package logger

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"strings"
	"time"

	"ssulmeta-go/internal/config"
)

// Define context key types to avoid collisions
type contextKey string

const (
	// RequestIDKey is the context key for request ID
	RequestIDKey contextKey = "request_id"
	// UserIDKey is the context key for user ID
	UserIDKey contextKey = "user_id"
)

var (
	defaultLogger *slog.Logger
)

// Init initializes the logger based on configuration
func Init(cfg *config.LoggingConfig) error {
	var handler slog.Handler

	// Set log level
	level := parseLevel(cfg.Level)
	opts := &slog.HandlerOptions{
		Level: level,
	}

	// Choose output destination
	var output *os.File
	switch cfg.Output {
	case "stdout":
		output = os.Stdout
	case "file":
		if cfg.FilePath == "" {
			return fmt.Errorf("log file path not specified")
		}
		// TODO: Implement file rotation
		file, err := os.OpenFile(cfg.FilePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
		if err != nil {
			return err
		}
		output = file
	default:
		output = os.Stdout
	}

	// Choose format
	switch cfg.Format {
	case "json":
		handler = slog.NewJSONHandler(output, opts)
	case "text":
		handler = slog.NewTextHandler(output, opts)
	default:
		handler = slog.NewTextHandler(output, opts)
	}

	defaultLogger = slog.New(handler)
	slog.SetDefault(defaultLogger)

	return nil
}

// parseLevel converts string level to slog.Level
func parseLevel(level string) slog.Level {
	switch strings.ToLower(level) {
	case "debug":
		return slog.LevelDebug
	case "info":
		return slog.LevelInfo
	case "warn", "warning":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

// Get returns the default logger
func Get() *slog.Logger {
	if defaultLogger == nil {
		// Return a basic logger if not initialized
		return slog.Default()
	}
	return defaultLogger
}

// With returns a logger with additional attributes
func With(args ...any) *slog.Logger {
	return Get().With(args...)
}

// WithError returns a logger with an error field
func WithError(err error) *slog.Logger {
	return Get().With("error", err)
}

// Debug logs a debug message
func Debug(msg string, args ...any) {
	Get().Debug(msg, args...)
}

// Info logs an info message
func Info(msg string, args ...any) {
	Get().Info(msg, args...)
}

// Warn logs a warning message
func Warn(msg string, args ...any) {
	Get().Warn(msg, args...)
}

// Error logs an error message
func Error(msg string, args ...any) {
	Get().Error(msg, args...)
}

// Structured logging helper functions

// LogFields represents structured logging fields
type LogFields struct {
	RequestID string
	UserID    string
	Operation string
	Duration  time.Duration
	Error     error
}

// WithContext returns a logger with context-based fields
func WithContext(ctx context.Context) *slog.Logger {
	logger := Get()

	// Extract common context values if available
	if requestID := ctx.Value(RequestIDKey); requestID != nil {
		logger = logger.With("request_id", requestID)
	}

	if userID := ctx.Value(UserIDKey); userID != nil {
		logger = logger.With("user_id", userID)
	}

	return logger
}

// WithFields returns a logger with structured fields
func WithFields(fields LogFields) *slog.Logger {
	logger := Get()

	if fields.RequestID != "" {
		logger = logger.With("request_id", fields.RequestID)
	}

	if fields.UserID != "" {
		logger = logger.With("user_id", fields.UserID)
	}

	if fields.Operation != "" {
		logger = logger.With("operation", fields.Operation)
	}

	if fields.Duration > 0 {
		logger = logger.With("duration_ms", fields.Duration.Milliseconds())
	}

	if fields.Error != nil {
		logger = logger.With("error", fields.Error)
	}

	return logger
}

// WithOperation returns a logger with operation field
func WithOperation(operation string) *slog.Logger {
	return Get().With("operation", operation)
}

// WithDuration returns a logger with duration field
func WithDuration(duration time.Duration) *slog.Logger {
	return Get().With("duration_ms", duration.Milliseconds())
}

// LogHTTPRequest logs HTTP request details
func LogHTTPRequest(method, url string, statusCode int, duration time.Duration) {
	Get().Info("http_request",
		"method", method,
		"url", url,
		"status_code", statusCode,
		"duration_ms", duration.Milliseconds(),
	)
}

// LogAPICall logs external API call details
func LogAPICall(service, endpoint string, statusCode int, duration time.Duration, err error) {
	fields := []any{
		"service", service,
		"endpoint", endpoint,
		"status_code", statusCode,
		"duration_ms", duration.Milliseconds(),
	}

	if err != nil {
		fields = append(fields, "error", err)
		Get().Error("api_call_failed", fields...)
	} else {
		Get().Info("api_call_success", fields...)
	}
}

// LogOperation logs operation start/end with duration
func LogOperation(operation string, duration time.Duration, err error) {
	fields := []any{
		"operation", operation,
		"duration_ms", duration.Milliseconds(),
	}

	if err != nil {
		fields = append(fields, "error", err)
		Get().Error("operation_failed", fields...)
	} else {
		Get().Info("operation_completed", fields...)
	}
}
