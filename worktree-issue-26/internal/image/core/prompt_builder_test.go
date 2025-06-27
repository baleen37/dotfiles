package core

import (
	"strings"
	"testing"

	"ssulmeta-go/pkg/models"
)

func TestPromptBuilder_BuildPrompt(t *testing.T) {
	pb := NewPromptBuilder()

	tests := []struct {
		name     string
		scene    models.Scene
		style    string
		wantPart []string // Parts that should be in the prompt
	}{
		{
			name: "basic scene with style",
			scene: models.Scene{
				Number:      1,
				Description: "소녀가 숲 속을 걷고 있다",
			},
			style: "children's book illustration, bright colors",
			wantPart: []string{
				"소녀가 숲 속을 걷고 있다",
				"children's book illustration",
				"vertical orientation",
				"9:16 aspect ratio",
			},
		},
		{
			name: "scene without style",
			scene: models.Scene{
				Number:      2,
				Description: "어두운 방에서 그림자가 움직인다",
			},
			style: "",
			wantPart: []string{
				"어두운 방에서 그림자가 움직인다",
				"vertical orientation",
				"high quality",
			},
		},
		{
			name: "empty description",
			scene: models.Scene{
				Number:      3,
				Description: "",
			},
			style: "romantic atmosphere",
			wantPart: []string{
				"romantic atmosphere",
				"centered composition",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := pb.BuildPrompt(tt.scene, tt.style)

			// Check that all expected parts are in the prompt
			for _, part := range tt.wantPart {
				if !strings.Contains(got, part) {
					t.Errorf("BuildPrompt() missing expected part %q, got = %v", part, got)
				}
			}

			// Check that prompt is properly cleaned
			if strings.Contains(got, ",,") {
				t.Errorf("BuildPrompt() contains double commas: %v", got)
			}
			if strings.HasPrefix(got, ",") || strings.HasSuffix(got, ",") {
				t.Errorf("BuildPrompt() has leading/trailing comma: %v", got)
			}
		})
	}
}

func TestPromptBuilder_BuildPromptsForStory(t *testing.T) {
	pb := NewPromptBuilder()

	scenes := []models.Scene{
		{
			Number:      1,
			Description: "어린 공주가 성의 정원을 걷고 있다",
		},
		{
			Number:      2,
			Description: "공주가 정원에서 신비한 꽃을 발견한다",
		},
		{
			Number:      3,
			Description: "꽃이 빛나며 마법의 요정이 나타난다",
		},
	}

	style := "fairy tale illustration, magical atmosphere"

	prompts := pb.BuildPromptsForStory(scenes, style)

	if len(prompts) != len(scenes) {
		t.Fatalf("BuildPromptsForStory() returned %d prompts, want %d", len(prompts), len(scenes))
	}

	// Check that all prompts contain style
	for i, prompt := range prompts {
		if !strings.Contains(prompt, style) {
			t.Errorf("Prompt %d missing style: %v", i, prompt)
		}

		// Check scene progression
		expectedProgression := strings.Contains(prompt, "scene")
		if !expectedProgression {
			t.Errorf("Prompt %d missing scene progression: %v", i, prompt)
		}
	}

	// Check character consistency (should detect "공주")
	hasCharacterConsistency := false
	for _, prompt := range prompts {
		if strings.Contains(prompt, "공주") && strings.Contains(prompt, "characters:") {
			hasCharacterConsistency = true
			break
		}
	}
	if !hasCharacterConsistency {
		t.Error("Prompts missing character consistency")
	}

	// Check setting consistency (should detect "정원")
	hasSettingConsistency := false
	for _, prompt := range prompts {
		if strings.Contains(prompt, "정원") && strings.Contains(prompt, "setting:") {
			hasSettingConsistency = true
			break
		}
	}
	if !hasSettingConsistency {
		t.Error("Prompts missing setting consistency")
	}
}

func TestExtractCharacterDescriptions(t *testing.T) {
	tests := []struct {
		name   string
		scenes []models.Scene
		want   []string // Keywords that should be found
	}{
		{
			name: "fairy tale characters",
			scenes: []models.Scene{
				{Description: "어린 공주가 성을 나선다"},
				{Description: "공주는 마녀를 만난다"},
				{Description: "요정이 공주를 도와준다"},
			},
			want: []string{"공주", "마녀", "요정"},
		},
		{
			name: "modern story characters",
			scenes: []models.Scene{
				{Description: "소녀가 학교에 간다"},
				{Description: "소녀는 친구를 만난다"},
				{Description: "할머니가 소녀를 부른다"},
			},
			want: []string{"소녀", "친구", "할머니"},
		},
		{
			name: "no characters",
			scenes: []models.Scene{
				{Description: "비가 내린다"},
				{Description: "바람이 분다"},
			},
			want: []string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := extractCharacterDescriptions(tt.scenes)

			if len(tt.want) == 0 && got != "" {
				t.Errorf("extractCharacterDescriptions() = %v, want empty", got)
				return
			}

			for _, keyword := range tt.want {
				if !strings.Contains(got, keyword) {
					t.Errorf("extractCharacterDescriptions() missing %q, got = %v", keyword, got)
				}
			}
		})
	}
}

func TestExtractSettingDescription(t *testing.T) {
	tests := []struct {
		name   string
		scenes []models.Scene
		want   []string // Keywords that should be found
	}{
		{
			name: "forest story",
			scenes: []models.Scene{
				{Description: "깊은 숲 속에서"},
				{Description: "숲의 작은 집"},
				{Description: "숲을 벗어나 마을로"},
			},
			want: []string{"숲"},
		},
		{
			name: "multiple settings",
			scenes: []models.Scene{
				{Description: "성의 정원에서"},
				{Description: "정원을 지나 숲으로"},
				{Description: "숲에서 다시 성으로"},
			},
			want: []string{"성", "정원", "숲"},
		},
		{
			name: "no clear setting",
			scenes: []models.Scene{
				{Description: "그녀는 생각했다"},
				{Description: "시간이 흘렀다"},
			},
			want: []string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := extractSettingDescription(tt.scenes)

			if len(tt.want) == 0 && got != "" {
				t.Errorf("extractSettingDescription() = %v, want empty", got)
				return
			}

			for _, keyword := range tt.want {
				if !strings.Contains(got, keyword) {
					t.Errorf("extractSettingDescription() missing %q, got = %v", keyword, got)
				}
			}
		})
	}
}
