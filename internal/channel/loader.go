package channel

import (
	"fmt"
	"os"
	"path/filepath"
	"ssulmeta-go/pkg/models"

	"gopkg.in/yaml.v3"
)

// Config represents channel configuration from YAML
type Config struct {
	Name             string   `yaml:"name"`
	YouTubeChannelID string   `yaml:"youtube_channel_id"`
	Tags             []string `yaml:"tags"`
	PromptTemplate   string   `yaml:"prompt_template"`
	SceneStyle       string   `yaml:"scene_style"`
}

// LoadChannelConfig loads channel configuration from YAML file
func LoadChannelConfig(channelName string) (*Config, error) {
	configPath := filepath.Join("configs", "channels", fmt.Sprintf("%s.yaml", channelName))

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read channel config: %w", err)
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal channel config: %w", err)
	}

	return &config, nil
}

// ToModel converts Config to models.Channel
func (c *Config) ToModel() *models.Channel {
	channel := models.NewChannel(c.Name)
	channel.YouTubeChannelID = c.YouTubeChannelID
	channel.PromptTemplate = c.PromptTemplate
	channel.Tags = c.Tags
	return channel
}

// GetSceneStyle returns the scene style for image generation
func (c *Config) GetSceneStyle() string {
	if c.SceneStyle == "" {
		return "cinematic, high quality, vertical format"
	}
	return c.SceneStyle
}
