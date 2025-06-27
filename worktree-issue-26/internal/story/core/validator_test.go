package core

import (
	"ssulmeta-go/pkg/models"
	"strings"
	"testing"
)

func TestValidator_ValidateStory(t *testing.T) {
	v := NewValidator()

	tests := []struct {
		name    string
		story   *models.Story
		wantErr bool
	}{
		{
			name: "valid story",
			story: &models.Story{
				Title:   "유효한 제목",
				Content: generateContent(280),
			},
			wantErr: false,
		},
		{
			name:    "nil story",
			story:   nil,
			wantErr: true,
		},
		{
			name: "empty title",
			story: &models.Story{
				Title:   "",
				Content: generateContent(280),
			},
			wantErr: true,
		},
		{
			name: "content too short",
			story: &models.Story{
				Title:   "유효한 제목",
				Content: "너무 짧은 내용",
			},
			wantErr: true,
		},
		{
			name: "content too long",
			story: &models.Story{
				Title:   "유효한 제목",
				Content: strings.Repeat("가", 301),
			},
			wantErr: true,
		},
		{
			name: "valid story with exact minimum length",
			story: &models.Story{
				Title:   "정확히 270자 이야기",
				Content: generateContent(270),
			},
			wantErr: false,
		},
		{
			name: "valid story with exact maximum length",
			story: &models.Story{
				Title:   "정확히 300자 이야기",
				Content: generateContent(300),
			},
			wantErr: false,
		},
		{
			name: "content just below minimum (269 chars)",
			story: &models.Story{
				Title:   "269자 이야기",
				Content: generateContent(269),
			},
			wantErr: true,
		},
		{
			name: "content just above maximum (301 chars)",
			story: &models.Story{
				Title:   "301자 이야기",
				Content: generateContent(301),
			},
			wantErr: true,
		},
		{
			name: "title with only spaces",
			story: &models.Story{
				Title:   "   ",
				Content: generateContent(280),
			},
			wantErr: false, // Validator doesn't check for whitespace-only titles
		},
		{
			name: "content without enough sentences",
			story: &models.Story{
				Title:   "문장이 부족한 이야기",
				Content: strings.Repeat("가", 280) + " 한 문장만",
			},
			wantErr: true,
		},
		{
			name: "content with exactly 3 sentences",
			story: &models.Story{
				Title:   "3문장 이야기",
				Content: "첫 번째 문장입니다. 두 번째 문장은 " + strings.Repeat("가", 235) + "입니다. 세 번째 문장입니다.",
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := v.ValidateStory(tt.story)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateStory() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidator_ValidateScenes(t *testing.T) {
	v := NewValidator()

	tests := []struct {
		name    string
		scenes  []*models.Scene
		wantErr bool
	}{
		{
			name: "valid scenes",
			scenes: []*models.Scene{
				{Number: 1, Description: "첫 번째 장면", ImagePrompt: "prompt1", Duration: 3.0},
				{Number: 2, Description: "두 번째 장면", ImagePrompt: "prompt2", Duration: 3.0},
				{Number: 3, Description: "세 번째 장면", ImagePrompt: "prompt3", Duration: 3.0},
				{Number: 4, Description: "네 번째 장면", ImagePrompt: "prompt4", Duration: 3.0},
				{Number: 5, Description: "다섯 번째 장면", ImagePrompt: "prompt5", Duration: 3.0},
				{Number: 6, Description: "여섯 번째 장면", ImagePrompt: "prompt6", Duration: 3.0},
			},
			wantErr: false,
		},
		{
			name:    "nil scenes",
			scenes:  nil,
			wantErr: true,
		},
		{
			name:    "empty scenes",
			scenes:  []*models.Scene{},
			wantErr: true,
		},
		{
			name: "too few scenes (5)",
			scenes: []*models.Scene{
				{Number: 1, Description: "첫 번째 장면", ImagePrompt: "prompt1", Duration: 3.0},
				{Number: 2, Description: "두 번째 장면", ImagePrompt: "prompt2", Duration: 3.0},
				{Number: 3, Description: "세 번째 장면", ImagePrompt: "prompt3", Duration: 3.0},
				{Number: 4, Description: "네 번째 장면", ImagePrompt: "prompt4", Duration: 3.0},
				{Number: 5, Description: "다섯 번째 장면", ImagePrompt: "prompt5", Duration: 3.0},
			},
			wantErr: true,
		},
		{
			name: "too many scenes (11)",
			scenes: []*models.Scene{
				{Number: 1, Description: "장면 1", ImagePrompt: "prompt1", Duration: 3.0},
				{Number: 2, Description: "장면 2", ImagePrompt: "prompt2", Duration: 3.0},
				{Number: 3, Description: "장면 3", ImagePrompt: "prompt3", Duration: 3.0},
				{Number: 4, Description: "장면 4", ImagePrompt: "prompt4", Duration: 3.0},
				{Number: 5, Description: "장면 5", ImagePrompt: "prompt5", Duration: 3.0},
				{Number: 6, Description: "장면 6", ImagePrompt: "prompt6", Duration: 3.0},
				{Number: 7, Description: "장면 7", ImagePrompt: "prompt7", Duration: 3.0},
				{Number: 8, Description: "장면 8", ImagePrompt: "prompt8", Duration: 3.0},
				{Number: 9, Description: "장면 9", ImagePrompt: "prompt9", Duration: 3.0},
				{Number: 10, Description: "장면 10", ImagePrompt: "prompt10", Duration: 3.0},
				{Number: 11, Description: "장면 11", ImagePrompt: "prompt11", Duration: 3.0},
			},
			wantErr: true,
		},
		{
			name: "empty scene description",
			scenes: []*models.Scene{
				{Number: 1, Description: "첫 번째 장면", ImagePrompt: "prompt1", Duration: 3.0},
				{Number: 2, Description: "", ImagePrompt: "prompt2", Duration: 3.0},
				{Number: 3, Description: "세 번째 장면", ImagePrompt: "prompt3", Duration: 3.0},
				{Number: 4, Description: "네 번째 장면", ImagePrompt: "prompt4", Duration: 3.0},
				{Number: 5, Description: "다섯 번째 장면", ImagePrompt: "prompt5", Duration: 3.0},
				{Number: 6, Description: "여섯 번째 장면", ImagePrompt: "prompt6", Duration: 3.0},
			},
			wantErr: true,
		},
		{
			name: "empty image prompt",
			scenes: []*models.Scene{
				{Number: 1, Description: "첫 번째 장면", ImagePrompt: "prompt1", Duration: 3.0},
				{Number: 2, Description: "두 번째 장면", ImagePrompt: "", Duration: 3.0},
				{Number: 3, Description: "세 번째 장면", ImagePrompt: "prompt3", Duration: 3.0},
				{Number: 4, Description: "네 번째 장면", ImagePrompt: "prompt4", Duration: 3.0},
				{Number: 5, Description: "다섯 번째 장면", ImagePrompt: "prompt5", Duration: 3.0},
				{Number: 6, Description: "여섯 번째 장면", ImagePrompt: "prompt6", Duration: 3.0},
			},
			wantErr: true,
		},
		{
			name: "zero duration",
			scenes: []*models.Scene{
				{Number: 1, Description: "첫 번째 장면", ImagePrompt: "prompt1", Duration: 3.0},
				{Number: 2, Description: "두 번째 장면", ImagePrompt: "prompt2", Duration: 0},
				{Number: 3, Description: "세 번째 장면", ImagePrompt: "prompt3", Duration: 3.0},
				{Number: 4, Description: "네 번째 장면", ImagePrompt: "prompt4", Duration: 3.0},
				{Number: 5, Description: "다섯 번째 장면", ImagePrompt: "prompt5", Duration: 3.0},
				{Number: 6, Description: "여섯 번째 장면", ImagePrompt: "prompt6", Duration: 3.0},
			},
			wantErr: true,
		},
		{
			name: "duplicate scene numbers",
			scenes: []*models.Scene{
				{Number: 1, Description: "첫 번째 장면", ImagePrompt: "prompt1", Duration: 3.0},
				{Number: 2, Description: "두 번째 장면", ImagePrompt: "prompt2", Duration: 3.0},
				{Number: 2, Description: "중복된 장면 번호", ImagePrompt: "prompt3", Duration: 3.0},
				{Number: 4, Description: "네 번째 장면", ImagePrompt: "prompt4", Duration: 3.0},
				{Number: 5, Description: "다섯 번째 장면", ImagePrompt: "prompt5", Duration: 3.0},
				{Number: 6, Description: "여섯 번째 장면", ImagePrompt: "prompt6", Duration: 3.0},
			},
			wantErr: false, // Validator doesn't check for duplicate numbers
		},
		{
			name: "non-sequential scene numbers",
			scenes: []*models.Scene{
				{Number: 1, Description: "첫 번째 장면", ImagePrompt: "prompt1", Duration: 3.0},
				{Number: 3, Description: "세 번째 장면", ImagePrompt: "prompt3", Duration: 3.0},
				{Number: 4, Description: "네 번째 장면", ImagePrompt: "prompt4", Duration: 3.0},
				{Number: 5, Description: "다섯 번째 장면", ImagePrompt: "prompt5", Duration: 3.0},
				{Number: 6, Description: "여섯 번째 장면", ImagePrompt: "prompt6", Duration: 3.0},
				{Number: 7, Description: "일곱 번째 장면", ImagePrompt: "prompt7", Duration: 3.0},
			},
			wantErr: false, // Validator doesn't check for sequential numbering
		},
		{
			name: "valid 10 scenes",
			scenes: []*models.Scene{
				{Number: 1, Description: "장면 1", ImagePrompt: "prompt1", Duration: 3.0},
				{Number: 2, Description: "장면 2", ImagePrompt: "prompt2", Duration: 3.0},
				{Number: 3, Description: "장면 3", ImagePrompt: "prompt3", Duration: 3.0},
				{Number: 4, Description: "장면 4", ImagePrompt: "prompt4", Duration: 3.0},
				{Number: 5, Description: "장면 5", ImagePrompt: "prompt5", Duration: 3.0},
				{Number: 6, Description: "장면 6", ImagePrompt: "prompt6", Duration: 3.0},
				{Number: 7, Description: "장면 7", ImagePrompt: "prompt7", Duration: 3.0},
				{Number: 8, Description: "장면 8", ImagePrompt: "prompt8", Duration: 3.0},
				{Number: 9, Description: "장면 9", ImagePrompt: "prompt9", Duration: 3.0},
				{Number: 10, Description: "장면 10", ImagePrompt: "prompt10", Duration: 3.0},
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := v.ValidateScenes(tt.scenes)
			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateScenes() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestValidator_EdgeCases(t *testing.T) {
	v := NewValidator()

	t.Run("title exactly 50 characters", func(t *testing.T) {
		story := &models.Story{
			Title:   strings.Repeat("가", 50),
			Content: generateContent(280),
		}
		if err := v.ValidateStory(story); err != nil {
			t.Errorf("ValidateStory() should accept 50 character title, got error: %v", err)
		}
	})

	t.Run("title 51 characters", func(t *testing.T) {
		story := &models.Story{
			Title:   strings.Repeat("가", 51),
			Content: generateContent(280),
		}
		if err := v.ValidateStory(story); err == nil {
			t.Error("ValidateStory() should reject 51 character title")
		}
	})

	t.Run("scene with negative duration", func(t *testing.T) {
		scenes := []*models.Scene{
			{Number: 1, Description: "장면 1", ImagePrompt: "prompt1", Duration: -1.0},
			{Number: 2, Description: "장면 2", ImagePrompt: "prompt2", Duration: 3.0},
			{Number: 3, Description: "장면 3", ImagePrompt: "prompt3", Duration: 3.0},
			{Number: 4, Description: "장면 4", ImagePrompt: "prompt4", Duration: 3.0},
			{Number: 5, Description: "장면 5", ImagePrompt: "prompt5", Duration: 3.0},
			{Number: 6, Description: "장면 6", ImagePrompt: "prompt6", Duration: 3.0},
		}
		if err := v.ValidateScenes(scenes); err == nil {
			t.Error("ValidateScenes() should reject negative duration")
		}
	})

	t.Run("content with only whitespace", func(t *testing.T) {
		story := &models.Story{
			Title:   "Valid Title",
			Content: "   \n\t   ",
		}
		if err := v.ValidateStory(story); err == nil {
			t.Error("ValidateStory() should reject content with only whitespace")
		}
	})
}

// Helper function to generate content with exact character count
func generateContent(length int) string {
	if length <= 0 {
		return ""
	}
	// Create content with enough sentences
	prefix := "이것은 테스트 문장입니다. 두 번째 문장입니다. 세 번째 문장입니다. "
	prefixLen := len([]rune(prefix))

	if length < prefixLen {
		return string([]rune(prefix)[:length])
	}

	// Fill the rest with Korean characters
	remaining := length - prefixLen
	base := "가나다라마바사아자차카타파하"
	baseRunes := []rune(base)

	result := prefix
	for i := 0; i < remaining; i++ {
		result += string(baseRunes[i%len(baseRunes)])
	}
	return result
}
