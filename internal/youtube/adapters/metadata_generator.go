package adapters

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"ssulmeta-go/internal/youtube/ports"
	"ssulmeta-go/pkg/errors"
)

// MetadataGenerator implements the MetadataGenerator interface
type MetadataGenerator struct {
	channelConfigs map[string]ChannelConfig
}

// ChannelConfig holds configuration for each channel type
type ChannelConfig struct {
	CategoryID     string
	TitleTemplates []string
	DescFormat     string
	BaseTags       []string
	Emojis         []string
}

// NewMetadataGenerator creates a new metadata generator instance
func NewMetadataGenerator() *MetadataGenerator {
	return &MetadataGenerator{
		channelConfigs: map[string]ChannelConfig{
			"fairy_tale": {
				CategoryID: "27", // Education
				TitleTemplates: []string{
					"%s ✨",
					"마법의 %s 🌟",
					"%s의 모험 🏰",
					"따뜻한 %s 💖",
				},
				DescFormat: `%s 💖

🏰 %s
✨ %s
💝 %s
🌟 %s

#동화 #%s #유튜브쇼츠`,
				BaseTags: []string{"동화", "교육", "아이들", "이야기", "유튜브쇼츠", "따뜻한이야기"},
				Emojis:   []string{"✨", "🌟", "🏰", "💖", "💝"},
			},
			"horror": {
				CategoryID: "24", // Entertainment
				TitleTemplates: []string{
					"%s 🌙",
					"깊은 밤 %s 😱",
					"%s의 수수께끼 👻",
					"무서운 %s 🔍",
				},
				DescFormat: `%s 😱

🏚️ %s
👻 %s
🔍 %s
😰 %s

#공포 #%s #유튜브쇼츠`,
				BaseTags: []string{"공포", "호러", "미스터리", "유튜브쇼츠", "무서운이야기"},
				Emojis:   []string{"🌙", "😱", "👻", "🔍", "😰"},
			},
			"romance": {
				CategoryID: "24", // Entertainment
				TitleTemplates: []string{
					"%s ☕",
					"달콤한 %s 💕",
					"%s 이야기 💖",
					"운명적 %s 💑",
				},
				DescFormat: `%s 💕

☕ %s
💑 %s
🌧️ %s
💖 %s

#로맨스 #%s #유튜브쇼츠`,
				BaseTags: []string{"로맨스", "사랑", "만남", "연인", "달콤한이야기", "유튜브쇼츠", "감동"},
				Emojis:   []string{"☕", "💕", "💖", "💑", "🌧️"},
			},
		},
	}
}

// GenerateMetadata generates complete metadata from story content
func (g *MetadataGenerator) GenerateMetadata(ctx context.Context, storyContent string, channelType string) (*ports.Metadata, error) {
	// Validate inputs
	if err := g.validateInputs(storyContent, channelType); err != nil {
		return nil, err
	}

	// Get channel configuration
	config, exists := g.channelConfigs[channelType]
	if !exists {
		return nil, errors.NewValidationError(
			errors.CodeValidationError,
			"unsupported channel type",
			map[string]interface{}{
				"channel_type":            channelType,
				"supported_channel_types": []string{"fairy_tale", "horror", "romance"},
			},
		)
	}

	// Generate individual components
	title, err := g.GenerateTitle(ctx, storyContent, channelType)
	if err != nil {
		return nil, err
	}

	description, err := g.GenerateDescription(ctx, storyContent, title, channelType)
	if err != nil {
		return nil, err
	}

	tags, err := g.GenerateTags(ctx, storyContent, channelType)
	if err != nil {
		return nil, err
	}

	// Create metadata object
	metadata := &ports.Metadata{
		Title:           title,
		Description:     description,
		Tags:            tags,
		CategoryID:      config.CategoryID,
		DefaultLanguage: "ko",
		Privacy:         "public",
	}

	return metadata, nil
}

// GenerateTitle generates a compelling video title
func (g *MetadataGenerator) GenerateTitle(ctx context.Context, storyContent string, channelType string) (string, error) {
	// Validate inputs
	if err := g.validateInputs(storyContent, channelType); err != nil {
		return "", err
	}

	config, exists := g.channelConfigs[channelType]
	if !exists {
		return "", errors.NewValidationError(
			errors.CodeValidationError,
			"unsupported channel type",
			map[string]interface{}{"channel_type": channelType},
		)
	}

	// Extract key elements from story
	keyWords := g.extractKeywords(storyContent, channelType)
	if len(keyWords) == 0 {
		return "", errors.NewValidationError(
			errors.CodeValidationError,
			"failed to extract keywords from story",
			map[string]interface{}{"story_length": len(storyContent)},
		)
	}

	// Select template and generate title
	template := config.TitleTemplates[0] // Use first template for consistency
	title := fmt.Sprintf(template, keyWords[0])

	// Ensure title length is within YouTube limits
	if len(title) > 100 {
		title = title[:97] + "..."
	}

	return title, nil
}

// GenerateDescription generates a video description
func (g *MetadataGenerator) GenerateDescription(ctx context.Context, storyContent string, title string, channelType string) (string, error) {
	// Validate inputs
	if err := g.validateInputs(storyContent, channelType); err != nil {
		return "", err
	}

	if strings.TrimSpace(title) == "" {
		return "", errors.NewValidationError(
			errors.CodeValidationError,
			"title is required for description generation",
			nil,
		)
	}

	config, exists := g.channelConfigs[channelType]
	if !exists {
		return "", errors.NewValidationError(
			errors.CodeValidationError,
			"unsupported channel type",
			map[string]interface{}{"channel_type": channelType},
		)
	}

	// Extract key points from story
	keyPoints := g.extractKeyPoints(storyContent, channelType)
	if len(keyPoints) < 4 {
		// Pad with generic points if needed
		for len(keyPoints) < 4 {
			keyPoints = append(keyPoints, "특별한 이야기")
		}
	}

	// Generate description using template
	description := fmt.Sprintf(config.DescFormat,
		g.generateHookLine(storyContent, channelType),
		keyPoints[0],
		keyPoints[1],
		keyPoints[2],
		keyPoints[3],
		g.extractMainTheme(storyContent, channelType),
	)

	return description, nil
}

// GenerateTags generates relevant tags for the video
func (g *MetadataGenerator) GenerateTags(ctx context.Context, storyContent string, channelType string) ([]string, error) {
	// Validate inputs
	if err := g.validateInputs(storyContent, channelType); err != nil {
		return nil, err
	}

	config, exists := g.channelConfigs[channelType]
	if !exists {
		return nil, errors.NewValidationError(
			errors.CodeValidationError,
			"unsupported channel type",
			map[string]interface{}{"channel_type": channelType},
		)
	}

	// Start with base tags
	tags := make([]string, len(config.BaseTags))
	copy(tags, config.BaseTags)

	// Extract content-specific tags
	contentTags := g.extractContentTags(storyContent, channelType)

	// Merge tags and remove duplicates
	tagSet := make(map[string]bool)
	for _, tag := range tags {
		tagSet[tag] = true
	}

	for _, tag := range contentTags {
		if !tagSet[tag] && len(tagSet) < 15 { // YouTube tag limit
			tagSet[tag] = true
		}
	}

	// Convert back to slice
	finalTags := make([]string, 0, len(tagSet))
	for tag := range tagSet {
		finalTags = append(finalTags, tag)
	}

	return finalTags, nil
}

// validateInputs validates common inputs for metadata generation
func (g *MetadataGenerator) validateInputs(storyContent string, channelType string) error {
	if strings.TrimSpace(storyContent) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"story content is required",
			map[string]interface{}{"story_content": storyContent},
		)
	}

	if len(storyContent) < 20 {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"story content too short",
			map[string]interface{}{
				"story_length": len(storyContent),
				"min_length":   20,
			},
		)
	}

	if strings.TrimSpace(channelType) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"channel type is required",
			map[string]interface{}{"channel_type": channelType},
		)
	}

	return nil
}

// extractKeywords extracts main keywords from story content
func (g *MetadataGenerator) extractKeywords(storyContent string, channelType string) []string {
	var keywords []string

	// Channel-specific keyword patterns
	patterns := map[string][]string{
		"fairy_tale": {"공주", "왕자", "마법", "왕국", "모험", "친구", "용감", "착한"},
		"horror":     {"저택", "밤", "귀신", "미스터리", "무서운", "어둠", "비밀", "공포"},
		"romance":    {"사랑", "만남", "카페", "연인", "마음", "감동", "운명", "달콤한"},
	}

	if channelPatterns, exists := patterns[channelType]; exists {
		for _, pattern := range channelPatterns {
			if strings.Contains(storyContent, pattern) {
				keywords = append(keywords, pattern)
			}
		}
	}

	// If no specific keywords found, extract general nouns
	if len(keywords) == 0 {
		words := strings.Fields(storyContent)
		for _, word := range words {
			if len(word) > 2 && g.isNoun(word) {
				keywords = append(keywords, word)
				break
			}
		}
	}

	return keywords
}

// extractKeyPoints extracts key story points for description
func (g *MetadataGenerator) extractKeyPoints(storyContent string, channelType string) []string {
	sentences := g.splitIntoSentences(storyContent)
	var points []string

	// Extract meaningful sentences
	for _, sentence := range sentences {
		if len(sentence) > 10 && g.isMeaningfulSentence(sentence) {
			points = append(points, g.summarizeSentence(sentence))
			if len(points) >= 4 {
				break
			}
		}
	}

	return points
}

// generateHookLine generates an engaging hook line
func (g *MetadataGenerator) generateHookLine(storyContent string, channelType string) string {
	hooks := map[string][]string{
		"fairy_tale": {
			"아름다운 공주와 마법사의 감동적인 이야기를 만나보세요!",
			"따뜻한 마음을 가진 주인공의 특별한 모험!",
			"마법과 우정이 가득한 환상적인 이야기!",
		},
		"horror": {
			"매일 밤 들려오는 발소리의 정체는?",
			"상상하지 못했던 무서운 진실이 밝혀진다!",
			"깊은 밤, 홀로 남겨진 당신이라면?",
		},
		"romance": {
			"하나의 우산 아래에서 시작된 아름다운 사랑 이야기",
			"운명처럼 다가온 특별한 만남의 순간",
			"평범한 일상에서 시작된 달콤한 로맨스",
		},
	}

	if hookList, exists := hooks[channelType]; exists {
		return hookList[0] // Use first hook for consistency
	}

	return "특별한 이야기를 만나보세요!"
}

// extractMainTheme extracts the main theme for hashtags
func (g *MetadataGenerator) extractMainTheme(storyContent string, channelType string) string {
	themes := map[string]string{
		"fairy_tale": "동화",
		"horror":     "공포",
		"romance":    "로맨스",
	}

	if theme, exists := themes[channelType]; exists {
		return theme
	}

	return "이야기"
}

// extractContentTags extracts tags specific to content
func (g *MetadataGenerator) extractContentTags(storyContent string, channelType string) []string {
	var contentTags []string

	// Extract based on content analysis
	keywords := g.extractKeywords(storyContent, channelType)
	for _, keyword := range keywords {
		if len(keyword) > 1 {
			contentTags = append(contentTags, keyword)
		}
	}

	return contentTags
}

// Helper functions

func (g *MetadataGenerator) splitIntoSentences(text string) []string {
	re := regexp.MustCompile(`[.!?]+\s*`)
	sentences := re.Split(text, -1)

	var result []string
	for _, sentence := range sentences {
		sentence = strings.TrimSpace(sentence)
		if sentence != "" {
			result = append(result, sentence)
		}
	}

	return result
}

func (g *MetadataGenerator) isMeaningfulSentence(sentence string) bool {
	// Filter out very short or simple sentences
	return len(sentence) > 10 && strings.Contains(sentence, " ")
}

func (g *MetadataGenerator) summarizeSentence(sentence string) string {
	// Simple summarization - take first meaningful part
	if len(sentence) > 50 {
		words := strings.Fields(sentence)
		if len(words) > 5 {
			return strings.Join(words[:5], " ") + "..."
		}
	}
	return sentence
}

func (g *MetadataGenerator) isNoun(word string) bool {
	// Simple heuristic for Korean nouns (this could be enhanced with NLP)
	if len(word) < 2 {
		return false
	}

	// Check for common noun endings in Korean
	nounEndings := []string{"이", "가", "을", "를", "의", "에", "로", "와", "과"}
	for _, ending := range nounEndings {
		if strings.HasSuffix(word, ending) {
			return true
		}
	}

	return true // Default to true for unknown words
}
