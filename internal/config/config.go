package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

type Config struct {
	App        AppConfig        `yaml:"app"`
	Database   DatabaseConfig   `yaml:"database"`
	Server     ServerConfig     `yaml:"server"`
	API        APIConfig        `yaml:"api"`
	YouTube    YouTubeConfig    `yaml:"youtube"`
	Storage    StorageConfig    `yaml:"storage"`
	Logging    LoggingConfig    `yaml:"logging"`
	Story      StoryConfig      `yaml:"story"`
	HTTPClient HTTPClientConfig `yaml:"http_client"`
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
	APIKey       string  `yaml:"api_key"`
	BaseURL      string  `yaml:"base_url"`
	Model        string  `yaml:"model"`
	MaxTokens    int     `yaml:"max_tokens"`
	Temperature  float64 `yaml:"temperature"`
	RateLimit    int     `yaml:"rate_limit"`
	SystemPrompt string  `yaml:"system_prompt"`
}

type ImageAPIConfig struct {
	Provider       string        `yaml:"provider"`
	APIKey         string        `yaml:"api_key"`
	BaseURL        string        `yaml:"base_url"`
	Width          int           `yaml:"width"`
	Height         int           `yaml:"height"`
	Steps          int           `yaml:"steps"`
	GuidanceScale  float64       `yaml:"guidance_scale"`
	Sampler        string        `yaml:"sampler"`
	NegativePrompt string        `yaml:"negative_prompt"`
	JPEGQuality    int           `yaml:"jpeg_quality"`
	MaxFileSize    int64         `yaml:"max_file_size"`
	RateLimit      int           `yaml:"rate_limit"`
	RateLimitDelay time.Duration `yaml:"rate_limit_delay"`
}

type TTSConfig struct {
	Provider        string  `yaml:"provider"`
	APIKey          string  `yaml:"api_key"`
	BaseURL         string  `yaml:"base_url"`
	CredentialsFile string  `yaml:"credentials_file"`
	LanguageCode    string  `yaml:"language_code"`
	VoiceName       string  `yaml:"voice_name"`
	SpeakingRate    float64 `yaml:"speaking_rate"`
	Pitch           float64 `yaml:"pitch"`
	VolumeGain      float64 `yaml:"volume_gain"`
	SampleRate      int     `yaml:"sample_rate"`
	AudioEncoding   string  `yaml:"audio_encoding"`
	RateLimit       int     `yaml:"rate_limit"`
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

type ServerConfig struct {
	Port         string        `yaml:"port"`
	RedisAddr    string        `yaml:"redis_addr"`
	RedisDB      int           `yaml:"redis_db"`
	ReadTimeout  time.Duration `yaml:"read_timeout"`
	WriteTimeout time.Duration `yaml:"write_timeout"`
}

type StoryConfig struct {
	ReadingRate   float64 `yaml:"reading_rate"`
	MinDuration   float64 `yaml:"min_duration"`
	MaxDuration   float64 `yaml:"max_duration"`
	DefaultPrompt string  `yaml:"default_prompt"`
	DefaultTitle  string  `yaml:"default_title"`
}

type HTTPClientConfig struct {
	OpenAITimeout time.Duration `yaml:"openai_timeout"`
	TTSTimeout    time.Duration `yaml:"tts_timeout"`
	ImageTimeout  time.Duration `yaml:"image_timeout"`
	RetryCount    int           `yaml:"retry_count"`
	RetryInterval time.Duration `yaml:"retry_interval"`
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

	// Server validation
	if c.Server.Port == "" {
		return fmt.Errorf("server port is required")
	}
	if c.Server.RedisAddr == "" {
		return fmt.Errorf("redis address is required")
	}

	// HTTP client timeout validation
	if c.HTTPClient.OpenAITimeout <= 0 {
		return fmt.Errorf("openAI timeout must be positive")
	}
	if c.HTTPClient.TTSTimeout <= 0 {
		return fmt.Errorf("tTS timeout must be positive")
	}
	if c.HTTPClient.ImageTimeout <= 0 {
		return fmt.Errorf("image timeout must be positive")
	}

	// Story configuration validation
	if c.Story.ReadingRate <= 0 {
		return fmt.Errorf("reading rate must be positive")
	}
	if c.Story.MinDuration <= 0 || c.Story.MaxDuration <= 0 {
		return fmt.Errorf("scene duration bounds must be positive")
	}
	if c.Story.MinDuration >= c.Story.MaxDuration {
		return fmt.Errorf("min duration must be less than max duration")
	}

	// API configuration validation
	if c.API.OpenAI.BaseURL == "" {
		return fmt.Errorf("openAI base URL is required")
	}
	if c.API.Image.Width <= 0 || c.API.Image.Height <= 0 {
		return fmt.Errorf("image dimensions must be positive")
	}

	// Check for unexpanded environment variables
	if strings.Contains(c.API.OpenAI.APIKey, "${") && !c.API.UseMock {
		return fmt.Errorf("openAI API key is not set")
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
