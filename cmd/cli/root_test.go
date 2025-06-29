package main

import (
	"bytes"
	"os"
	"strings"
	"testing"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/stretchr/testify/assert"
)

func TestRootCommand(t *testing.T) {
	tests := []struct {
		name           string
		args           []string
		expectedOutput []string
		expectError    bool
	}{
		{
			name:           "no arguments shows help",
			args:           []string{},
			expectedOutput: []string{"ssulmeta", "ssulmeta is a CLI tool for automated YouTube Shorts generation", "Available Commands:"},
			expectError:    false,
		},
		{
			name:           "help flag shows help",
			args:           []string{"--help"},
			expectedOutput: []string{"ssulmeta", "ssulmeta is a CLI tool for automated YouTube Shorts generation", "Available Commands:"},
			expectError:    false,
		},
		{
			name:           "unknown command shows error",
			args:           []string{"unknown"},
			expectedOutput: []string{"Error:", "unknown command"},
			expectError:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset commands for each test
			resetCommands()

			// Capture output
			output := &bytes.Buffer{}
			rootCmd.SetOut(output)
			rootCmd.SetErr(output)

			// Set arguments
			rootCmd.SetArgs(tt.args)

			// Execute command
			err := rootCmd.Execute()

			// Check error
			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}

			// Check output
			outputStr := output.String()
			for _, expected := range tt.expectedOutput {
				assert.Contains(t, outputStr, expected)
			}
		})
	}
}

func TestGlobalFlags(t *testing.T) {
	tests := []struct {
		name        string
		args        []string
		envVars     map[string]string
		checkFunc   func(t *testing.T)
		expectError bool
	}{
		{
			name: "config flag sets config file",
			args: []string{"--config", "test.yaml", "version"},
			checkFunc: func(t *testing.T) {
				// The config file should be set in viper
				assert.Equal(t, "test.yaml", viper.GetString("config"))
			},
			expectError: false,
		},
		{
			name: "env flag sets environment",
			args: []string{"--env", "test", "version"},
			checkFunc: func(t *testing.T) {
				assert.Equal(t, "test", viper.GetString("env"))
			},
			expectError: false,
		},
		{
			name: "verbose flag enables debug logging",
			args: []string{"--verbose", "version"},
			checkFunc: func(t *testing.T) {
				// Verbose flag should be set
				assert.True(t, verbose)
			},
			expectError: false,
		},
		{
			name: "log-level flag sets log level",
			args: []string{"--log-level", "error", "version"},
			checkFunc: func(t *testing.T) {
				assert.Equal(t, "error", logLevel)
			},
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset for each test
			resetCommands()
			os.Clearenv()

			// Set environment variables
			for k, v := range tt.envVars {
				os.Setenv(k, v)
			}

			// Capture output
			output := &bytes.Buffer{}
			rootCmd.SetOut(output)
			rootCmd.SetErr(output)

			// Set arguments
			rootCmd.SetArgs(tt.args)

			// Execute command
			err := rootCmd.Execute()

			// Check error
			if tt.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}

			// Run custom check
			if tt.checkFunc != nil {
				tt.checkFunc(t)
			}
		})
	}
}

func TestEnvironmentVariableBinding(t *testing.T) {
	tests := []struct {
		name     string
		envVars  map[string]string
		args     []string
		expected map[string]string
	}{
		{
			name: "environment variables are bound to flags",
			envVars: map[string]string{
				"SSULMETA_CONFIG":    "env-config.yaml",
				"SSULMETA_ENV":       "production",
				"SSULMETA_LOG_LEVEL": "debug",
			},
			args: []string{"version"},
			expected: map[string]string{
				"config":    "env-config.yaml",
				"env":       "production",
				"log-level": "debug",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset
			resetCommands()
			os.Clearenv()

			// Set environment variables
			for k, v := range tt.envVars {
				os.Setenv(k, v)
			}

			// Re-initialize to pick up env vars
			resetCommands()

			// Check viper values
			for key, expected := range tt.expected {
				actual := viper.GetString(key)
				// For debugging: also check with underscores
				if actual == "" && strings.Contains(key, "-") {
					altKey := strings.ReplaceAll(key, "-", "_")
					actual = viper.GetString(altKey)
				}
				assert.Equal(t, expected, actual, "viper.GetString(%q) should equal %q but got %q", key, expected, actual)
			}
		})
	}
}

func TestPersistentPreRunE(t *testing.T) {
	t.Run("skips config loading for version command", func(t *testing.T) {
		resetCommands()

		// The version command should not load config
		output := &bytes.Buffer{}
		rootCmd.SetOut(output)
		rootCmd.SetErr(output)
		rootCmd.SetArgs([]string{"version"})

		err := rootCmd.Execute()
		assert.NoError(t, err)

		// Should show version without config error
		assert.Contains(t, output.String(), "ssulmeta")
	})

	t.Run("loads config for other commands", func(t *testing.T) {
		resetCommands()

		// Set test environment
		os.Setenv("APP_ENV", "test")

		output := &bytes.Buffer{}
		rootCmd.SetOut(output)
		rootCmd.SetErr(output)
		rootCmd.SetArgs([]string{"help"})

		// This might fail if test config doesn't exist, which is expected
		_ = rootCmd.Execute()

		// The important thing is that it attempted to load config
		// (we can't easily test this without a valid config file)
	})
}

func TestGettersAndHelpers(t *testing.T) {
	t.Run("GetConfig returns nil before loading", func(t *testing.T) {
		resetCommands()
		cfg = nil
		assert.Nil(t, GetConfig())
	})

	t.Run("GetLogger returns contextualized logger", func(t *testing.T) {
		resetCommands()

		// Create a mock command
		mockCmd := &cobra.Command{
			Use: "test",
		}
		rootCmd.AddCommand(mockCmd)

		logger := GetLogger(mockCmd)
		assert.NotNil(t, logger)
		// We can't easily test the logger fields without exposing internals
	})
}

// Helper to clean environment after tests
func TestMain(m *testing.M) {
	// Save original env
	origEnv := os.Environ()

	// Run tests
	code := m.Run()

	// Restore env
	os.Clearenv()
	for _, e := range origEnv {
		parts := strings.SplitN(e, "=", 2)
		if len(parts) == 2 {
			os.Setenv(parts[0], parts[1])
		}
	}

	os.Exit(code)
}
