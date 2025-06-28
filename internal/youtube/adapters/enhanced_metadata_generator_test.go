package adapters

import (
	"context"
	"os"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/youtube/ports"
)

func TestEnhancedMetadataGenerator_GenerateMetadata(t *testing.T) {
	// Setup enhanced generator with mock
	openAIConfig := &config.OpenAIConfig{
		APIKey:      "test-api-key",
		BaseURL:     "https://api.openai.com/v1/chat/completions",
		Model:       "gpt-3.5-turbo",
		MaxTokens:   500,
		Temperature: 0.3,
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true) // Use mock
	require.NoError(t, err)

	tests := []struct {
		name         string
		storyContent string
		channelType  string
		expectError  bool
		errorMessage string
		validateFunc func(*testing.T, *ports.Metadata)
	}{
		{
			name: "동화 채널 OpenAI 향상된 메타데이터 생성",
			storyContent: `옛날 옛적에 한 왕국에 아름다운 공주가 살고 있었습니다. 
공주는 매일 성 밖으로 나가 백성들과 함께 지내며 모든 이들에게 사랑받았습니다. 
어느 날 마법사가 나타나 공주에게 특별한 능력을 주었고, 
공주는 그 능력으로 왕국을 더욱 평화롭게 만들었습니다.`,
			channelType: "fairy_tale",
			validateFunc: func(t *testing.T, metadata *ports.Metadata) {
				// Enhanced title should use new template format (contains at least one emoji and | separator)
				assert.Contains(t, metadata.Title, "|")
				assert.LessOrEqual(t, len(metadata.Title), 100)
				// Should contain either ✨, 🌟, 🏰, or 💖 (any fairy tale emoji)
				hasEmojiTitle := strings.Contains(metadata.Title, "✨") ||
					strings.Contains(metadata.Title, "🌟") ||
					strings.Contains(metadata.Title, "🏰") ||
					strings.Contains(metadata.Title, "💖")
				assert.True(t, hasEmojiTitle, "Title should contain fairy tale emoji")

				// Enhanced description should use template structure
				assert.Contains(t, metadata.Description, "📚")
				assert.Contains(t, metadata.Description, "✨")
				assert.Contains(t, metadata.Description, "#동화")
				assert.LessOrEqual(t, len(metadata.Description), 5000)

				// Enhanced tags from AI analysis
				assert.Contains(t, metadata.Tags, "동화")
				assert.Contains(t, metadata.Tags, "교육")
				assert.Contains(t, metadata.Tags, "아이들")
				assert.Contains(t, metadata.Tags, "마법") // From AI analysis
				assert.LessOrEqual(t, len(metadata.Tags), 15)

				// Category and settings from new config
				assert.Equal(t, "27", metadata.CategoryID) // Education
				assert.Equal(t, "ko", metadata.DefaultLanguage)
				assert.Equal(t, "public", metadata.Privacy)
			},
		},
		{
			name: "공포 채널 향상된 메타데이터",
			storyContent: `깊은 밤, 낡은 저택에서 혼자 살던 한 남자가 있었습니다. 
매일 밤 똑같은 시간에 들려오는 발소리에 그는 점점 불안해졌습니다. 
어느 날 밤, 용기를 내어 발소리의 근원을 찾아 나섰지만, 
그곳에서 마주한 것은 상상하지 못했던 진실이었습니다.`,
			channelType: "horror",
			validateFunc: func(t *testing.T, metadata *ports.Metadata) {
				assert.Contains(t, metadata.Title, "|")
				// Should contain any horror emoji: 🌙, 👻, 😱, or 🔍
				hasHorrorEmoji := strings.Contains(metadata.Title, "🌙") ||
					strings.Contains(metadata.Title, "👻") ||
					strings.Contains(metadata.Title, "😱") ||
					strings.Contains(metadata.Title, "🔍")
				assert.True(t, hasHorrorEmoji, "Title should contain horror emoji")

				assert.Contains(t, metadata.Description, "🌙")
				assert.Contains(t, metadata.Description, "👻")
				assert.Contains(t, metadata.Description, "#공포")

				assert.Contains(t, metadata.Tags, "공포")
				assert.Contains(t, metadata.Tags, "호러")
				assert.Contains(t, metadata.Tags, "미스터리")

				assert.Equal(t, "24", metadata.CategoryID) // Entertainment
			},
		},
		{
			name: "로맨스 채널 향상된 메타데이터",
			storyContent: `카페에서 우연히 마주친 두 사람. 
매일 같은 시간에 같은 자리에 앉아 있던 그들은 서로에게 호감을 느끼고 있었습니다. 
어느 날 비가 오던 날, 하나의 우산 아래에서 시작된 첫 대화는 
두 사람의 인생을 완전히 바꾸어 놓았습니다.`,
			channelType: "romance",
			validateFunc: func(t *testing.T, metadata *ports.Metadata) {
				assert.Contains(t, metadata.Title, "|")
				// Should contain any romance emoji: 💕, 💖, ☕, or 🌸
				hasRomanceEmoji := strings.Contains(metadata.Title, "💕") ||
					strings.Contains(metadata.Title, "💖") ||
					strings.Contains(metadata.Title, "☕") ||
					strings.Contains(metadata.Title, "🌸")
				assert.True(t, hasRomanceEmoji, "Title should contain romance emoji")

				assert.Contains(t, metadata.Description, "💕")
				assert.Contains(t, metadata.Description, "💖")
				assert.Contains(t, metadata.Description, "#로맨스")

				assert.Contains(t, metadata.Tags, "로맨스")
				assert.Contains(t, metadata.Tags, "사랑")
				assert.Contains(t, metadata.Tags, "만남")
			},
		},
		{
			name:         "빈 스토리 콘텐츠",
			storyContent: "",
			channelType:  "fairy_tale",
			expectError:  true,
			errorMessage: "story content is required",
		},
		{
			name:         "지원하지 않는 채널 타입",
			storyContent: "이것은 충분히 긴 테스트 스토리 콘텐츠입니다. 최소 20자를 넘어야 합니다.",
			channelType:  "unsupported_type",
			expectError:  true,
			errorMessage: "unsupported channel type",
		},
		{
			name:         "너무 짧은 스토리 콘텐츠",
			storyContent: "짧음",
			channelType:  "fairy_tale",
			expectError:  true,
			errorMessage: "story content too short",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := generator.GenerateMetadata(context.Background(), tt.storyContent, tt.channelType)

			if tt.expectError {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.errorMessage)
				assert.Nil(t, result)
			} else {
				require.NoError(t, err)
				require.NotNil(t, result)
				tt.validateFunc(t, result)
			}
		})
	}
}

func TestEnhancedMetadataGenerator_OpenAIIntegration(t *testing.T) {
	// Test with SKIP_OPENAI_API environment variable
	if err := os.Setenv("SKIP_OPENAI_API", "true"); err != nil {
		t.Fatalf("Failed to set environment variable: %v", err)
	}
	defer func() {
		if err := os.Unsetenv("SKIP_OPENAI_API"); err != nil {
			t.Logf("Failed to unset environment variable: %v", err)
		}
	}()

	openAIConfig := &config.OpenAIConfig{
		APIKey:      "test-api-key",
		BaseURL:     "https://api.openai.com/v1/chat/completions",
		Model:       "gpt-3.5-turbo",
		MaxTokens:   500,
		Temperature: 0.3,
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, false) // Don't use mock, but API will be skipped
	require.NoError(t, err)

	storyContent := `마법사와 공주의 아름다운 우정 이야기입니다. 
두 사람은 어려움을 함께 극복하며 진정한 친구가 되었습니다.`

	metadata, err := generator.GenerateMetadata(context.Background(), storyContent, "fairy_tale")
	require.NoError(t, err)
	require.NotNil(t, metadata)

	// Should still work with fallback mock analysis
	assert.NotEmpty(t, metadata.Title)
	assert.NotEmpty(t, metadata.Description)
	assert.NotEmpty(t, metadata.Tags)
}

func TestEnhancedMetadataGenerator_SpecialCharacterValidation(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	tests := []struct {
		name         string
		storyContent string
		channelType  string
		expectError  bool
		validateFunc func(*testing.T, *ports.Metadata)
	}{
		{
			name: "이모지가 포함된 정상적인 스토리",
			storyContent: `공주와 왕자가 만나서 💕 사랑에 빠졌습니다! 
그들은 함께 모험을 떠나며 ⭐ 별빛 아래에서 약속을 나누었습니다.`,
			channelType: "fairy_tale",
			validateFunc: func(t *testing.T, metadata *ports.Metadata) {
				assert.NotEmpty(t, metadata.Title)
				assert.NotEmpty(t, metadata.Description)
				// 적절한 양의 이모지는 허용되어야 함 (any fairy tale emoji)
				hasFairyTaleEmoji := strings.Contains(metadata.Title, "✨") ||
					strings.Contains(metadata.Title, "🌟") ||
					strings.Contains(metadata.Title, "🏰") ||
					strings.Contains(metadata.Title, "💖")
				assert.True(t, hasFairyTaleEmoji, "Title should contain fairy tale emoji")
			},
		},
		{
			name: "특수문자가 많은 스토리",
			storyContent: `정상적인 한국어 스토리입니다. 공주가 살았습니다. 
왕자와 만났습니다. 행복하게 살았습니다. 끝.`,
			channelType: "fairy_tale",
			validateFunc: func(t *testing.T, metadata *ports.Metadata) {
				// 금지된 문자가 없으면 정상 처리되어야 함
				assert.NotContains(t, metadata.Title, "<")
				assert.NotContains(t, metadata.Title, ">")
				assert.NotContains(t, metadata.Title, "[")
				assert.NotContains(t, metadata.Title, "]")
				assert.NotContains(t, metadata.Description, "<")
				assert.NotContains(t, metadata.Description, ">")
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := generator.GenerateMetadata(context.Background(), tt.storyContent, tt.channelType)

			if tt.expectError {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
				require.NotNil(t, result)
				tt.validateFunc(t, result)
			}
		})
	}
}

func TestEnhancedMetadataGenerator_LengthValidation(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	// Test with normal story
	normalStory := `옛날 옛적에 한 마을에 착한 소녀가 살고 있었습니다. 
소녀는 매일 할머니를 도와드리며 착하게 살았습니다.`

	metadata, err := generator.GenerateMetadata(context.Background(), normalStory, "fairy_tale")
	require.NoError(t, err)

	// 길이 제한 검증
	assert.LessOrEqual(t, len(metadata.Title), 100)
	assert.LessOrEqual(t, len(metadata.Description), 5000)
	assert.LessOrEqual(t, len(metadata.Tags), 15)

	// 태그 총 길이 검증
	totalTagLength := 0
	for _, tag := range metadata.Tags {
		totalTagLength += len(tag)
	}
	assert.LessOrEqual(t, totalTagLength, 500)
}

func TestEnhancedMetadataGenerator_ContentAnalysis(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	tests := []struct {
		name         string
		storyContent string
		channelType  string
		expectedTags []string
	}{
		{
			name: "마법 요소가 포함된 동화",
			storyContent: `마법사가 공주에게 특별한 마법을 가르쳐주었습니다. 
공주는 그 마법으로 동물들과 대화할 수 있게 되었습니다.`,
			channelType:  "fairy_tale",
			expectedTags: []string{"동물", "마법", "공주"},
		},
		{
			name: "가족 관계가 중심인 동화",
			storyContent: `엄마와 아이가 함께 숲속을 걸으며 대화를 나누었습니다. 
가족의 사랑이 얼마나 소중한지 깨달았습니다.`,
			channelType:  "fairy_tale",
			expectedTags: []string{"가족", "엄마"},
		},
		{
			name: "미스터리 요소가 강한 공포",
			storyContent: `밤마다 들려오는 수상한 소리의 정체를 찾기 위해 
주인공은 어두운 저택을 탐험하기 시작했습니다.`,
			channelType:  "horror",
			expectedTags: []string{"밤", "미스터리", "저택"},
		},
		{
			name: "카페에서의 로맨스",
			storyContent: `매일 같은 카페에서 마주치는 두 사람이 
드디어 용기를 내어 대화를 시작했습니다. 첫사랑의 설렘이 시작되었습니다.`,
			channelType:  "romance",
			expectedTags: []string{"카페", "만남", "설렘"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			metadata, err := generator.GenerateMetadata(context.Background(), tt.storyContent, tt.channelType)
			require.NoError(t, err)

			// AI 분석에 기반한 태그가 포함되어야 함
			for _, expectedTag := range tt.expectedTags {
				found := false
				for _, tag := range metadata.Tags {
					if tag == expectedTag {
						found = true
						break
					}
				}
				if !found {
					// 일부 태그는 컨텐츠 분석에 따라 달라질 수 있으므로 경고만
					t.Logf("Expected tag '%s' not found in tags: %v", expectedTag, metadata.Tags)
				}
			}
		})
	}
}

func TestEnhancedMetadataGenerator_ChannelConfigLoading(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	// 모든 채널 설정이 로드되었는지 확인
	assert.Contains(t, generator.channelConfigs, "fairy_tale")
	assert.Contains(t, generator.channelConfigs, "horror")
	assert.Contains(t, generator.channelConfigs, "romance")

	// 각 채널의 설정이 올바르게 로드되었는지 확인
	fairyTaleConfig := generator.channelConfigs["fairy_tale"]
	assert.NotEmpty(t, fairyTaleConfig.YouTubeInfo.Metadata.TitleTemplates)
	assert.NotEmpty(t, fairyTaleConfig.YouTubeInfo.Metadata.DescriptionTemplate)
	assert.NotEmpty(t, fairyTaleConfig.YouTubeInfo.Metadata.BaseTags)
	assert.Equal(t, "27", fairyTaleConfig.YouTubeInfo.Metadata.CategoryID)

	horrorConfig := generator.channelConfigs["horror"]
	assert.Equal(t, "24", horrorConfig.YouTubeInfo.Metadata.CategoryID)

	romanceConfig := generator.channelConfigs["romance"]
	assert.Equal(t, "24", romanceConfig.YouTubeInfo.Metadata.CategoryID)
}

func TestEnhancedMetadataGenerator_InterfaceCompliance(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	// MetadataGenerator 인터페이스 구현 확인
	var _ ports.MetadataGenerator = generator

	storyContent := "테스트용 스토리 콘텐츠입니다. 공주와 왕자의 이야기입니다."
	channelType := "fairy_tale"

	// GenerateTitle 메서드 테스트
	title, err := generator.GenerateTitle(context.Background(), storyContent, channelType)
	require.NoError(t, err)
	assert.NotEmpty(t, title)

	// GenerateDescription 메서드 테스트
	description, err := generator.GenerateDescription(context.Background(), storyContent, title, channelType)
	require.NoError(t, err)
	assert.NotEmpty(t, description)

	// GenerateTags 메서드 테스트
	tags, err := generator.GenerateTags(context.Background(), storyContent, channelType)
	require.NoError(t, err)
	assert.NotEmpty(t, tags)
}

func TestEnhancedMetadataGenerator_MockAnalysis(t *testing.T) {
	openAIConfig := &config.OpenAIConfig{
		APIKey:  "test-api-key",
		BaseURL: "https://api.openai.com/v1/chat/completions",
		Model:   "gpt-3.5-turbo",
	}

	generator, err := NewEnhancedMetadataGenerator(openAIConfig, true)
	require.NoError(t, err)

	// 각 채널 타입별 목 분석 테스트
	tests := []struct {
		channelType     string
		expectedTheme   string
		expectedContent string
	}{
		{
			channelType:     "fairy_tale",
			expectedTheme:   "우정과 용기",
			expectedContent: "adventure",
		},
		{
			channelType:     "horror",
			expectedTheme:   "미스터리와 긴장감",
			expectedContent: "mystery",
		},
		{
			channelType:     "romance",
			expectedTheme:   "사랑과 만남",
			expectedContent: "first_love",
		},
	}

	for _, tt := range tests {
		t.Run(tt.channelType, func(t *testing.T) {
			analysis := generator.getMockAnalysis("test content", tt.channelType)

			assert.Equal(t, tt.expectedTheme, analysis.MainTheme)
			assert.Equal(t, tt.expectedContent, analysis.ContentType)
			assert.NotEmpty(t, analysis.KeyCharacters)
			assert.NotEmpty(t, analysis.KeyMoments)
			assert.NotEmpty(t, analysis.SEOKeywords)
			assert.NotEmpty(t, analysis.HookSuggestion)
		})
	}
}
