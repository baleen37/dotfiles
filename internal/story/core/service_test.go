package core

import (
	"context"
	"ssulmeta-go/internal/story/adapters"
	"ssulmeta-go/pkg/models"
	"testing"
	"time"
)

func TestService_GenerateStory(t *testing.T) {
	// Create mock service using dependency injection
	generator := adapters.NewMockGenerator()
	validator := NewValidator()
	service := NewService(generator, validator)

	// Create test channel
	channel := models.NewChannel("test_channel")
	channel.PromptTemplate = "테스트용 프롬프트"

	// Generate story
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	story, err := service.GenerateStory(ctx, channel)
	if err != nil {
		t.Fatalf("Failed to generate story: %v", err)
	}

	// Verify story
	if story.Title == "" {
		t.Error("Story title is empty")
	}

	if story.Content == "" {
		t.Error("Story content is empty")
	}

	if len(story.Scenes) == 0 {
		t.Error("No scenes generated")
	}

	t.Logf("Generated story: %s", story.Title)
	t.Logf("Content length: %d characters", len([]rune(story.Content)))
	t.Logf("Number of scenes: %d", len(story.Scenes))
}

func TestValidator(t *testing.T) {
	validator := NewValidator()

	tests := []struct {
		name    string
		story   *models.Story
		wantErr bool
	}{
		{
			name: "valid story",
			story: &models.Story{
				Title:   "테스트 이야기",
				Content: "옛날 옛적에 아름다운 마을이 있었습니다. 그 마을에는 착한 사람들이 살고 있었습니다. 어느 날, 마을에 신비한 나그네가 찾아왔습니다. 나그네는 마을 사람들에게 특별한 선물을 주었습니다. 그것은 바로 희망의 씨앗이었습니다. 마을 사람들은 정성껏 씨앗을 심고 가꾸었습니다. 시간이 흘러 씨앗은 아름다운 꽃으로 피어났습니다. 그 꽃은 마을 전체를 환하게 밝혀주었습니다. 마을 사람들은 더욱 행복해졌습니다. 그들은 나그네에게 감사하며 살았습니다. 이 이야기는 희망과 감사의 중요성을 전합니다.",
			},
			wantErr: false,
		},
		{
			name: "too short",
			story: &models.Story{
				Title:   "짧은 이야기",
				Content: "너무 짧은 내용.",
			},
			wantErr: true,
		},
		{
			name: "empty title",
			story: &models.Story{
				Title:   "",
				Content: "제목이 없는 이야기입니다. 충분히 긴 내용을 포함하고 있습니다. 세 번째 문장도 추가합니다.",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := validator.ValidateStory(tt.story)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateStory() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
