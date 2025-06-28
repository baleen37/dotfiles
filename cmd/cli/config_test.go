package main

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gopkg.in/yaml.v3"

	"ssulmeta-go/internal/config"
)

func TestConfigCommand(t *testing.T) {
	tests := []struct {
		name           string
		args           []string
		setupFunc      func()
		expectedOutput []string
		expectError    bool
	}{
		{
			name:           "shows paths when --paths flag is used",
			args:           []string{"config", "--paths"},
			expectedOutput: []string{"Configuration Paths:", "Environment:", "Search paths"},
			expectError:    false,
		},
		{
			name: "shows config in text format by default",
			args: []string{"config"},
			setupFunc: func() {
				// Mock a config
				cfg = &config.Config{
					App: config.AppConfig{
						Name: "test-app",
						Env:  "test",
					},
				}
			},
			expectedOutput: []string{"Current Configuration:", "App:", "Name:"},
			expectError:    false,
		},
		{
			name: "shows config in JSON format",
			args: []string{"config", "-o", "json"},
			setupFunc: func() {
				cfg = &config.Config{
					App: config.AppConfig{
						Name: "test-app",
						Env:  "test",
					},
				}
			},
			expectedOutput: []string{"{", "app", "name", "test-app"},
			expectError:    false,
		},
		{
			name: "shows config in YAML format",
			args: []string{"config", "-o", "yaml"},
			setupFunc: func() {
				cfg = &config.Config{
					App: config.AppConfig{
						Name: "test-app",
						Env:  "test",
					},
				}
			},
			expectedOutput: []string{"app:", "name: test-app"},
			expectError:    false,
		},
		{
			name:           "returns error when config not loaded",
			args:           []string{"config"},
			setupFunc:      func() { cfg = nil },
			expectedOutput: []string{"configuration not loaded"},
			expectError:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset
			resetCommands()

			// Setup
			if tt.setupFunc != nil {
				tt.setupFunc()
			}

			// Capture output
			output := &bytes.Buffer{}
			rootCmd.SetOut(output)
			rootCmd.SetErr(output)

			// Set arguments
			rootCmd.SetArgs(tt.args)

			// Execute
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

func TestConfigPaths(t *testing.T) {
	t.Run("shows explicit config file when set", func(t *testing.T) {
		resetCommands()

		// Set explicit config file
		os.Setenv("CONFIG_FILE", "/path/to/config.yaml")
		defer os.Unsetenv("CONFIG_FILE")

		output := &bytes.Buffer{}
		rootCmd.SetOut(output)
		rootCmd.SetErr(output)
		rootCmd.SetArgs([]string{"config", "--paths"})

		err := rootCmd.Execute()
		require.NoError(t, err)

		outputStr := output.String()
		assert.Contains(t, outputStr, "Explicit config file: /path/to/config.yaml")
		assert.Contains(t, outputStr, "✗ File not found")
	})

	t.Run("shows search paths for environment", func(t *testing.T) {
		resetCommands()

		os.Setenv("APP_ENV", "test")
		defer os.Unsetenv("APP_ENV")

		output := &bytes.Buffer{}
		rootCmd.SetOut(output)
		rootCmd.SetErr(output)
		rootCmd.SetArgs([]string{"config", "--paths"})

		err := rootCmd.Execute()
		require.NoError(t, err)

		outputStr := output.String()
		assert.Contains(t, outputStr, "Environment: test")
		assert.Contains(t, outputStr, "configs/test.yaml")
		assert.Contains(t, outputStr, "config/test.yml")
	})
}

func TestMaskSensitiveData(t *testing.T) {
	tests := []struct {
		name     string
		input    map[string]interface{}
		expected map[string]interface{}
	}{
		{
			name: "masks database DSN",
			input: map[string]interface{}{
				"database": map[string]interface{}{
					"dsn": "user:password@localhost:5432/db",
				},
			},
			expected: map[string]interface{}{
				"database": map[string]interface{}{
					"dsn": "****@localhost:5432/db",
				},
			},
		},
		{
			name: "masks API keys",
			input: map[string]interface{}{
				"api_key": "secret-key-123",
				"apiKey":  "another-secret",
				"token":   "bearer-token",
			},
			expected: map[string]interface{}{
				"api_key": "****",
				"apiKey":  "****",
				"token":   "****",
			},
		},
		{
			name: "masks nested sensitive data",
			input: map[string]interface{}{
				"services": map[string]interface{}{
					"openai": map[string]interface{}{
						"api_key": "sk-1234567890",
					},
				},
			},
			expected: map[string]interface{}{
				"services": map[string]interface{}{
					"openai": map[string]interface{}{
						"api_key": "****",
					},
				},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := maskSensitiveData(tt.input)

			// Convert to JSON for easier comparison
			resultJSON, _ := json.Marshal(result)
			expectedJSON, _ := json.Marshal(tt.expected)

			assert.JSONEq(t, string(expectedJSON), string(resultJSON))
		})
	}
}

func TestMaskDSN(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "masks standard DSN",
			input:    "user:password@localhost:5432/db",
			expected: "****@localhost:5432/db",
		},
		{
			name:     "masks DSN without @ symbol",
			input:    "some-connection-string",
			expected: "some-connection-****",
		},
		{
			name:     "masks short DSN",
			input:    "short",
			expected: "****",
		},
		{
			name:     "handles empty DSN",
			input:    "",
			expected: "****",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := maskDSN(tt.input)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestConfigOutputFormats(t *testing.T) {
	// Create a test config
	testConfig := &config.Config{
		App: config.AppConfig{
			Name:  "test-app",
			Env:   "test",
			Debug: true,
		},
		Database: config.DatabaseConfig{
			Host:     "localhost",
			Port:     5432,
			User:     "user",
			Password: "pass",
			DBName:   "db",
		},
		Logging: config.LoggingConfig{
			Level:  "debug",
			Format: "json",
		},
	}

	t.Run("JSON output is valid", func(t *testing.T) {
		resetCommands()
		cfg = testConfig

		output := &bytes.Buffer{}
		rootCmd.SetOut(output)
		rootCmd.SetErr(output)
		rootCmd.SetArgs([]string{"config", "-o", "json"})

		err := rootCmd.Execute()
		require.NoError(t, err)

		// Verify valid JSON
		var result map[string]interface{}
		err = json.Unmarshal(output.Bytes(), &result)
		require.NoError(t, err)

		// Check some values
		app, ok := result["app"].(map[string]interface{})
		require.True(t, ok)
		assert.Equal(t, "test-app", app["name"])
	})

	t.Run("YAML output is valid", func(t *testing.T) {
		resetCommands()
		cfg = testConfig

		output := &bytes.Buffer{}
		rootCmd.SetOut(output)
		rootCmd.SetErr(output)
		rootCmd.SetArgs([]string{"config", "-o", "yaml"})

		err := rootCmd.Execute()
		require.NoError(t, err)

		// Verify valid YAML
		var result map[string]interface{}
		err = yaml.Unmarshal(output.Bytes(), &result)
		require.NoError(t, err)

		// Check some values
		app, ok := result["app"].(map[string]interface{})
		require.True(t, ok)
		assert.Equal(t, "test-app", app["name"])
	})
}

func TestConfigCommandIntegration(t *testing.T) {
	t.Run("handles missing config file gracefully", func(t *testing.T) {
		resetCommands()

		// Create a temp directory
		tmpDir := t.TempDir()
		oldWd, _ := os.Getwd()
		os.Chdir(tmpDir)
		defer os.Chdir(oldWd)

		output := &bytes.Buffer{}
		rootCmd.SetOut(output)
		rootCmd.SetErr(output)
		rootCmd.SetArgs([]string{"config", "--paths"})

		err := rootCmd.Execute()
		require.NoError(t, err)

		outputStr := output.String()
		assert.Contains(t, outputStr, "✗") // Should show files as not found
	})

	t.Run("finds existing config file", func(t *testing.T) {
		resetCommands()

		// Create a temp directory with config
		tmpDir := t.TempDir()
		configDir := filepath.Join(tmpDir, "configs")
		os.MkdirAll(configDir, 0755)

		// Create a test config file
		configFile := filepath.Join(configDir, "test.yaml")
		os.WriteFile(configFile, []byte("app:\n  name: test"), 0644)

		oldWd, _ := os.Getwd()
		os.Chdir(tmpDir)
		defer os.Chdir(oldWd)

		os.Setenv("APP_ENV", "test")
		defer os.Unsetenv("APP_ENV")

		output := &bytes.Buffer{}
		rootCmd.SetOut(output)
		rootCmd.SetErr(output)
		rootCmd.SetArgs([]string{"config", "--paths"})

		err := rootCmd.Execute()
		require.NoError(t, err)

		outputStr := output.String()
		assert.Contains(t, outputStr, "✓") // Should show file as found
		assert.Contains(t, outputStr, "configs/test.yaml")
	})
}
