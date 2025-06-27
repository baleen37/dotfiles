package adapters

import (
	"ssulmeta-go/pkg/models"
	"testing"
)

func TestSceneSplitter_SplitIntoScenes(t *testing.T) {
	splitter := NewSceneSplitter()

	tests := []struct {
		name           string
		story          *models.Story
		expectedScenes int
		expectError    bool
	}{
		{
			name: "basic story splitting",
			story: &models.Story{
				Title:   "테스트 스토리",
				Content: "어느 날 밤, 하늘에서 가장 작은 별이 지구로 여행을 떠났습니다. 별은 처음으로 지구의 아름다운 풍경을 보고 감탄했습니다. 깊은 숲 속에서 반딧불이를 만났고, 함께 아름다운 빛의 춤을 추었습니다. 반딧불이는 별에게 지구의 밤이 얼마나 아름다운지 보여주었습니다. 새벽이 되자 별은 다시 하늘로 돌아가야 했지만, 반딧불이와의 우정은 영원히 그들의 마음속에서 빛났습니다.",
			},
			expectedScenes: 6, // Should be between 6-10 scenes
			expectError:    false,
		},
		{
			name: "short story",
			story: &models.Story{
				Title:   "짧은 이야기",
				Content: "옛날에 한 소년이 있었습니다. 소년은 용감했습니다. 그는 모험을 떠났습니다.",
			},
			expectedScenes: 6, // Minimum scenes
			expectError:    false,
		},
		{
			name: "empty story",
			story: &models.Story{
				Title:   "빈 이야기",
				Content: "",
			},
			expectedScenes: 0,
			expectError:    true,
		},
		{
			name: "long story with many sentences",
			story: &models.Story{
				Title:   "긴 이야기",
				Content: "첫 번째 문장입니다. 두 번째 문장입니다. 세 번째 문장입니다. 네 번째 문장입니다. 다섯 번째 문장입니다. 여섯 번째 문장입니다. 일곱 번째 문장입니다. 여덟 번째 문장입니다. 아홉 번째 문장입니다. 열 번째 문장입니다. 열한 번째 문장입니다. 열두 번째 문장입니다. 열세 번째 문장입니다. 열네 번째 문장입니다. 열다섯 번째 문장입니다.",
			},
			expectedScenes: 10, // Should not exceed max scenes
			expectError:    false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := splitter.SplitIntoScenes(tt.story)

			if tt.expectError {
				if err == nil {
					t.Errorf("expected error but got nil")
				}
				return
			}

			if err != nil {
				t.Errorf("unexpected error: %v", err)
				return
			}

			if tt.expectedScenes > 0 {
				if len(result.Scenes) < splitter.minScenes {
					t.Errorf("scenes count %d is less than minimum %d", len(result.Scenes), splitter.minScenes)
				}
				if len(result.Scenes) > splitter.maxScenes {
					t.Errorf("scenes count %d exceeds maximum %d", len(result.Scenes), splitter.maxScenes)
				}
			}

			// Verify scene numbering
			for i, scene := range result.Scenes {
				if scene.Number != i+1 {
					t.Errorf("scene %d has incorrect number %d", i+1, scene.Number)
				}
			}

			// Verify no empty scenes
			for i, scene := range result.Scenes {
				if scene.Text == "" {
					t.Errorf("scene %d has empty text", i+1)
				}
			}
		})
	}
}

func TestSceneSplitter_findNaturalBreakPoints(t *testing.T) {
	splitter := NewSceneSplitter()

	tests := []struct {
		name     string
		content  string
		expected int // minimum expected break points
	}{
		{
			name:     "sentences with periods",
			content:  "첫 번째 문장입니다. 두 번째 문장입니다. 세 번째 문장입니다.",
			expected: 2, // At least 2 break points
		},
		{
			name:     "formal endings",
			content:  "안녕하세요 습니다. 좋은 날씨입니다. 감사했습니다.",
			expected: 1, // At least 1 break point
		},
		{
			name:     "conjunctions",
			content:  "날씨가 좋았습니다. 그런데 갑자기 비가 왔습니다. 하지만 우산이 있었습니다.",
			expected: 2, // Break points after conjunctions
		},
		{
			name:     "no break points",
			content:  "짧은문장",
			expected: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			breakPoints := splitter.findNaturalBreakPoints(tt.content)

			if len(breakPoints) < tt.expected {
				t.Errorf("expected at least %d break points, got %d", tt.expected, len(breakPoints))
			}

			// Verify break points are sorted
			for i := 1; i < len(breakPoints); i++ {
				if breakPoints[i] <= breakPoints[i-1] {
					t.Errorf("break points are not sorted: %v", breakPoints)
				}
			}

			// Verify break points are within content bounds
			for _, bp := range breakPoints {
				if bp < 0 || bp > len(tt.content) {
					t.Errorf("break point %d is out of bounds for content length %d", bp, len(tt.content))
				}
			}
		})
	}
}

func TestSceneSplitter_calculateTargetScenes(t *testing.T) {
	splitter := NewSceneSplitter()

	tests := []struct {
		name     string
		content  string
		expected int
	}{
		{
			name:     "very short content",
			content:  "짧음",
			expected: splitter.minScenes,
		},
		{
			name:     "medium content",
			content:  "이것은 중간 길이의 텍스트입니다. 몇 개의 문장이 있습니다. 적절한 씬 수를 만들어야 합니다.",
			expected: 7, // Should be around 7 scenes for this length
		},
		{
			name:     "very long content",
			content:  "이것은 매우 긴 텍스트입니다. " + "반복되는 문장입니다. " + "반복되는 문장입니다. " + "반복되는 문장입니다. " + "반복되는 문장입니다. " + "반복되는 문장입니다. " + "반복되는 문장입니다. " + "반복되는 문장입니다. " + "반복되는 문장입니다. " + "반복되는 문장입니다. " + "반복되는 문장입니다. " + "반복되는 문장입니다. " + "반복되는 문장입니다. " + "추가로 더 많은 내용을 넣어서 400자를 넘기기 위한 텍스트입니다. " + "더 많은 내용이 필요합니다. " + "계속해서 텍스트를 추가합니다. " + "길이를 늘리기 위해 더 많은 문장을 추가합니다. " + "이제 충분히 길어졌을 것입니다. " + "마지막 문장입니다.",
			expected: splitter.maxScenes,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := splitter.calculateTargetScenes(tt.content)

			if result < splitter.minScenes {
				t.Errorf("result %d is less than minimum %d", result, splitter.minScenes)
			}
			if result > splitter.maxScenes {
				t.Errorf("result %d exceeds maximum %d", result, splitter.maxScenes)
			}

			// For specific test cases, check expected value
			if tt.expected == splitter.minScenes && result != splitter.minScenes {
				t.Errorf("expected minimum scenes %d, got %d", splitter.minScenes, result)
			}
			if tt.expected == splitter.maxScenes && result < splitter.maxScenes-1 {
				t.Errorf("expected close to maximum scenes (at least %d), got %d", splitter.maxScenes-1, result)
			}
		})
	}
}

func TestSceneSplitter_extractKeyPhrases(t *testing.T) {
	splitter := NewSceneSplitter()

	tests := []struct {
		name          string
		text          string
		expectPhrases bool
	}{
		{
			name:          "text with descriptive patterns",
			text:          "아름다운 숲에서 작은 토끼가 뛰어다녔습니다.",
			expectPhrases: true,
		},
		{
			name:          "simple text",
			text:          "안녕하세요.",
			expectPhrases: false,
		},
		{
			name:          "text with possessive patterns",
			text:          "소녀의 마음이 따뜻했습니다.",
			expectPhrases: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			phrases := splitter.extractKeyPhrases(tt.text)

			if tt.expectPhrases && len(phrases) == 0 {
				t.Errorf("expected key phrases but got none")
			}

			// Verify phrase limit
			if len(phrases) > 3 {
				t.Errorf("expected at most 3 key phrases, got %d", len(phrases))
			}
		})
	}
}

func TestSceneSplitter_classifyScene(t *testing.T) {
	splitter := NewSceneSplitter()

	tests := []struct {
		name         string
		text         string
		index        int
		totalScenes  int
		expectedType SceneType
	}{
		{
			name:         "opening scene",
			text:         "옛날에 한 소년이 있었습니다.",
			index:        0,
			totalScenes:  8,
			expectedType: OpeningScene,
		},
		{
			name:         "closing scene",
			text:         "그리고 행복하게 살았답니다.",
			index:        7,
			totalScenes:  8,
			expectedType: ClosingScene,
		},
		{
			name:         "action scene",
			text:         "소년이 빠르게 달렸습니다.",
			index:        3,
			totalScenes:  8,
			expectedType: ActionScene,
		},
		{
			name:         "dialogue scene",
			text:         "소년이 말했습니다.",
			index:        2,
			totalScenes:  8,
			expectedType: DialogueScene,
		},
		{
			name:         "climax scene",
			text:         "마침내 용을 물리쳤습니다.",
			index:        6,
			totalScenes:  8,
			expectedType: ClimaxScene,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := splitter.classifyScene(tt.text, tt.index, tt.totalScenes)

			if result != tt.expectedType {
				t.Errorf("expected scene type %d, got %d", tt.expectedType, result)
			}
		})
	}
}

func TestSceneSplitter_sortAndDeduplicate(t *testing.T) {
	splitter := NewSceneSplitter()

	tests := []struct {
		name     string
		input    []int
		expected []int
	}{
		{
			name:     "unsorted with duplicates",
			input:    []int{5, 2, 8, 2, 1, 8, 3},
			expected: []int{1, 2, 3, 5, 8},
		},
		{
			name:     "already sorted",
			input:    []int{1, 2, 3, 4, 5},
			expected: []int{1, 2, 3, 4, 5},
		},
		{
			name:     "empty slice",
			input:    []int{},
			expected: []int{},
		},
		{
			name:     "single element",
			input:    []int{5},
			expected: []int{5},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := splitter.sortAndDeduplicate(tt.input)

			if len(result) != len(tt.expected) {
				t.Errorf("expected length %d, got %d", len(tt.expected), len(result))
				return
			}

			for i, v := range result {
				if v != tt.expected[i] {
					t.Errorf("at index %d: expected %d, got %d", i, tt.expected[i], v)
				}
			}
		})
	}
}

// Benchmarks for performance testing

func BenchmarkSceneSplitter_SplitIntoScenes(b *testing.B) {
	splitter := NewSceneSplitter()
	story := &models.Story{
		Title:   "벤치마크 테스트",
		Content: "어느 날 밤, 하늘에서 가장 작은 별이 지구로 여행을 떠났습니다. 별은 처음으로 지구의 아름다운 풍경을 보고 감탄했습니다. 깊은 숲 속에서 반딧불이를 만났고, 함께 아름다운 빛의 춤을 추었습니다. 반딧불이는 별에게 지구의 밤이 얼마나 아름다운지 보여주었고, 별은 반딧불이에게 우주의 신비를 들려주었습니다. 새벽이 되자 별은 다시 하늘로 돌아가야 했지만, 반딧불이와의 우정은 영원히 그들의 마음속에서 빛났습니다. 그 후로 매일 밤, 별과 반딧불이는 서로를 그리워하며 빛을 내고 있습니다.",
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := splitter.SplitIntoScenes(story)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkSceneSplitter_findNaturalBreakPoints(b *testing.B) {
	splitter := NewSceneSplitter()
	content := "어느 날 밤, 하늘에서 가장 작은 별이 지구로 여행을 떠났습니다. 별은 처음으로 지구의 아름다운 풍경을 보고 감탄했습니다. 깊은 숲 속에서 반딧불이를 만났고, 함께 아름다운 빛의 춤을 추었습니다. 그런데 반딧불이는 별에게 지구의 밤이 얼마나 아름다운지 보여주었습니다. 하지만 새벽이 되자 별은 다시 하늘로 돌아가야 했습니다."

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = splitter.findNaturalBreakPoints(content)
	}
}
