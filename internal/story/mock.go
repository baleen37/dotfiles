package story

import (
	"context"
	"fmt"
	"ssulmeta-go/pkg/models"
	"strings"
)

// MockGenerator is a mock implementation of Generator
type MockGenerator struct{}

// NewMockGenerator creates a new mock generator
func NewMockGenerator() *MockGenerator {
	return &MockGenerator{}
}

// GenerateStory generates a mock story
func (m *MockGenerator) GenerateStory(ctx context.Context, channel *models.Channel) (*models.Story, error) {
	// Sample story for testing (270-300 characters)
	story := &models.Story{
		Title:   "테스트 이야기: 작은 별의 모험",
		Content: "어느 날 밤, 하늘에서 가장 작은 별이 지구로 여행을 떠났습니다. 별은 처음으로 지구의 아름다운 풍경을 보고 감탄했습니다. 깊은 숲 속에서 반딧불이를 만났고, 함께 아름다운 빛의 춤을 추었습니다. 반딧불이는 별에게 지구의 밤이 얼마나 아름다운지 보여주었고, 별은 반딧불이에게 우주의 신비를 들려주었습니다. 새벽이 되자 별은 다시 하늘로 돌아가야 했지만, 반딧불이와의 우정은 영원히 그들의 마음속에서 빛났습니다. 그 후로 매일 밤, 별과 반딧불이는 서로를 그리워하며 빛을 내고 있습니다.",
	}

	return story, nil
}

// DivideIntoScenes divides the story into scenes
func (m *MockGenerator) DivideIntoScenes(ctx context.Context, story *models.Story) error {
	// Simple division based on sentences
	sentences := strings.Split(story.Content, ". ")

	scenes := make([]models.Scene, 0)
	for i, sentence := range sentences {
		if strings.TrimSpace(sentence) == "" {
			continue
		}

		scene := models.Scene{
			Number:      i + 1,
			Description: sentence + ".",
			ImagePrompt: fmt.Sprintf("Fairy tale illustration: %s, soft colors, magical atmosphere", sentence),
			Duration:    10.0, // 10 seconds per scene
		}
		scenes = append(scenes, scene)
	}

	story.Scenes = scenes
	return nil
}
