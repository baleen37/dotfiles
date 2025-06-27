package ports

import (
	"context"
	"ssulmeta-go/pkg/models"
)

// Service defines the interface for story generation services
type Service interface {
	// GenerateStory generates and validates a complete story
	GenerateStory(ctx context.Context, channel *models.Channel) (*models.Story, error)
}

// Generator defines the interface for story generation
type Generator interface {
	// GenerateStory generates a story based on the channel configuration
	GenerateStory(ctx context.Context, channel *models.Channel) (*models.Story, error)

	// DivideIntoScenes divides the story content into scenes
	DivideIntoScenes(ctx context.Context, story *models.Story) error
}

// Validator defines the interface for story validation
type Validator interface {
	// ValidateStory validates the generated story
	ValidateStory(story *models.Story) error

	// ValidateScenes validates the story scenes
	ValidateScenes(scenes []*models.Scene) error
}
