package story

import (
	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/story/adapters"
	"ssulmeta-go/internal/story/core"
	"ssulmeta-go/internal/story/ports"
)

// NewService creates a new story service with appropriate generator
func NewService(cfg *config.APIConfig) (ports.Service, error) {
	var generator ports.Generator

	if cfg.UseMock {
		generator = adapters.NewMockGenerator()
	} else {
		generator = adapters.NewOpenAIGenerator(&cfg.OpenAI)
	}

	return core.NewService(cfg, generator)
}
