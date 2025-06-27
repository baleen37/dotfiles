package story

import (
	"context"
	"fmt"
	"ssulmeta-go/internal/config"
	"ssulmeta-go/pkg/models"
)

// Service provides story generation functionality
type Service struct {
	generator Generator
	validator *Validator
}

// NewService creates a new story service
func NewService(cfg *config.APIConfig) (*Service, error) {
	var generator Generator

	if cfg.UseMock {
		generator = NewMockGenerator()
	} else {
		generator = NewOpenAIGenerator(&cfg.OpenAI)
	}

	return &Service{
		generator: generator,
		validator: NewValidator(),
	}, nil
}

// GenerateStory generates and validates a story
func (s *Service) GenerateStory(ctx context.Context, channel *models.Channel) (*models.Story, error) {
	// Generate story
	story, err := s.generator.GenerateStory(ctx, channel)
	if err != nil {
		return nil, fmt.Errorf("failed to generate story: %w", err)
	}

	// Validate story
	if err := s.validator.ValidateStory(story); err != nil {
		return nil, fmt.Errorf("story validation failed: %w", err)
	}

	// Divide into scenes
	if err := s.generator.DivideIntoScenes(ctx, story); err != nil {
		return nil, fmt.Errorf("failed to divide into scenes: %w", err)
	}

	// Validate scenes
	if err := s.validator.ValidateScenes(story.Scenes); err != nil {
		return nil, fmt.Errorf("scene validation failed: %w", err)
	}

	return story, nil
}
