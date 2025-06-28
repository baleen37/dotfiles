package cli

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"ssulmeta-go/internal/config"
)

// ConfigLoader handles configuration loading for CLI
type ConfigLoader struct {
	configFile  string
	environment string
}

// NewConfigLoader creates a new config loader
func NewConfigLoader(configFile, environment string) *ConfigLoader {
	return &ConfigLoader{
		configFile:  configFile,
		environment: environment,
	}
}

// Load loads the configuration
func (l *ConfigLoader) Load() (*config.Config, error) {
	// Set environment if specified
	if l.environment != "" {
		os.Setenv("APP_ENV", l.environment)
	}

	// If explicit config file is provided, use it
	if l.configFile != "" {
		configPath := l.configFile
		if strings.HasPrefix(configPath, "~/") {
			home, err := os.UserHomeDir()
			if err != nil {
				return nil, fmt.Errorf("failed to get home directory: %w", err)
			}
			configPath = filepath.Join(home, configPath[2:])
		}
		os.Setenv("CONFIG_FILE", configPath)
		return config.Load()
	}

	// Try to find config file based on environment
	env := l.environment
	if env == "" {
		env = os.Getenv("APP_ENV")
		if env == "" {
			env = "local"
		}
	}

	configPath, err := FindConfigFile(env)
	if err != nil {
		return nil, err
	}

	os.Setenv("CONFIG_FILE", configPath)
	return config.Load()
}

// GetConfigPaths returns possible config file paths for an environment
func GetConfigPaths(environment string) []string {
	if environment == "" {
		environment = os.Getenv("APP_ENV")
		if environment == "" {
			environment = "local"
		}
	}

	var paths []string

	// Project-relative paths
	for _, dir := range []string{"configs", "config"} {
		for _, ext := range []string{"yaml", "yml"} {
			paths = append(paths, filepath.Join(dir, fmt.Sprintf("%s.%s", environment, ext)))
		}
	}

	// Home directory configs
	home, err := os.UserHomeDir()
	if err == nil && home != "" {
		// ~/.ssulmeta/config.yaml
		paths = append(paths, filepath.Join(home, ".ssulmeta", "config.yaml"))
		// ~/.ssulmeta.{env}.yaml
		paths = append(paths, filepath.Join(home, fmt.Sprintf(".ssulmeta.%s.yaml", environment)))
	}

	return paths
}

// FindConfigFile searches for a config file in standard locations
func FindConfigFile(environment string) (string, error) {
	paths := GetConfigPaths(environment)

	for _, path := range paths {
		if _, err := os.Stat(path); err == nil {
			return path, nil
		}
	}

	return "", errors.New("no config file found for environment: " + environment)
}
