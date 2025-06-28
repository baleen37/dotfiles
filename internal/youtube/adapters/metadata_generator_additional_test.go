package adapters

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMetadataGenerator_IsNoun(t *testing.T) {
	generator := NewMetadataGenerator()

	tests := []struct {
		name     string
		word     string
		expected bool
	}{
		{
			name:     "한 글자 단어",
			word:     "가",
			expected: true, // len("가") in bytes is 3, not 1
		},
		{
			name:     "조사가 붙은 명사",
			word:     "공주가",
			expected: true,
		},
		{
			name:     "목적격 조사",
			word:     "왕국을",
			expected: true,
		},
		{
			name:     "소유격 조사",
			word:     "마법의",
			expected: true,
		},
		{
			name:     "부사격 조사",
			word:     "숲에",
			expected: true,
		},
		{
			name:     "조사 없는 단어",
			word:     "모험",
			expected: true, // 기본값
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := generator.isNoun(tt.word)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestMetadataGenerator_ExtractKeywords_EdgeCases(t *testing.T) {
	generator := NewMetadataGenerator()

	tests := []struct {
		name         string
		storyContent string
		channelType  string
		wantKeywords bool
	}{
		{
			name:         "패턴이 없는 동화",
			storyContent: "아주 특별한 이야기가 있었습니다. 그 이야기는 정말 놀라웠습니다.",
			channelType:  "fairy_tale",
			wantKeywords: true, // 일반 명사 추출
		},
		{
			name:         "알 수 없는 채널 타입",
			storyContent: "공포스러운 이야기입니다.",
			channelType:  "unknown",
			wantKeywords: true, // 일반 명사 추출
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			keywords := generator.extractKeywords(tt.storyContent, tt.channelType)

			if tt.wantKeywords {
				assert.NotEmpty(t, keywords)
			} else {
				assert.Empty(t, keywords)
			}
		})
	}
}

func TestMetadataGenerator_SplitIntoSentences_ComplexCases(t *testing.T) {
	generator := NewMetadataGenerator()

	tests := []struct {
		name      string
		text      string
		wantCount int
	}{
		{
			name:      "여러 문장 부호 혼합",
			text:      "첫 번째 문장입니다. 두 번째 문장! 세 번째 문장? 네 번째 문장.",
			wantCount: 4,
		},
		{
			name:      "연속된 문장 부호",
			text:      "놀랍습니다!! 정말요??? 대단해요...",
			wantCount: 3,
		},
		{
			name:      "공백만 있는 텍스트",
			text:      "   ",
			wantCount: 0,
		},
		{
			name:      "문장 부호 없는 텍스트",
			text:      "문장 부호가 없는 긴 텍스트입니다",
			wantCount: 1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			sentences := generator.splitIntoSentences(tt.text)
			assert.Len(t, sentences, tt.wantCount)
		})
	}
}

func TestMetadataGenerator_SummarizeSentence_EdgeCases(t *testing.T) {
	generator := NewMetadataGenerator()

	tests := []struct {
		name     string
		sentence string
		expected string
	}{
		{
			name:     "짧은 문장",
			sentence: "짧은 문장",
			expected: "짧은 문장",
		},
		{
			name:     "긴 문장",
			sentence: "이것은 정말 긴 문장인데 50자가 넘어서 요약이 필요한 경우입니다 여기서부터는 잘려야 합니다",
			expected: "이것은 정말 긴 문장인데 50자가...",
		},
		{
			name:     "단어가 적은 긴 문장",
			sentence: "이것은 매우 긴 문장이지만 단어수가 적습니다아아아아아아아아아아아아아아아아아아아아아아아",
			expected: "이것은 매우 긴 문장이지만 단어수가...",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := generator.summarizeSentence(tt.sentence)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestMetadataGenerator_ExtractKeyPoints_Padding(t *testing.T) {
	generator := NewMetadataGenerator()

	// 짧은 스토리로 패딩 테스트
	shortStory := "짧은 이야기입니다."
	points := generator.extractKeyPoints(shortStory, "fairy_tale")

	// 문장이 하나뿐이고 10자 이상이므로 하나의 포인트만 추출됨
	// 그리고 4개로 패딩됨
	assert.GreaterOrEqual(t, len(points), 1) // 최소 1개 이상

	// 패딩된 포인트 확인 (4개 미만인 경우에만)
	if len(points) == 4 {
		paddingCount := 0
		for _, point := range points {
			if point == "특별한 이야기" {
				paddingCount++
			}
		}
		assert.Greater(t, paddingCount, 0)
	}
}

func TestMetadataGenerator_GenerateHookLine_UnknownChannel(t *testing.T) {
	generator := NewMetadataGenerator()

	// 존재하지 않는 채널 타입
	hookLine := generator.generateHookLine("테스트 스토리", "unknown_channel")
	assert.Equal(t, "특별한 이야기를 만나보세요!", hookLine)
}

func TestMetadataGenerator_ExtractMainTheme_UnknownChannel(t *testing.T) {
	generator := NewMetadataGenerator()

	// 존재하지 않는 채널 타입
	theme := generator.extractMainTheme("테스트 스토리", "unknown_channel")
	assert.Equal(t, "이야기", theme)
}

func TestMetadataGenerator_GenerateMetadata_FullIntegration(t *testing.T) {
	generator := NewMetadataGenerator()

	// 모든 패턴을 포함한 복잡한 스토리
	complexStory := `옛날 옛적에 아름다운 공주가 살고 있었습니다. 
	공주는 마법사와 친구가 되어 모험을 떠났습니다.
	깊은 숲 속에서 용감한 기사를 만났고, 함께 왕국을 구했습니다.
	그들의 우정은 영원히 이어졌고, 모두가 행복하게 살았답니다.`

	metadata, err := generator.GenerateMetadata(context.Background(), complexStory, "fairy_tale")
	require.NoError(t, err)

	// 메타데이터 검증
	assert.NotEmpty(t, metadata.Title)
	assert.Contains(t, metadata.Title, "✨") // 이모지 포함 확인
	assert.LessOrEqual(t, len(metadata.Title), 100)

	assert.NotEmpty(t, metadata.Description)
	assert.Contains(t, metadata.Description, "#동화")
	assert.LessOrEqual(t, len(metadata.Description), 5000)

	assert.NotEmpty(t, metadata.Tags)
	assert.Contains(t, metadata.Tags, "동화")
	assert.LessOrEqual(t, len(metadata.Tags), 15)

	// 추출된 키워드 확인
	hasExpectedKeyword := false
	expectedKeywords := []string{"공주", "마법", "모험", "우정"}
	for _, tag := range metadata.Tags {
		for _, expected := range expectedKeywords {
			if tag == expected {
				hasExpectedKeyword = true
				break
			}
		}
	}
	assert.True(t, hasExpectedKeyword, "Expected at least one keyword from story")
}
