package story

import (
	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/story/adapters"
	"ssulmeta-go/internal/story/core"
	"ssulmeta-go/internal/story/ports"
)

// NewServiceWithConfig creates a new story service with configuration (backward compatibility)
func NewServiceWithConfig(cfg *config.APIConfig) (ports.Service, error) {
	var generator ports.Generator

	if cfg.UseMock {
		generator = adapters.NewMockGenerator()
	} else {
		generator = adapters.NewOpenAIGenerator(&cfg.OpenAI)
	}

	validator := core.NewValidator()
	service := core.NewService(generator, validator)

	return service, nil
}
