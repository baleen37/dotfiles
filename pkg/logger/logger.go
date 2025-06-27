package logger

import (
	"fmt"
	"log/slog"
	"os"
	"strings"

	"ssulmeta-go/internal/config"
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
