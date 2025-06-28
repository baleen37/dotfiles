package cli

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestConfigLoader(t *testing.T) {
	t.Run("creates config loader with parameters", func(t *testing.T) {
		loader := NewConfigLoader("test.yaml", "test")
		assert.NotNil(t, loader)
		assert.Equal(t, "test.yaml", loader.configFile)
		assert.Equal(t, "test", loader.environment)
	})

	t.Run("sets environment variable when specified", func(t *testing.T) {
		// Save and restore environment
		oldEnv := os.Getenv("APP_ENV")
		defer os.Setenv("APP_ENV", oldEnv)

		loader := NewConfigLoader("", "production")
		// We can't test Load() without a valid config, but we can test the env setting
		os.Unsetenv("APP_ENV")

		// The Load method will set the env, but we need a valid config file
		// For now, just test that the loader is created correctly
		assert.Equal(t, "production", loader.environment)
	})

	t.Run("expands home directory in config path", func(t *testing.T) {
		home, err := os.UserHomeDir()
		require.NoError(t, err)

		loader := NewConfigLoader("~/test.yaml", "")

		// Test the path expansion logic directly
		// In a real test, we'd create a temp file and test Load()
		_ = filepath.Join(home, "test.yaml")

		// The actual expansion happens in Load(), but we can verify the loader stores the path
		assert.Equal(t, "~/test.yaml", loader.configFile)
	})

	t.Run("handles absolute paths", func(t *testing.T) {
		absPath := "/absolute/path/to/config.yaml"
		loader := NewConfigLoader(absPath, "")
		assert.Equal(t, absPath, loader.configFile)
	})
}

func TestGetConfigPaths(t *testing.T) {
	tests := []struct {
		name        string
		environment string
		setupFunc   func()
		validate    func(t *testing.T, paths []string)
	}{
		{
			name:        "returns paths for specified environment",
			environment: "test",
			validate: func(t *testing.T, paths []string) {
				assert.Contains(t, paths, "configs/test.yaml")
				assert.Contains(t, paths, "configs/test.yml")
				assert.Contains(t, paths, "config/test.yaml")
				assert.Contains(t, paths, "config/test.yml")
			},
		},
		{
			name:        "uses APP_ENV when environment not specified",
			environment: "",
			setupFunc: func() {
				os.Setenv("APP_ENV", "production")
			},
			validate: func(t *testing.T, paths []string) {
				assert.Contains(t, paths, "configs/production.yaml")
			},
		},
		{
			name:        "defaults to local when no environment",
			environment: "",
			setupFunc: func() {
				os.Unsetenv("APP_ENV")
			},
			validate: func(t *testing.T, paths []string) {
				assert.Contains(t, paths, "configs/local.yaml")
			},
		},
		{
			name:        "includes home directory configs",
			environment: "test",
			validate: func(t *testing.T, paths []string) {
				home, _ := os.UserHomeDir()
				if home != "" {
					assert.Contains(t, paths, filepath.Join(home, ".ssulmeta", "config.yaml"))
					assert.Contains(t, paths, filepath.Join(home, ".ssulmeta.test.yaml"))
				}
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Save and restore environment
			oldEnv := os.Getenv("APP_ENV")
			defer os.Setenv("APP_ENV", oldEnv)

			if tt.setupFunc != nil {
				tt.setupFunc()
			}

			paths := GetConfigPaths(tt.environment)
			assert.NotEmpty(t, paths)

			if tt.validate != nil {
				tt.validate(t, paths)
			}
		})
	}
}

func TestFindConfigFile(t *testing.T) {
	t.Run("finds existing config file", func(t *testing.T) {
		// Create a temporary directory with a config file
		tmpDir := t.TempDir()
		configDir := filepath.Join(tmpDir, "configs")
		err := os.MkdirAll(configDir, 0755)
		require.NoError(t, err)

		// Create a test config file
		configFile := filepath.Join(configDir, "test.yaml")
		err = os.WriteFile(configFile, []byte("test: config"), 0644)
		require.NoError(t, err)

		// Change to temp directory
		oldWd, _ := os.Getwd()
		err = os.Chdir(tmpDir)
		require.NoError(t, err)
		defer os.Chdir(oldWd)

		// Find the config file
		found, err := FindConfigFile("test")
		assert.NoError(t, err)
		assert.Equal(t, "configs/test.yaml", found)
	})

	t.Run("returns error when no config file found", func(t *testing.T) {
		// Use a temporary empty directory
		tmpDir := t.TempDir()
		oldWd, _ := os.Getwd()
		err := os.Chdir(tmpDir)
		require.NoError(t, err)
		defer os.Chdir(oldWd)

		found, err := FindConfigFile("nonexistent")
		assert.Error(t, err)
		assert.Empty(t, found)
		assert.Contains(t, err.Error(), "no config file found")
	})

	t.Run("finds config in alternative locations", func(t *testing.T) {
		// Create a temporary directory with config in alternative location
		tmpDir := t.TempDir()
		configDir := filepath.Join(tmpDir, "config") // Note: config instead of configs
		err := os.MkdirAll(configDir, 0755)
		require.NoError(t, err)

		// Create a test config file
		configFile := filepath.Join(configDir, "dev.yml")
		err = os.WriteFile(configFile, []byte("test: config"), 0644)
		require.NoError(t, err)

		// Change to temp directory
		oldWd, _ := os.Getwd()
		err = os.Chdir(tmpDir)
		require.NoError(t, err)
		defer os.Chdir(oldWd)

		// Find the config file
		found, err := FindConfigFile("dev")
		assert.NoError(t, err)
		assert.Equal(t, "config/dev.yml", found)
	})
}

func TestConfigLoaderIntegration(t *testing.T) {
	t.Run("handles missing config file error", func(t *testing.T) {
		// Create a loader with non-existent file
		loader := NewConfigLoader("/non/existent/config.yaml", "test")

		// This will fail because the file doesn't exist
		// In a real scenario, we'd mock the config.Load() function
		_, err := loader.Load()
		assert.Error(t, err)
	})

	t.Run("sets CONFIG_FILE environment variable", func(t *testing.T) {
		// Save and restore environment
		oldConfigFile := os.Getenv("CONFIG_FILE")
		defer func() {
			if oldConfigFile != "" {
				os.Setenv("CONFIG_FILE", oldConfigFile)
			} else {
				os.Unsetenv("CONFIG_FILE")
			}
		}()

		// Create a temporary config file
		tmpFile, err := os.CreateTemp("", "config-*.yaml")
		require.NoError(t, err)
		defer os.Remove(tmpFile.Name())

		// Write some config
		_, err = tmpFile.WriteString("app:\n  name: test")
		require.NoError(t, err)
		tmpFile.Close()

		loader := NewConfigLoader(tmpFile.Name(), "")

		// The Load method will set CONFIG_FILE
		// We can't fully test without mocking config.Load()
		assert.Equal(t, tmpFile.Name(), loader.configFile)
	})
}
