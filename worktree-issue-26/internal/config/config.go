package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

type Config struct {
	App      AppConfig      `yaml:"app"`
	Database DatabaseConfig `yaml:"database"`
	API      APIConfig      `yaml:"api"`
	YouTube  YouTubeConfig  `yaml:"youtube"`
	Storage  StorageConfig  `yaml:"storage"`
	Logging  LoggingConfig  `yaml:"logging"`
}

type AppConfig struct {
	Name  string `yaml:"name"`
	Env   string `yaml:"env"`
	Debug bool   `yaml:"debug"`
}

type DatabaseConfig struct {
	Host               string `yaml:"host"`
	Port               int    `yaml:"port"`
	User               string `yaml:"user"`
	Password           string `yaml:"password"`
	DBName             string `yaml:"dbname"`
	SSLMode            string `yaml:"sslmode"`
	MaxConnections     int    `yaml:"max_connections"`
	MaxIdleConnections int    `yaml:"max_idle_connections"`
}

type APIConfig struct {
	UseMock bool           `yaml:"use_mock"`
	OpenAI  OpenAIConfig   `yaml:"openai"`
	Image   ImageAPIConfig `yaml:"image"`
	TTS     TTSConfig      `yaml:"tts"`
}

type OpenAIConfig struct {
	APIKey      string  `yaml:"api_key"`
	Model       string  `yaml:"model"`
	MaxTokens   int     `yaml:"max_tokens"`
	Temperature float64 `yaml:"temperature"`
	RateLimit   int     `yaml:"rate_limit"`
}

type ImageAPIConfig struct {
	Provider  string `yaml:"provider"`
	APIKey    string `yaml:"api_key"`
	BaseURL   string `yaml:"base_url"`
	RateLimit int    `yaml:"rate_limit"`
}

type TTSConfig struct {
	Provider        string `yaml:"provider"`
	APIKey          string `yaml:"api_key"`
	CredentialsFile string `yaml:"credentials_file"`
	LanguageCode    string `yaml:"language_code"`
	VoiceName       string `yaml:"voice_name"`
	RateLimit       int    `yaml:"rate_limit"`
}

type YouTubeConfig struct {
	ClientID      string `yaml:"client_id"`
	ClientSecret  string `yaml:"client_secret"`
	RedirectURL   string `yaml:"redirect_url"`
	UploadTimeout int    `yaml:"upload_timeout"`
}

type StorageConfig struct {
	BasePath   string `yaml:"base_path"`
	TempPath   string `yaml:"temp_path"`
	MaxTempAge int    `yaml:"max_temp_age"`
}

type LoggingConfig struct {
	Level      string `yaml:"level"`
	Format     string `yaml:"format"`
	Output     string `yaml:"output"`
	FilePath   string `yaml:"file_path"`
	MaxSize    int    `yaml:"max_size"`
	MaxBackups int    `yaml:"max_backups"`
	MaxAge     int    `yaml:"max_age"`
}

// Load loads configuration from yaml file based on APP_ENV
func Load() (*Config, error) {
	env := os.Getenv("APP_ENV")
	if env == "" {
		env = "local"
	}

	configPath := filepath.Join("configs", fmt.Sprintf("%s.yaml", env))

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file %s: %w", configPath, err)
	}

	// Expand environment variables
	expandedData := os.ExpandEnv(string(data))

	var config Config
	if err := yaml.Unmarshal([]byte(expandedData), &config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Validate configuration
	if err := config.Validate(); err != nil {
		return nil, fmt.Errorf("invalid configuration: %w", err)
	}

	return &config, nil
}

// Validate validates the configuration
func (c *Config) Validate() error {
	if c.App.Name == "" {
		return fmt.Errorf("app name is required")
	}

	if c.Database.Host == "" || c.Database.Port == 0 {
		return fmt.Errorf("database host and port are required")
	}

	// Check for unexpanded environment variables
	if strings.Contains(c.API.OpenAI.APIKey, "${") && !c.API.UseMock {
		return fmt.Errorf("OpenAI API key is not set")
	}

	return nil
}

// GetDatabaseDSN returns PostgreSQL connection string
func (c *Config) GetDatabaseDSN() string {
	return fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		c.Database.Host,
		c.Database.Port,
		c.Database.User,
		c.Database.Password,
		c.Database.DBName,
		c.Database.SSLMode,
	)
}
