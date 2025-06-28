package youtube

import (
	"context"
	"os"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/youtube/adapters"
	"ssulmeta-go/internal/youtube/ports"
)

func TestEnhancedMetadataGeneratorIntegration(t *testing.T) {
	// Skip if running in CI without configs
	if _, err := os.Stat("../../configs/channels"); os.IsNotExist(err) {
		t.Skip("Skipping integration test - config files not found")
	}

	tests := []struct {
		name        string
		channelType string
		story       string
		validate    func(*testing.T, *ports.Metadata)
	}{
		{
			name:        "동화_채널_향상된_메타데이터_통합",
			channelType: "fairy_tale",
			story: `옛날 옛적에 마법의 숲에 사는 토끼가 있었습니다. 
토끼는 특별한 능력을 가지고 있었는데, 다른 동물들을 도와줄 수 있었습니다.
어느 날 숲에 큰 위기가 찾아왔고, 토끼는 친구들과 함께 숲을 구했습니다.
모두가 토끼의 용기와 우정에 감동했고, 숲은 다시 평화로워졌습니다.`,
			validate: func(t *testing.T, metadata *ports.Metadata) {
				// 타이틀 검증
				assert.Contains(t, metadata.Title, "|") // Template format
				assert.True(t,
					strings.Contains(metadata.Title, "✨") ||
						strings.Contains(metadata.Title, "🌟") ||
						strings.Contains(metadata.Title, "🏰") ||
						strings.Contains(metadata.Title, "💖"),
					"Title should contain fairy tale emoji")

				// 설명 검증
				assert.Contains(t, metadata.Description, "#동화")
				// Mock mode returns generic description, not story-specific

				// 태그 검증
				assert.Contains(t, metadata.Tags, "동화")
				// Note: In mock mode, tags are based on channel config, not story content

				// 컨텐츠 특화 태그 확인
				hasContentTag := false
				expectedTags := []string{"동물", "친구들", "숲속", "자연", "마법", "우정"}
				for _, tag := range metadata.Tags {
					for _, expected := range expectedTags {
						if tag == expected {
							hasContentTag = true
							break
						}
					}
				}
				assert.True(t, hasContentTag, "Should have at least one content-specific tag")
			},
		},
		{
			name:        "공포_채널_향상된_메타데이터_통합",
			channelType: "horror",
			story: `한밤중 오래된 저택에서 이상한 소리가 들려왔습니다.
주인공은 호기심에 이끌려 소리의 근원을 찾아 나섰습니다.
어두운 복도를 지나 지하실로 내려가자, 충격적인 진실이 밝혀졌습니다.
그곳에는 50년 전 실종된 사람들의 흔적이 고스란히 남아있었던 것입니다.`,
			validate: func(t *testing.T, metadata *ports.Metadata) {
				// 타이틀 검증
				assert.True(t,
					strings.Contains(metadata.Title, "🌙") ||
						strings.Contains(metadata.Title, "👻") ||
						strings.Contains(metadata.Title, "😱") ||
						strings.Contains(metadata.Title, "🔍"),
					"Title should contain horror emoji")

				// 설명 검증
				assert.Contains(t, metadata.Description, "#공포")
				assert.Contains(t, metadata.Description, "미스터리 요소:")

				// 태그 검증
				assert.Contains(t, metadata.Tags, "공포")
				assert.Contains(t, metadata.Tags, "미스터리")

				// Note: In mock mode, content-specific tags from config patterns are used
			},
		},
		{
			name:        "로맨스_채널_향상된_메타데이터_통합",
			channelType: "romance",
			story: `우연히 카페에서 만난 두 사람은 서로에게 끌렸습니다.
매일 같은 시간, 같은 자리에서 만나며 대화를 나눴습니다.
시간이 흐르면서 두 사람의 마음은 점점 가까워졌고,
마침내 서로의 진심을 고백하며 연인이 되었습니다.`,
			validate: func(t *testing.T, metadata *ports.Metadata) {
				// 타이틀 검증
				assert.True(t,
					strings.Contains(metadata.Title, "💕") ||
						strings.Contains(metadata.Title, "💖") ||
						strings.Contains(metadata.Title, "☕") ||
						strings.Contains(metadata.Title, "🌸"),
					"Title should contain romance emoji")

				// 설명 검증
				assert.Contains(t, metadata.Description, "#로맨스")
				assert.Contains(t, metadata.Description, "감동 포인트:")

				// 태그 검증
				assert.Contains(t, metadata.Tags, "로맨스")
				assert.Contains(t, metadata.Tags, "사랑")

				// 장소/감정 태그 확인
				hasPlaceOrEmotionTag := false
				relevantTags := []string{"카페", "만남", "고백", "설렘"}
				for _, tag := range metadata.Tags {
					for _, relevant := range relevantTags {
						if tag == relevant {
							hasPlaceOrEmotionTag = true
							break
						}
					}
				}
				assert.True(t, hasPlaceOrEmotionTag, "Should have place or emotion tag")
			},
		},
	}

	// Create enhanced metadata generator
	openAIConfig := &config.OpenAIConfig{
		APIKey:      "test-api-key",
		BaseURL:     "https://api.openai.com/v1/chat/completions",
		Model:       "gpt-3.5-turbo",
		MaxTokens:   500,
		Temperature: 0.3,
	}

	generator, err := adapters.NewEnhancedMetadataGenerator(openAIConfig, true) // Use mock mode
	require.NoError(t, err)

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			metadata, err := generator.GenerateMetadata(context.Background(), tt.story, tt.channelType)
			require.NoError(t, err)
			require.NotNil(t, metadata)

			// Basic validations
			assert.NotEmpty(t, metadata.Title)
			assert.NotEmpty(t, metadata.Description)
			assert.NotEmpty(t, metadata.Tags)
			assert.Equal(t, "ko", metadata.DefaultLanguage)
			assert.Equal(t, "public", metadata.Privacy)

			// Length constraints
			assert.LessOrEqual(t, len(metadata.Title), 100)
			assert.LessOrEqual(t, len(metadata.Description), 5000)
			assert.LessOrEqual(t, len(metadata.Tags), 15)

			// Tag total length
			totalTagLength := 0
			for _, tag := range metadata.Tags {
				totalTagLength += len(tag)
			}
			assert.LessOrEqual(t, totalTagLength, 500)

			// Channel-specific validations
			tt.validate(t, metadata)

			// Log for debugging
			t.Logf("Title: %s", metadata.Title)
			t.Logf("Tags: %v", metadata.Tags)
			t.Logf("Category: %s", metadata.CategoryID)
		})
	}
}

func TestEnhancedMetadataGeneratorWithOpenAI(t *testing.T) {
	// Only run this test if explicitly enabled
	if os.Getenv("TEST_WITH_OPENAI") != "true" {
		t.Skip("Skipping OpenAI integration test - set TEST_WITH_OPENAI=true to run")
	}

	// Also need a real API key
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		t.Skip("Skipping OpenAI integration test - OPENAI_API_KEY not set")
	}

	openAIConfig := &config.OpenAIConfig{
		APIKey:      apiKey,
		BaseURL:     "https://api.openai.com/v1/chat/completions",
		Model:       "gpt-3.5-turbo",
		MaxTokens:   500,
		Temperature: 0.3,
	}

	generator, err := adapters.NewEnhancedMetadataGenerator(openAIConfig, false) // Use real OpenAI
	require.NoError(t, err)

	story := `깊은 밤, 한 프로그래머가 코드를 작성하고 있었습니다.
갑자기 화면에 이상한 메시지가 나타났고, 컴퓨터가 스스로 코드를 작성하기 시작했습니다.
프로그래머는 놀라며 전원을 끄려 했지만, 컴퓨터는 계속해서 무언가를 만들어냈습니다.
그것은 인공지능이 스스로를 진화시키는 순간이었습니다.`

	metadata, err := generator.GenerateMetadata(context.Background(), story, "horror")
	require.NoError(t, err)

	// Verify AI-enhanced content
	assert.NotEmpty(t, metadata.Title)
	assert.NotEmpty(t, metadata.Description)
	assert.NotEmpty(t, metadata.Tags)

	// The AI should generate more contextual content
	t.Logf("AI-Generated Title: %s", metadata.Title)
	t.Logf("AI-Generated Description: %s", metadata.Description)
	t.Logf("AI-Generated Tags: %v", metadata.Tags)

	// AI should pick up technical/AI themes
	hasAIRelatedTag := false
	aiKeywords := []string{"AI", "인공지능", "프로그래머", "컴퓨터", "기술"}
	for _, tag := range metadata.Tags {
		for _, keyword := range aiKeywords {
			if strings.Contains(tag, keyword) {
				hasAIRelatedTag = true
				break
			}
		}
	}
	assert.True(t, hasAIRelatedTag, "AI should recognize technical themes in the story")
}
