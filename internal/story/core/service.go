package core

import (
	"context"
	"ssulmeta-go/internal/story/ports"
	"ssulmeta-go/pkg/errors"
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
		// Check if it's already an AppError
		if appErr, ok := errors.GetAppError(err); ok {
			return nil, appErr
		}
		return nil, errors.Wrap(err, errors.ErrorTypeInternal, errors.CodeStoryGenerationFailed, "failed to generate story")
	}

	// Validate story
	if err := s.validator.ValidateStory(story); err != nil {
		// Validator already returns AppError
		return nil, err
	}

	// Divide into scenes
	if err := s.generator.DivideIntoScenes(ctx, story); err != nil {
		// Check if it's already an AppError
		if appErr, ok := errors.GetAppError(err); ok {
			return nil, appErr
		}
		return nil, errors.Wrap(err, errors.ErrorTypeInternal, errors.CodeStoryGenerationFailed, "failed to divide into scenes")
	}

	// Validate scenes
	scenePointers := make([]*models.Scene, len(story.Scenes))
	for i := range story.Scenes {
		scenePointers[i] = &story.Scenes[i]
	}
	if err := s.validator.ValidateScenes(scenePointers); err != nil {
		// Validator already returns AppError
		return nil, err
	}

	return story, nil
}
