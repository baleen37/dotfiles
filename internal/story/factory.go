package story

import (
	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/story/adapters"
	"ssulmeta-go/internal/story/core"
	"ssulmeta-go/internal/story/ports"
	"time"
)

// NewServiceWithConfig creates a new story service with configuration (backward compatibility)
func NewServiceWithConfig(cfg *config.APIConfig, storyCfg *config.StoryConfig, httpTimeout time.Duration) (ports.Service, error) {
	var generator ports.Generator

	if cfg.UseMock {
		generator = adapters.NewMockGenerator()
	} else {
		generator = adapters.NewOpenAIGenerator(&cfg.OpenAI, storyCfg, httpTimeout)
	}

	validator := core.NewValidator()
	service := core.NewService(generator, validator)

	return service, nil
}
