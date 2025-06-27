package image

import (
	"fmt"
	"log/slog"

	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/image/adapters"
	"ssulmeta-go/internal/image/core"
	"ssulmeta-go/internal/image/ports"
)

// Container holds all image-related dependencies
type Container struct {
	Service       *core.Service
	Generator     ports.Generator
	PromptBuilder ports.PromptBuilder
	Processor     ports.ImageProcessor
}

// NewContainer creates a new container with all dependencies
func NewContainer(cfg *config.Config, logger *slog.Logger) (*Container, error) {
	var generator ports.Generator
	var processor ports.ImageProcessor

	// Create prompt builder (always use real implementation)
	promptBuilder := core.NewPromptBuilder()

	// Create generator based on configuration
	switch cfg.API.Image.Provider {
	case "mock":
		generator = adapters.NewMockGenerator(cfg.Storage.BasePath)
		processor = adapters.NewMockProcessor()
	case "stable-diffusion":
		if cfg.API.Image.APIKey == "" {
			return nil, fmt.Errorf("stable-diffusion API key not configured")
		}
		generator = adapters.NewStableDiffusionClient(
			cfg.API.Image.APIKey,
			cfg.API.Image.BaseURL,
			cfg.Storage.BasePath,
			logger,
		)
		processor = adapters.NewImageProcessor(logger)
	default:
		return nil, fmt.Errorf("unknown image provider: %s", cfg.API.Image.Provider)
	}

	// Create service
	service := core.NewService(generator, promptBuilder, processor, logger)

	return &Container{
		Service:       service,
		Generator:     generator,
		PromptBuilder: promptBuilder,
		Processor:     processor,
	}, nil
}
