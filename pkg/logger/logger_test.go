package logger

import (
	"bytes"
	"context"
	"errors"
	"log/slog"
	"strings"
	"testing"
	"time"

	"ssulmeta-go/internal/config"
)

func TestInit(t *testing.T) {
	tests := []struct {
		name        string
		config      *config.LoggingConfig
		expectError bool
	}{
		{
			name: "valid text format config",
			config: &config.LoggingConfig{
				Level:  "info",
				Format: "text",
				Output: "stdout",
			},
			expectError: false,
		},
		{
			name: "valid json format config",
			config: &config.LoggingConfig{
				Level:  "debug",
				Format: "json",
				Output: "stdout",
			},
			expectError: false,
		},
		{
			name: "file output without path",
			config: &config.LoggingConfig{
				Level:  "info",
				Format: "text",
				Output: "file",
			},
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := Init(tt.config)
			if tt.expectError && err == nil {
				t.Error("expected error but got none")
			}
			if !tt.expectError && err != nil {
				t.Errorf("unexpected error: %v", err)
			}
		})
	}
}

func TestParseLevel(t *testing.T) {
	tests := []struct {
		input    string
		expected slog.Level
	}{
		{"debug", slog.LevelDebug},
		{"DEBUG", slog.LevelDebug},
		{"info", slog.LevelInfo},
		{"INFO", slog.LevelInfo},
		{"warn", slog.LevelWarn},
		{"warning", slog.LevelWarn},
		{"error", slog.LevelError},
		{"ERROR", slog.LevelError},
		{"invalid", slog.LevelInfo}, // defaults to info
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			result := parseLevel(tt.input)
			if result != tt.expected {
				t.Errorf("parseLevel(%s) = %v, want %v", tt.input, result, tt.expected)
			}
		})
	}
}

func TestWithFields(t *testing.T) {
	// Initialize logger
	cfg := &config.LoggingConfig{
		Level:  "debug",
		Format: "json",
		Output: "stdout",
	}
	if err := Init(cfg); err != nil {
		t.Fatalf("failed to initialize logger: %v", err)
	}

	fields := LogFields{
		RequestID: "req-123",
		UserID:    "user-456",
		Operation: "test-operation",
		Duration:  100 * time.Millisecond,
		Error:     errors.New("test error"),
	}

	logger := WithFields(fields)
	if logger == nil {
		t.Error("WithFields returned nil logger")
	}
}

func TestWithOperation(t *testing.T) {
	cfg := &config.LoggingConfig{
		Level:  "debug",
		Format: "text",
		Output: "stdout",
	}
	if err := Init(cfg); err != nil {
		t.Fatalf("failed to initialize logger: %v", err)
	}

	logger := WithOperation("test-operation")
	if logger == nil {
		t.Error("WithOperation returned nil logger")
	}
}

func TestWithContext(t *testing.T) {
	cfg := &config.LoggingConfig{
		Level:  "debug",
		Format: "text",
		Output: "stdout",
	}
	if err := Init(cfg); err != nil {
		t.Fatalf("failed to initialize logger: %v", err)
	}

	ctx := context.Background()
	ctx = context.WithValue(ctx, RequestIDKey, "req-123")
	ctx = context.WithValue(ctx, UserIDKey, "user-456")

	logger := WithContext(ctx)
	if logger == nil {
		t.Error("WithContext returned nil logger")
	}
}

func TestLogAPICall(t *testing.T) {
	// Capture log output
	var buf bytes.Buffer

	// Create test handler
	handler := slog.NewTextHandler(&buf, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	})
	defaultLogger = slog.New(handler)

	tests := []struct {
		name        string
		service     string
		endpoint    string
		statusCode  int
		duration    time.Duration
		err         error
		expectError bool
	}{
		{
			name:        "successful api call",
			service:     "openai",
			endpoint:    "chat/completions",
			statusCode:  200,
			duration:    100 * time.Millisecond,
			err:         nil,
			expectError: false,
		},
		{
			name:        "failed api call",
			service:     "openai",
			endpoint:    "chat/completions",
			statusCode:  500,
			duration:    50 * time.Millisecond,
			err:         errors.New("server error"),
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Clear buffer
			buf.Reset()

			LogAPICall(tt.service, tt.endpoint, tt.statusCode, tt.duration, tt.err)

			output := buf.String()
			if output == "" {
				t.Error("expected log output but got empty string")
			}

			// Verify log contains expected fields
			if !strings.Contains(output, tt.service) {
				t.Errorf("log output should contain service %s", tt.service)
			}

			if !strings.Contains(output, tt.endpoint) {
				t.Errorf("log output should contain endpoint %s", tt.endpoint)
			}

			if tt.expectError && !strings.Contains(output, "api_call_failed") {
				t.Error("expected api_call_failed in log output")
			}

			if !tt.expectError && !strings.Contains(output, "api_call_success") {
				t.Error("expected api_call_success in log output")
			}
		})
	}
}

func TestLogOperation(t *testing.T) {
	// Capture log output
	var buf bytes.Buffer

	handler := slog.NewTextHandler(&buf, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	})
	defaultLogger = slog.New(handler)

	tests := []struct {
		name        string
		operation   string
		duration    time.Duration
		err         error
		expectError bool
	}{
		{
			name:        "successful operation",
			operation:   "story_generation",
			duration:    200 * time.Millisecond,
			err:         nil,
			expectError: false,
		},
		{
			name:        "failed operation",
			operation:   "story_generation",
			duration:    100 * time.Millisecond,
			err:         errors.New("generation failed"),
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			buf.Reset()

			LogOperation(tt.operation, tt.duration, tt.err)

			output := buf.String()
			if output == "" {
				t.Error("expected log output but got empty string")
			}

			if !strings.Contains(output, tt.operation) {
				t.Errorf("log output should contain operation %s", tt.operation)
			}

			if tt.expectError && !strings.Contains(output, "operation_failed") {
				t.Error("expected operation_failed in log output")
			}

			if !tt.expectError && !strings.Contains(output, "operation_completed") {
				t.Error("expected operation_completed in log output")
			}
		})
	}
}

func TestBasicLogFunctions(t *testing.T) {
	var buf bytes.Buffer

	handler := slog.NewTextHandler(&buf, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	})
	defaultLogger = slog.New(handler)

	tests := []struct {
		name    string
		logFunc func(string, ...any)
		level   string
		message string
	}{
		{"debug", Debug, "DEBUG", "debug message"},
		{"info", Info, "INFO", "info message"},
		{"warn", Warn, "WARN", "warning message"},
		{"error", Error, "ERROR", "error message"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			buf.Reset()

			tt.logFunc(tt.message, "key", "value")

			output := buf.String()
			if output == "" {
				t.Error("expected log output but got empty string")
			}

			if !strings.Contains(output, tt.level) {
				t.Errorf("log output should contain level %s", tt.level)
			}

			if !strings.Contains(output, tt.message) {
				t.Errorf("log output should contain message %s", tt.message)
			}
		})
	}
}
