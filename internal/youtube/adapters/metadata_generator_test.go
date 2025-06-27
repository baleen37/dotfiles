package adapters

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/youtube/ports"
)

func TestMetadataGenerator_GenerateMetadata(t *testing.T) {
	tests := []struct {
		name         string
		storyContent string
		channelType  string
		expected     *ports.Metadata
		expectError  bool
		errorMessage string
	}{
		{
			name: "동화 채널 메타데이터 생성 성공",
			storyContent: `옛날 옛적에 한 왕국에 아름다운 공주가 살고 있었습니다. 
공주는 매일 성 밖으로 나가 백성들과 함께 지내며 모든 이들에게 사랑받았습니다. 
어느 날 마법사가 나타나 공주에게 특별한 능력을 주었고, 
공주는 그 능력으로 왕국을 더욱 평화롭게 만들었습니다.`,
			channelType: "fairy_tale",
			expected: &ports.Metadata{
				Title:           "마법 공주의 따뜻한 이야기 ✨",
				Description:     "아름다운 공주와 마법사의 감동적인 이야기를 만나보세요! 💖\n\n🏰 한 왕국의 아름다운 공주\n✨ 마법사로부터 받은 특별한 능력\n💝 백성들을 위한 공주의 따뜻한 마음\n🌟 평화로운 왕국을 만든 이야기\n\n#동화 #공주 #마법 #따뜻한이야기 #유튜브쇼츠",
				Tags:            []string{"동화", "공주", "마법", "교육", "아이들", "이야기", "유튜브쇼츠", "따뜻한이야기"},
				CategoryID:      "27", // Education
				DefaultLanguage: "ko",
				Privacy:         "public",
			},
		},
		{
			name: "공포 채널 메타데이터 생성 성공",
			storyContent: `깊은 밤, 낡은 저택에서 혼자 살던 한 남자가 있었습니다. 
매일 밤 똑같은 시간에 들려오는 발소리에 그는 점점 불안해졌습니다. 
어느 날 밤, 용기를 내어 발소리의 근원을 찾아 나섰지만, 
그곳에서 마주한 것은 상상하지 못했던 진실이었습니다.`,
			channelType: "horror",
			expected: &ports.Metadata{
				Title:           "깊은 밤 저택의 수수께끼 🌙",
				Description:     "매일 밤 들려오는 발소리의 정체는? 😱\n\n🏚️ 낡은 저택의 미스터리\n👻 매일 밤 똑같은 시간의 발소리\n🔍 용기를 낸 남자의 탐험\n😰 상상하지 못했던 진실\n\n#공포 #미스터리 #저택 #밤 #유튜브쇼츠",
				Tags:            []string{"공포", "호러", "미스터리", "저택", "밤", "발소리", "유튜브쇼츠", "무서운이야기"},
				CategoryID:      "24", // Entertainment
				DefaultLanguage: "ko",
				Privacy:         "public",
			},
		},
		{
			name: "로맨스 채널 메타데이터 생성 성공",
			storyContent: `카페에서 우연히 마주친 두 사람. 
매일 같은 시간에 같은 자리에 앉아 있던 그들은 서로에게 호감을 느끼고 있었습니다. 
어느 날 비가 오던 날, 하나의 우산 아래에서 시작된 첫 대화는 
두 사람의 인생을 완전히 바꾸어 놓았습니다.`,
			channelType: "romance",
			expected: &ports.Metadata{
				Title:           "카페에서 시작된 운명적 만남 ☕",
				Description:     "하나의 우산 아래에서 시작된 아름다운 사랑 이야기 💕\n\n☕ 카페에서의 운명적 만남\n💑 매일 같은 시간, 같은 자리\n🌧️ 비 오던 날의 첫 대화\n💖 인생을 바꾼 특별한 순간\n\n#로맨스 #사랑 #카페 #만남 #유튜브쇼츠",
				Tags:            []string{"로맨스", "사랑", "만남", "카페", "연인", "달콤한이야기", "유튜브쇼츠", "감동"},
				CategoryID:      "24", // Entertainment
				DefaultLanguage: "ko",
				Privacy:         "public",
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
			generator := NewMetadataGenerator()

			result, err := generator.GenerateMetadata(context.Background(), tt.storyContent, tt.channelType)

			if tt.expectError {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.errorMessage)
				assert.Nil(t, result)
			} else {
				require.NoError(t, err)
				require.NotNil(t, result)

				// 제목 검증
				assert.NotEmpty(t, result.Title)
				assert.LessOrEqual(t, len(result.Title), 100) // YouTube 제목 길이 제한

				// 설명 검증
				assert.NotEmpty(t, result.Description)
				assert.LessOrEqual(t, len(result.Description), 5000) // YouTube 설명 길이 제한

				// 태그 검증
				assert.NotEmpty(t, result.Tags)
				assert.LessOrEqual(t, len(result.Tags), 15) // YouTube 태그 개수 제한

				// 메타데이터 필드 검증
				assert.Equal(t, tt.expected.CategoryID, result.CategoryID)
				assert.Equal(t, tt.expected.DefaultLanguage, result.DefaultLanguage)
				assert.Equal(t, tt.expected.Privacy, result.Privacy)

				// 채널별 특성 검증
				switch tt.channelType {
				case "fairy_tale":
					assert.Contains(t, result.Tags, "동화")
					assert.Contains(t, result.Tags, "아이들")
				case "horror":
					assert.Contains(t, result.Tags, "공포")
					assert.Contains(t, result.Tags, "호러")
				case "romance":
					assert.Contains(t, result.Tags, "로맨스")
					assert.Contains(t, result.Tags, "사랑")
				}

				// 모든 태그에 유튜브쇼츠 포함 확인
				assert.Contains(t, result.Tags, "유튜브쇼츠")
			}
		})
	}
}

func TestMetadataGenerator_GenerateTitle(t *testing.T) {
	tests := []struct {
		name         string
		storyContent string
		channelType  string
		expectedKey  string
		expectError  bool
	}{
		{
			name:         "동화 제목 생성",
			storyContent: "공주와 마법사의 이야기",
			channelType:  "fairy_tale",
			expectedKey:  "공주",
		},
		{
			name:         "공포 제목 생성",
			storyContent: "깊은 밤 저택에서 일어난 일",
			channelType:  "horror",
			expectedKey:  "저택",
		},
		{
			name:         "로맨스 제목 생성",
			storyContent: "카페에서 만난 두 사람의 사랑",
			channelType:  "romance",
			expectedKey:  "사랑",
		},
		{
			name:         "빈 콘텐츠",
			storyContent: "",
			channelType:  "fairy_tale",
			expectError:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			generator := NewMetadataGenerator()

			title, err := generator.GenerateTitle(context.Background(), tt.storyContent, tt.channelType)

			if tt.expectError {
				require.Error(t, err)
				assert.Empty(t, title)
			} else {
				require.NoError(t, err)
				assert.NotEmpty(t, title)
				assert.LessOrEqual(t, len(title), 100)
				if tt.expectedKey != "" {
					assert.Contains(t, title, tt.expectedKey)
				}
			}
		})
	}
}

func TestMetadataGenerator_GenerateDescription(t *testing.T) {
	tests := []struct {
		name         string
		storyContent string
		title        string
		channelType  string
		expectError  bool
	}{
		{
			name:         "동화 설명 생성",
			storyContent: "공주와 마법사의 아름다운 이야기",
			title:        "마법 공주 이야기",
			channelType:  "fairy_tale",
		},
		{
			name:         "공포 설명 생성",
			storyContent: "무서운 저택의 미스터리",
			title:        "깊은 밤의 공포",
			channelType:  "horror",
		},
		{
			name:         "로맨스 설명 생성",
			storyContent: "달콤한 사랑 이야기",
			title:        "운명적 만남",
			channelType:  "romance",
		},
		{
			name:         "빈 제목",
			storyContent: "테스트 스토리",
			title:        "",
			channelType:  "fairy_tale",
			expectError:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			generator := NewMetadataGenerator()

			description, err := generator.GenerateDescription(context.Background(), tt.storyContent, tt.title, tt.channelType)

			if tt.expectError {
				require.Error(t, err)
				assert.Empty(t, description)
			} else {
				require.NoError(t, err)
				assert.NotEmpty(t, description)
				assert.LessOrEqual(t, len(description), 5000)
				// 설명에 해시태그가 포함되어 있는지 확인
				assert.Contains(t, description, "#")
			}
		})
	}
}

func TestMetadataGenerator_GenerateTags(t *testing.T) {
	tests := []struct {
		name         string
		storyContent string
		channelType  string
		expectedTags []string
		expectError  bool
	}{
		{
			name:         "동화 태그 생성",
			storyContent: "공주와 마법사의 이야기",
			channelType:  "fairy_tale",
			expectedTags: []string{"동화", "공주", "마법", "아이들", "유튜브쇼츠"},
		},
		{
			name:         "공포 태그 생성",
			storyContent: "무서운 저택의 미스터리",
			channelType:  "horror",
			expectedTags: []string{"공포", "호러", "미스터리", "저택", "유튜브쇼츠"},
		},
		{
			name:         "로맨스 태그 생성",
			storyContent: "달콤한 사랑 이야기",
			channelType:  "romance",
			expectedTags: []string{"로맨스", "사랑", "달콤한이야기", "유튜브쇼츠"},
		},
		{
			name:         "빈 콘텐츠",
			storyContent: "",
			channelType:  "fairy_tale",
			expectError:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			generator := NewMetadataGenerator()

			tags, err := generator.GenerateTags(context.Background(), tt.storyContent, tt.channelType)

			if tt.expectError {
				require.Error(t, err)
				assert.Empty(t, tags)
			} else {
				require.NoError(t, err)
				assert.NotEmpty(t, tags)
				assert.LessOrEqual(t, len(tags), 15)

				// 필수 태그 확인
				for _, expectedTag := range tt.expectedTags {
					assert.Contains(t, tags, expectedTag)
				}
			}
		})
	}
}
