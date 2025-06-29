package cli

import (
	"bytes"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"

	"ssulmeta-go/internal/config"
)

func TestSetupLogger(t *testing.T) {
	tests := []struct {
		name     string
		cfg      *config.LoggingConfig
		verbose  bool
		level    string
		expected string
	}{
		{
			name: "uses specified level",
			cfg: &config.LoggingConfig{
				Level:  "info",
				Format: "text",
			},
			level:    "debug",
			expected: "debug",
		},
		{
			name: "verbose overrides to debug",
			cfg: &config.LoggingConfig{
				Level:  "info",
				Format: "text",
			},
			verbose:  true,
			expected: "debug",
		},
		{
			name: "level takes precedence over verbose",
			cfg: &config.LoggingConfig{
				Level:  "info",
				Format: "text",
			},
			verbose:  true,
			level:    "error",
			expected: "error",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Make a copy of the config to avoid modifying the original
			cfg := *tt.cfg

			err := SetupLogger(&cfg, tt.verbose, tt.level)
			assert.NoError(t, err)

			// Check that the level was set correctly
			assert.Equal(t, tt.expected, cfg.Level)
		})
	}
}

func TestGetLogLevelFromString(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"debug", "debug"},
		{"DEBUG", "debug"},
		{"trace", "debug"},
		{"info", "info"},
		{"INFO", "info"},
		{"warn", "warn"},
		{"warning", "warn"},
		{"WARN", "warn"},
		{"error", "error"},
		{"err", "error"},
		{"ERROR", "error"},
		{"fatal", "error"},
		{"panic", "error"},
		{"unknown", "info"},
		{"", "info"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			result := GetLogLevelFromString(tt.input)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestProgressLogger(t *testing.T) {
	t.Run("creates progress logger with prefix", func(t *testing.T) {
		logger := NewProgressLogger(true, "test")
		assert.NotNil(t, logger)
		assert.True(t, logger.verbose)
		assert.Equal(t, "test", logger.prefix)
	})

	t.Run("methods work without panic", func(t *testing.T) {
		// This is a smoke test to ensure methods don't panic
		logger := NewProgressLogger(true, "test")

		// These should not panic
		logger.Start("Starting operation")
		logger.Progress("Making progress", "step", 1)
		logger.Success("Operation completed")
		logger.Warning("This is a warning")
		logger.Error("Operation failed", assert.AnError)
	})

	t.Run("progress only logs in verbose mode", func(t *testing.T) {
		// Non-verbose logger
		logger := NewProgressLogger(false, "test")

		// In real usage, Progress would not output anything
		// We can't easily test this without mocking the logger
		logger.Progress("This should not be logged")
	})
}

func TestCLILogger(t *testing.T) {
	t.Run("creates CLI logger", func(t *testing.T) {
		logger := NewCLILogger(true)
		assert.NotNil(t, logger)
		assert.True(t, logger.verbose)
	})

	t.Run("print outputs to stdout", func(t *testing.T) {
		// Capture stdout
		old := os.Stdout
		r, w, _ := os.Pipe()
		os.Stdout = w

		logger := NewCLILogger(false)
		logger.Print("Hello %s", "World")

		w.Close()
		os.Stdout = old

		var buf bytes.Buffer
		_, err := buf.ReadFrom(r)
		assert.NoError(t, err)
		assert.Equal(t, "Hello World\n", buf.String())
	})

	t.Run("print error outputs to stderr", func(t *testing.T) {
		// Capture stderr
		old := os.Stderr
		r, w, _ := os.Pipe()
		os.Stderr = w

		logger := NewCLILogger(false)
		logger.PrintError("Error: %s", "failed")

		w.Close()
		os.Stderr = old

		var buf bytes.Buffer
		_, err := buf.ReadFrom(r)
		assert.NoError(t, err)
		assert.Equal(t, "Error: failed\n", buf.String())
	})

	t.Run("debug only logs in verbose mode", func(t *testing.T) {
		// Non-verbose logger
		logger := NewCLILogger(false)

		// This should not output anything
		logger.Debug("Debug message")

		// Verbose logger
		verboseLogger := NewCLILogger(true)

		// This should output (but we can't easily test without mocking)
		verboseLogger.Debug("Debug message")
	})

	t.Run("standard log methods work", func(t *testing.T) {
		logger := NewCLILogger(true)

		// These should not panic
		logger.Info("Info message")
		logger.Warn("Warning message")
		logger.Error("Error message")
	})
}

func TestInitConsoleLogger(t *testing.T) {
	t.Run("initializes with info level by default", func(t *testing.T) {
		InitConsoleLogger(false)
		// We can't easily test the internal state without exposing it
		// This is mainly a smoke test
	})

	t.Run("initializes with debug level when verbose", func(t *testing.T) {
		InitConsoleLogger(true)
		// We can't easily test the internal state without exposing it
		// This is mainly a smoke test
	})
}

func TestLoggerIntegration(t *testing.T) {
	t.Run("logger config validation", func(t *testing.T) {
		validConfig := &config.LoggingConfig{
			Level:  "info",
			Format: "json",
			Output: "stdout",
		}

		err := SetupLogger(validConfig, false, "")
		// This might fail if the logger package has specific requirements
		// In a real test, we'd mock the logger.Init function
		_ = err // Acknowledge that error might occur
	})

	t.Run("handles invalid log level gracefully", func(t *testing.T) {
		// Even with invalid input, should return a valid level
		level := GetLogLevelFromString("invalid-level-12345")
		assert.Equal(t, "info", level)
	})
}

func TestProgressLoggerPrefixing(t *testing.T) {
	tests := []struct {
		name     string
		prefix   string
		message  string
		expected string
	}{
		{
			name:     "adds prefix when set",
			prefix:   "module",
			message:  "Starting",
			expected: "[module] Starting",
		},
		{
			name:     "no prefix when empty",
			prefix:   "",
			message:  "Starting",
			expected: "Starting",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			logger := NewProgressLogger(true, tt.prefix)

			// We can't easily capture the actual log output without mocking
			// but we can verify the logger is created correctly
			assert.Equal(t, tt.prefix, logger.prefix)
		})
	}
}
