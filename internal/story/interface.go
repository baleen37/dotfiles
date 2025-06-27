package story

import (
	"context"
	"ssulmeta-go/pkg/models"
)

// Generator defines the interface for story generation
type Generator interface {
	// GenerateStory generates a story based on the channel's prompt template
	GenerateStory(ctx context.Context, channel *models.Channel) (*models.Story, error)

	// DivideIntoScenes splits a story into scenes
	DivideIntoScenes(ctx context.Context, story *models.Story) error
}
