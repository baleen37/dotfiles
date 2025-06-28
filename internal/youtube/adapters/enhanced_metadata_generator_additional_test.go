package adapters

import (
	"context"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/config"
)

func TestEnhancedMetadataGenerator_BuildAnalysisPrompts(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	tests := []struct {
		name         string
		channelType  string
		wantContains []string
	}{
		{
			name:        "동화 채널 시스템 프롬프트",
			channelType: "fairy_tale",
			wantContains: []string{
				"YouTube Shorts 콘텐츠 분석 전문가",
				"교육적 가치",
				"교훈",
				"캐릭터의 성장",
			},
		},
		{
			name:        "공포 채널 시스템 프롬프트",
			channelType: "horror",
			wantContains: []string{
				"긴장감",
				"미스터리 요소",
				"반전",
			},
		},
		{
			name:        "로맨스 채널 시스템 프롬프트",
			channelType: "romance",
			wantContains: []string{
				"감정적 연결",
				"로맨틱한 순간",
				"관계 발전",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			systemPrompt := generator.buildAnalysisSystemPrompt(tt.channelType)
			for _, want := range tt.wantContains {
				assert.Contains(t, systemPrompt, want)
			}
		})
	}
}

func TestEnhancedMetadataGenerator_BuildAnalysisUserPrompt(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	storyContent := "테스트 스토리 내용입니다."
	channelType := "fairy_tale"

	userPrompt := generator.buildAnalysisUserPrompt(storyContent, channelType)

	assert.Contains(t, userPrompt, storyContent)
	assert.Contains(t, userPrompt, channelType)
	assert.Contains(t, userPrompt, "다음")
	assert.Contains(t, userPrompt, "스토리를 분석해주세요")
}

func TestEnhancedMetadataGenerator_ParseAnalysisResult(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	tests := []struct {
		name        string
		jsonContent string
		expectError bool
		expectTheme string
	}{
		{
			name: "유효한 JSON 파싱",
			jsonContent: `{
				"main_theme": "우정과 모험",
				"key_characters": ["주인공", "친구"],
				"emotional_tone": "밝고 희망적",
				"key_moments": ["만남", "모험", "성장"],
				"seo_keywords": ["동화", "우정"],
				"content_type": "adventure",
				"hook_suggestion": "흥미진진한 모험!"
			}`,
			expectError: false,
			expectTheme: "우정과 모험",
		},
		{
			name: "추가 텍스트가 있는 JSON",
			jsonContent: `분석 결과는 다음과 같습니다:
			{
				"main_theme": "사랑 이야기",
				"key_characters": ["연인1", "연인2"],
				"emotional_tone": "로맨틱",
				"key_moments": ["만남"],
				"seo_keywords": ["로맨스"],
				"content_type": "romance",
				"hook_suggestion": "달콤한 사랑!"
			}
			이상입니다.`,
			expectError: false,
			expectTheme: "사랑 이야기",
		},
		{
			name:        "잘못된 JSON",
			jsonContent: "이것은 JSON이 아닙니다",
			expectError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			analysis, err := generator.parseAnalysisResult(tt.jsonContent)

			if tt.expectError {
				assert.Error(t, err)
			} else {
				require.NoError(t, err)
				assert.Equal(t, tt.expectTheme, analysis.MainTheme)
			}
		})
	}
}

func TestEnhancedMetadataGenerator_ExtractTitleFromAnalysis(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	tests := []struct {
		name     string
		analysis ContentAnalysis
		expected string
	}{
		{
			name: "메인 테마가 있는 경우",
			analysis: ContentAnalysis{
				MainTheme:  "우정의 힘",
				KeyMoments: []string{"첫 만남", "도전"},
			},
			expected: "우정의 힘",
		},
		{
			name: "메인 테마가 없고 키 모먼트가 있는 경우",
			analysis: ContentAnalysis{
				MainTheme:  "",
				KeyMoments: []string{"마법의 발견", "모험 시작"},
			},
			expected: "마법의 발견",
		},
		{
			name: "모두 비어있는 경우",
			analysis: ContentAnalysis{
				MainTheme:  "",
				KeyMoments: []string{},
			},
			expected: "특별한 이야기",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			title := generator.extractTitleFromAnalysis(&tt.analysis)
			assert.Equal(t, tt.expected, title)
		})
	}
}

func TestEnhancedMetadataGenerator_GetHookLine(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	// Load channel configs to get real hook lines
	require.NoError(t, generator.loadChannelConfigs())

	fairyTaleConfig := generator.channelConfigs["fairy_tale"]
	require.NotNil(t, fairyTaleConfig)

	tests := []struct {
		name     string
		analysis ContentAnalysis
		expected string
	}{
		{
			name: "콘텐츠 타입 매칭",
			analysis: ContentAnalysis{
				ContentType:    "adventure",
				HookSuggestion: "",
			},
			expected: fairyTaleConfig.YouTubeInfo.Metadata.HookLines["adventure"],
		},
		{
			name: "AI 제안 사용",
			analysis: ContentAnalysis{
				ContentType:    "unknown",
				HookSuggestion: "AI가 제안한 훅 라인",
			},
			expected: "AI가 제안한 훅 라인",
		},
		{
			name: "기본값 사용",
			analysis: ContentAnalysis{
				ContentType:    "unknown",
				HookSuggestion: "",
			},
			expected: fairyTaleConfig.YouTubeInfo.Metadata.HookLines["default"],
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			hookLine := generator.getHookLine(&tt.analysis, fairyTaleConfig)
			assert.Equal(t, tt.expected, hookLine)
		})
	}
}

func TestEnhancedMetadataGenerator_GenerateSummaryFromAnalysis(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	tests := []struct {
		name     string
		analysis ContentAnalysis
		expected string
	}{
		{
			name: "테마와 캐릭터가 모두 있는 경우",
			analysis: ContentAnalysis{
				MainTheme:     "우정의 가치",
				KeyCharacters: []string{"토끼", "거북이"},
				KeyMoments:    []string{"경주 시작"},
			},
			expected: "토끼와 거북이의 우정의 가치",
		},
		{
			name: "테마만 있는 경우",
			analysis: ContentAnalysis{
				MainTheme:     "모험 이야기",
				KeyCharacters: []string{},
				KeyMoments:    []string{"출발"},
			},
			expected: "모험 이야기",
		},
		{
			name: "키 모먼트만 있는 경우",
			analysis: ContentAnalysis{
				MainTheme:     "",
				KeyCharacters: []string{},
				KeyMoments:    []string{"마법의 순간"},
			},
			expected: "마법의 순간",
		},
		{
			name:     "모두 비어있는 경우",
			analysis: ContentAnalysis{},
			expected: "특별한 이야기",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			summary := generator.generateSummaryFromAnalysis(&tt.analysis)
			assert.Equal(t, tt.expected, summary)
		})
	}
}

func TestEnhancedMetadataGenerator_GenerateBasicMetadata(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	storyContent := "옛날 옛적에 아름다운 공주가 살았습니다. 공주는 마법의 힘을 가지고 있었고, 왕국을 구하는 모험을 떠났습니다."
	channelType := "fairy_tale"

	config := generator.channelConfigs[channelType]
	require.NotNil(t, config)

	metadata, err := generator.generateBasicMetadata(storyContent, channelType, config)
	require.NoError(t, err)

	assert.NotEmpty(t, metadata.Title)
	assert.NotEmpty(t, metadata.Description)
	assert.NotEmpty(t, metadata.Tags)
	assert.Equal(t, "27", metadata.CategoryID)
	assert.Equal(t, "ko", metadata.DefaultLanguage)
	assert.Equal(t, "public", metadata.Privacy)

	// 제약 조건 확인
	assert.LessOrEqual(t, len(metadata.Title), 100)
	assert.LessOrEqual(t, len(metadata.Description), 5000)
	assert.LessOrEqual(t, len(metadata.Tags), 15)
}

func TestEnhancedMetadataGenerator_AnalyzeContentWithMock(t *testing.T) {
	// 환경 변수를 통해 mock 모드 강제
	oldEnv := os.Getenv("SKIP_OPENAI_API")
	err := os.Setenv("SKIP_OPENAI_API", "true")
	require.NoError(t, err)
	defer func() {
		err := os.Setenv("SKIP_OPENAI_API", oldEnv)
		require.NoError(t, err)
	}()

	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, false) // useMock = false but env var set
	require.NoError(t, err)

	storyContent := "테스트 스토리"
	channelType := "fairy_tale"

	analysis, err := generator.analyzeContent(context.Background(), storyContent, channelType)
	require.NoError(t, err)

	// Mock 분석 결과 확인
	assert.Equal(t, "우정과 용기", analysis.MainTheme)
	assert.Equal(t, "adventure", analysis.ContentType)
	assert.NotEmpty(t, analysis.KeyCharacters)
}
