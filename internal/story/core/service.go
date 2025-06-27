package core

import (
	"context"
	"fmt"
	"ssulmeta-go/internal/story/ports"
	"ssulmeta-go/pkg/models"
)

// Service provides story generation functionality
type Service struct {
	generator ports.Generator
	validator *Validator
}

// Ensure Service implements the Service interface
var _ ports.Service = (*Service)(nil)

// NewService creates a new story service with dependency injection
func NewService(generator ports.Generator, validator *Validator) *Service {
	return &Service{
		generator: generator,
		validator: validator,
	}
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
	scenePointers := make([]*models.Scene, len(story.Scenes))
	for i := range story.Scenes {
		scenePointers[i] = &story.Scenes[i]
	}
	if err := s.validator.ValidateScenes(scenePointers); err != nil {
		return nil, fmt.Errorf("scene validation failed: %w", err)
	}

	return story, nil
}
