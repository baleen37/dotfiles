package cli

import (
	"fmt"
	"log/slog"
	"os"
	"strings"

	"ssulmeta-go/internal/config"
	"ssulmeta-go/pkg/logger"
)

// SetupLogger configures the logger based on CLI flags and config
func SetupLogger(cfg *config.LoggingConfig, verbose bool, level string) error {
	// Priority: explicit level > verbose flag > config level
	if level != "" {
		cfg.Level = GetLogLevelFromString(level)
	} else if verbose {
		cfg.Level = "debug"
	}

	return logger.Init(cfg)
}

// GetLogLevelFromString normalizes log level strings
func GetLogLevelFromString(level string) string {
	switch strings.ToLower(level) {
	case "debug", "trace":
		return "debug"
	case "info":
		return "info"
	case "warn", "warning":
		return "warn"
	case "error", "err", "fatal", "panic":
		return "error"
	default:
		return "info"
	}
}

// ProgressLogger provides user-friendly progress logging for CLI
type ProgressLogger struct {
	verbose bool
	prefix  string
}

// NewProgressLogger creates a new progress logger
func NewProgressLogger(verbose bool, prefix string) *ProgressLogger {
	return &ProgressLogger{
		verbose: verbose,
		prefix:  prefix,
	}
}

// Start logs the beginning of an operation
func (p *ProgressLogger) Start(message string, args ...any) {
	msg := p.formatMessage(message)
	slog.Info(msg, args...)
}

// Progress logs progress updates (only in verbose mode)
func (p *ProgressLogger) Progress(message string, args ...any) {
	if p.verbose {
		msg := p.formatMessage(message)
		slog.Debug(msg, args...)
	}
}

// Success logs successful completion
func (p *ProgressLogger) Success(message string, args ...any) {
	msg := p.formatMessage(message)
	slog.Info(msg, args...)
}

// Warning logs a warning
func (p *ProgressLogger) Warning(message string, args ...any) {
	msg := p.formatMessage(message)
	slog.Warn(msg, args...)
}

// Error logs an error
func (p *ProgressLogger) Error(message string, err error, args ...any) {
	msg := p.formatMessage(message)
	args = append(args, "error", err)
	slog.Error(msg, args...)
}

func (p *ProgressLogger) formatMessage(message string) string {
	if p.prefix != "" {
		return fmt.Sprintf("[%s] %s", p.prefix, message)
	}
	return message
}

// CLILogger provides direct output methods for CLI commands
type CLILogger struct {
	verbose bool
}

// NewCLILogger creates a new CLI logger
func NewCLILogger(verbose bool) *CLILogger {
	return &CLILogger{verbose: verbose}
}

// Print outputs to stdout
func (c *CLILogger) Print(format string, args ...interface{}) {
	fmt.Fprintf(os.Stdout, format+"\n", args...)
}

// PrintError outputs to stderr
func (c *CLILogger) PrintError(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
}

// Debug outputs only in verbose mode
func (c *CLILogger) Debug(format string, args ...interface{}) {
	if c.verbose {
		fmt.Fprintf(os.Stdout, "[DEBUG] "+format+"\n", args...)
	}
}

// Info logs at info level
func (c *CLILogger) Info(message string, args ...any) {
	slog.Info(message, args...)
}

// Warn logs at warn level
func (c *CLILogger) Warn(message string, args ...any) {
	slog.Warn(message, args...)
}

// Error logs at error level
func (c *CLILogger) Error(message string, args ...any) {
	slog.Error(message, args...)
}

// InitConsoleLogger initializes a simple console logger for early CLI usage
func InitConsoleLogger(verbose bool) {
	level := slog.LevelInfo
	if verbose {
		level = slog.LevelDebug
	}

	handler := slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: level,
	})
	slog.SetDefault(slog.New(handler))
}
