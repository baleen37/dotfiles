package adapters

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
	"unicode/utf8"

	"gopkg.in/yaml.v3"

	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/youtube/ports"
	"ssulmeta-go/pkg/errors"
	"ssulmeta-go/pkg/logger"
)

// EnhancedMetadataGenerator implements the MetadataGenerator interface with OpenAI integration
type EnhancedMetadataGenerator struct {
	openAIConfig   *config.OpenAIConfig
	httpClient     *http.Client
	channelConfigs map[string]*ChannelMetadataConfig
	useMock        bool
}

// ChannelMetadataConfig represents the YouTube metadata configuration from channel YAML files
type ChannelMetadataConfig struct {
	Name        string              `yaml:"name"`
	YouTubeInfo YouTubeMetadataInfo `yaml:"youtube"`
	SceneStyle  string              `yaml:"scene_style"`
}

type YouTubeMetadataInfo struct {
	Metadata YouTubeMetadata `yaml:"metadata"`
}

type YouTubeMetadata struct {
	TitleTemplates      []string            `yaml:"title_templates"`
	DescriptionTemplate string              `yaml:"description_template"`
	HookLines           map[string]string   `yaml:"hook_lines"`
	BaseTags            []string            `yaml:"base_tags"`
	ContentTags         ContentTagConfig    `yaml:"content_tags"`
	Constraints         MetadataConstraints `yaml:"constraints"`
	CategoryID          string              `yaml:"category_id"`
	DefaultLanguage     string              `yaml:"default_language"`
	Privacy             string              `yaml:"privacy"`
}

type ContentTagConfig struct {
	Patterns map[string][]string `yaml:"patterns"`
}

type MetadataConstraints struct {
	TitleMaxLength       int `yaml:"title_max_length"`
	DescriptionMaxLength int `yaml:"description_max_length"`
	MaxTags              int `yaml:"max_tags"`
	TagTotalMaxLength    int `yaml:"tag_total_max_length"`
}

// OpenAI API structures for metadata generation
type openAIMetadataRequest struct {
	Model       string          `json:"model"`
	Messages    []openAIMessage `json:"messages"`
	MaxTokens   int             `json:"max_tokens"`
	Temperature float64         `json:"temperature"`
}

type openAIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type openAIMetadataResponse struct {
	Choices []openAIChoice `json:"choices"`
	Usage   openAIUsage    `json:"usage"`
}

type openAIChoice struct {
	Message openAIMessage `json:"message"`
}

type openAIUsage struct {
	TotalTokens int `json:"total_tokens"`
}

// ContentAnalysis represents the result of AI-powered content analysis
type ContentAnalysis struct {
	MainTheme      string   `json:"main_theme"`
	KeyCharacters  []string `json:"key_characters"`
	EmotionalTone  string   `json:"emotional_tone"`
	KeyMoments     []string `json:"key_moments"`
	SEOKeywords    []string `json:"seo_keywords"`
	ContentType    string   `json:"content_type"`
	HookSuggestion string   `json:"hook_suggestion"`
}

// NewEnhancedMetadataGenerator creates a new enhanced metadata generator with OpenAI integration
func NewEnhancedMetadataGenerator(openAIConfig *config.OpenAIConfig, useMock bool) (*EnhancedMetadataGenerator, error) {
	generator := &EnhancedMetadataGenerator{
		openAIConfig:   openAIConfig,
		httpClient:     &http.Client{Timeout: 30 * time.Second},
		channelConfigs: make(map[string]*ChannelMetadataConfig),
		useMock:        useMock,
	}

	// Load channel configurations
	if err := generator.loadChannelConfigs(); err != nil {
		return nil, errors.Wrap(err, errors.ErrorTypeInternal, errors.CodeConfigParseError, "failed to load channel configurations")
	}

	return generator, nil
}

// loadChannelConfigs loads channel metadata configurations from YAML files
func (g *EnhancedMetadataGenerator) loadChannelConfigs() error {
	// Try different possible paths for the config directory
	possiblePaths := []string{
		"configs/channels",
		"../../../configs/channels",
		"../../configs/channels",
	}

	var configDir string
	for _, path := range possiblePaths {
		if _, err := os.Stat(path); err == nil {
			configDir = path
			break
		}
	}

	if configDir == "" {
		return fmt.Errorf("could not find configs/channels directory")
	}

	channels := []string{"fairy_tale", "horror", "romance"}

	for _, channel := range channels {
		configPath := filepath.Join(configDir, channel+".yaml")

		data, err := os.ReadFile(configPath)
		if err != nil {
			return fmt.Errorf("failed to read config file %s: %w", configPath, err)
		}

		var config ChannelMetadataConfig
		if err := yaml.Unmarshal(data, &config); err != nil {
			return fmt.Errorf("failed to parse config file %s: %w", configPath, err)
		}

		g.channelConfigs[channel] = &config
	}

	return nil
}

// GenerateMetadata generates complete metadata from story content using OpenAI analysis
func (g *EnhancedMetadataGenerator) GenerateMetadata(ctx context.Context, storyContent string, channelType string) (*ports.Metadata, error) {
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

	// Analyze content using OpenAI (or mock)
	analysis, err := g.analyzeContent(ctx, storyContent, channelType)
	if err != nil {
		logger.Warn("OpenAI analysis failed, falling back to basic generation", "error", err)
		// Fall back to basic generation if OpenAI fails
		return g.generateBasicMetadata(storyContent, channelType, config)
	}

	// Generate enhanced metadata using AI analysis
	title, err := g.generateEnhancedTitle(analysis, config)
	if err != nil {
		return nil, err
	}

	description, err := g.generateEnhancedDescription(analysis, config)
	if err != nil {
		return nil, err
	}

	tags, err := g.generateEnhancedTags(analysis, config)
	if err != nil {
		return nil, err
	}

	// Create metadata object
	metadata := &ports.Metadata{
		Title:           title,
		Description:     description,
		Tags:            tags,
		CategoryID:      config.YouTubeInfo.Metadata.CategoryID,
		DefaultLanguage: config.YouTubeInfo.Metadata.DefaultLanguage,
		Privacy:         config.YouTubeInfo.Metadata.Privacy,
	}

	// Validate constraints
	if err := g.validateMetadataConstraints(metadata, config); err != nil {
		return nil, err
	}

	return metadata, nil
}

// analyzeContent uses OpenAI to analyze story content for intelligent metadata generation
func (g *EnhancedMetadataGenerator) analyzeContent(ctx context.Context, storyContent string, channelType string) (*ContentAnalysis, error) {
	if g.useMock || os.Getenv("SKIP_OPENAI_API") == "true" {
		return g.getMockAnalysis(storyContent, channelType), nil
	}

	// Build OpenAI prompt for content analysis
	systemPrompt := g.buildAnalysisSystemPrompt(channelType)
	userPrompt := g.buildAnalysisUserPrompt(storyContent, channelType)

	// Prepare OpenAI request
	reqBody := openAIMetadataRequest{
		Model: g.openAIConfig.Model,
		Messages: []openAIMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: userPrompt},
		},
		MaxTokens:   500,
		Temperature: 0.3, // Lower temperature for more consistent analysis
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return nil, errors.Wrap(err, errors.ErrorTypeInternal, errors.CodeInternalError, "failed to marshal OpenAI request")
	}

	// Create HTTP request
	req, err := http.NewRequestWithContext(ctx, "POST", g.openAIConfig.BaseURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, errors.Wrap(err, errors.ErrorTypeInternal, errors.CodeInternalError, "failed to create HTTP request")
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", g.openAIConfig.APIKey))

	// Send request
	resp, err := g.httpClient.Do(req)
	if err != nil {
		return nil, errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeOpenAIAPIError, "failed to send request to OpenAI")
	}
	defer func() {
		if err := resp.Body.Close(); err != nil {
			logger.Warn("Failed to close response body", "error", err)
		}
	}()

	// Check status code
	if resp.StatusCode != http.StatusOK {
		return nil, errors.New(errors.ErrorTypeExternal, errors.CodeOpenAIAPIError, "OpenAI API error").
			WithDetails("statusCode", resp.StatusCode)
	}

	// Parse response
	var openAIResp openAIMetadataResponse
	if err := json.NewDecoder(resp.Body).Decode(&openAIResp); err != nil {
		return nil, errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeOpenAIAPIError, "failed to decode OpenAI response")
	}

	if len(openAIResp.Choices) == 0 {
		return nil, errors.New(errors.ErrorTypeExternal, errors.CodeOpenAIAPIError, "no choices returned from OpenAI")
	}

	// Parse analysis result
	analysisContent := openAIResp.Choices[0].Message.Content
	analysis, err := g.parseAnalysisResult(analysisContent)
	if err != nil {
		logger.Warn("Failed to parse OpenAI analysis, using fallback", "error", err, "content", analysisContent)
		return g.getMockAnalysis(storyContent, channelType), nil
	}

	logger.Info("Content analysis completed",
		"channel_type", channelType,
		"main_theme", analysis.MainTheme,
		"emotional_tone", analysis.EmotionalTone,
		"tokens_used", openAIResp.Usage.TotalTokens,
	)

	return analysis, nil
}

// buildAnalysisSystemPrompt creates system prompt for content analysis
func (g *EnhancedMetadataGenerator) buildAnalysisSystemPrompt(channelType string) string {
	basePrompt := `당신은 YouTube Shorts 콘텐츠 분석 전문가입니다. 한국어 스토리를 분석하여 YouTube 메타데이터 생성에 필요한 정보를 추출합니다.

다음 형식의 JSON으로 응답해주세요:
{
  "main_theme": "주요 테마",
  "key_characters": ["등장인물1", "등장인물2"],
  "emotional_tone": "감정적 톤",
  "key_moments": ["핵심 순간1", "핵심 순간2"],
  "seo_keywords": ["SEO키워드1", "SEO키워드2"],
  "content_type": "콘텐츠 유형",
  "hook_suggestion": "시청자를 끌어들일 훅 라인"
}`

	channelSpecific := map[string]string{
		"fairy_tale": "동화 채널이므로 교육적 가치, 교훈, 캐릭터의 성장을 중심으로 분석하세요.",
		"horror":     "공포 채널이므로 긴장감, 미스터리 요소, 반전을 중심으로 분석하세요.",
		"romance":    "로맨스 채널이므로 감정적 연결, 로맨틱한 순간, 관계 발전을 중심으로 분석하세요.",
	}

	if specific, exists := channelSpecific[channelType]; exists {
		basePrompt += "\n\n" + specific
	}

	return basePrompt
}

// buildAnalysisUserPrompt creates user prompt for content analysis
func (g *EnhancedMetadataGenerator) buildAnalysisUserPrompt(storyContent string, channelType string) string {
	return fmt.Sprintf("다음 %s 스토리를 분석해주세요:\n\n%s", channelType, storyContent)
}

// parseAnalysisResult parses OpenAI analysis result from JSON
func (g *EnhancedMetadataGenerator) parseAnalysisResult(content string) (*ContentAnalysis, error) {
	// Extract JSON from the response (in case there's extra text)
	jsonStart := strings.Index(content, "{")
	jsonEnd := strings.LastIndex(content, "}") + 1

	if jsonStart == -1 || jsonEnd <= jsonStart {
		return nil, fmt.Errorf("no valid JSON found in response")
	}

	jsonContent := content[jsonStart:jsonEnd]

	var analysis ContentAnalysis
	if err := json.Unmarshal([]byte(jsonContent), &analysis); err != nil {
		return nil, fmt.Errorf("failed to parse analysis JSON: %w", err)
	}

	return &analysis, nil
}

// getMockAnalysis returns mock analysis for testing/fallback
func (g *EnhancedMetadataGenerator) getMockAnalysis(storyContent string, channelType string) *ContentAnalysis {
	mockData := map[string]*ContentAnalysis{
		"fairy_tale": {
			MainTheme:      "우정과 용기",
			KeyCharacters:  []string{"공주", "마법사"},
			EmotionalTone:  "따뜻하고 희망적",
			KeyMoments:     []string{"마법의 발견", "문제 해결", "행복한 결말"},
			SEOKeywords:    []string{"동화", "교육", "아이들", "마법"},
			ContentType:    "adventure",
			HookSuggestion: "마법과 용기가 가득한 감동적인 이야기를 만나보세요!",
		},
		"horror": {
			MainTheme:      "미스터리와 긴장감",
			KeyCharacters:  []string{"주인공", "의문의 존재"},
			EmotionalTone:  "긴장감 있고 오싹한",
			KeyMoments:     []string{"이상한 현상 발견", "진실 추적", "충격적 반전"},
			SEOKeywords:    []string{"공포", "미스터리", "호러", "긴장감"},
			ContentType:    "mystery",
			HookSuggestion: "마지막까지 예측할 수 없는 오싹한 이야기!",
		},
		"romance": {
			MainTheme:      "사랑과 만남",
			KeyCharacters:  []string{"남자 주인공", "여자 주인공"},
			EmotionalTone:  "달콤하고 감동적",
			KeyMoments:     []string{"첫 만남", "감정 발전", "로맨틱한 결말"},
			SEOKeywords:    []string{"로맨스", "사랑", "만남", "감동"},
			ContentType:    "first_love",
			HookSuggestion: "설렘 가득한 달콤한 로맨스 이야기입니다!",
		},
	}

	if mock, exists := mockData[channelType]; exists {
		return mock
	}

	return mockData["fairy_tale"] // Default fallback
}

// generateEnhancedTitle generates SEO-optimized titles using AI analysis
func (g *EnhancedMetadataGenerator) generateEnhancedTitle(analysis *ContentAnalysis, config *ChannelMetadataConfig) (string, error) {
	templates := config.YouTubeInfo.Metadata.TitleTemplates
	if len(templates) == 0 {
		return "", errors.NewValidationError(
			errors.CodeValidationError,
			"no title templates found for channel",
			nil,
		)
	}

	// Choose template based on content type or randomly
	template := templates[0] // Default to first template
	if len(templates) > 1 {
		template = templates[rand.Intn(len(templates))]
	}

	// Extract title from story content or use main theme
	title := g.extractTitleFromAnalysis(analysis)

	// Replace placeholder with extracted title
	generatedTitle := strings.ReplaceAll(template, "{title}", title)

	// Ensure title length is within constraints
	maxLength := config.YouTubeInfo.Metadata.Constraints.TitleMaxLength
	if utf8.RuneCountInString(generatedTitle) > maxLength {
		// Truncate gracefully
		runes := []rune(generatedTitle)
		if len(runes) > maxLength-3 {
			generatedTitle = string(runes[:maxLength-3]) + "..."
		}
	}

	// Validate title doesn't contain problematic characters
	if err := g.validateTextContent(generatedTitle, "title"); err != nil {
		return "", err
	}

	return generatedTitle, nil
}

// generateEnhancedDescription generates descriptions using AI analysis and templates
func (g *EnhancedMetadataGenerator) generateEnhancedDescription(analysis *ContentAnalysis, config *ChannelMetadataConfig) (string, error) {
	template := config.YouTubeInfo.Metadata.DescriptionTemplate
	if template == "" {
		return "", errors.NewValidationError(
			errors.CodeValidationError,
			"no description template found for channel",
			nil,
		)
	}

	// Get hook line based on content type
	hookLine := g.getHookLine(analysis, config)

	// Generate summary from key moments
	summary := g.generateSummaryFromAnalysis(analysis)

	// Extract specific content based on channel type
	var specificContent string
	switch {
	case strings.Contains(template, "{lesson_points}"):
		specificContent = strings.Join(analysis.KeyMoments, ", ")
	case strings.Contains(template, "{key_points}"):
		specificContent = strings.Join(analysis.KeyMoments, ", ")
	case strings.Contains(template, "{romantic_moments}"):
		specificContent = strings.Join(analysis.KeyMoments, ", ")
	}

	// Additional content based on template placeholders
	var additionalContent string
	switch {
	case strings.Contains(template, "{characters}"):
		additionalContent = strings.Join(analysis.KeyCharacters, ", ")
	case strings.Contains(template, "{mystery_elements}"):
		additionalContent = strings.Join(analysis.SEOKeywords, ", ")
	case strings.Contains(template, "{emotional_points}"):
		additionalContent = analysis.EmotionalTone
	}

	// Replace all placeholders
	description := template
	description = strings.ReplaceAll(description, "{hook_line}", hookLine)
	description = strings.ReplaceAll(description, "{summary}", summary)
	description = strings.ReplaceAll(description, "{lesson_points}", specificContent)
	description = strings.ReplaceAll(description, "{key_points}", specificContent)
	description = strings.ReplaceAll(description, "{romantic_moments}", specificContent)
	description = strings.ReplaceAll(description, "{characters}", additionalContent)
	description = strings.ReplaceAll(description, "{mystery_elements}", additionalContent)
	description = strings.ReplaceAll(description, "{emotional_points}", additionalContent)

	// Ensure description length is within constraints
	maxLength := config.YouTubeInfo.Metadata.Constraints.DescriptionMaxLength
	if utf8.RuneCountInString(description) > maxLength {
		runes := []rune(description)
		if len(runes) > maxLength-3 {
			description = string(runes[:maxLength-3]) + "..."
		}
	}

	// Validate description content
	if err := g.validateTextContent(description, "description"); err != nil {
		return "", err
	}

	return description, nil
}

// generateEnhancedTags generates intelligent tags using AI analysis
func (g *EnhancedMetadataGenerator) generateEnhancedTags(analysis *ContentAnalysis, config *ChannelMetadataConfig) ([]string, error) {
	tags := make([]string, 0, config.YouTubeInfo.Metadata.Constraints.MaxTags)
	tagSet := make(map[string]bool)

	// Add base tags
	for _, tag := range config.YouTubeInfo.Metadata.BaseTags {
		if !tagSet[tag] && len(tags) < config.YouTubeInfo.Metadata.Constraints.MaxTags {
			tags = append(tags, tag)
			tagSet[tag] = true
		}
	}

	// Add SEO keywords from analysis
	for _, keyword := range analysis.SEOKeywords {
		if !tagSet[keyword] && len(tags) < config.YouTubeInfo.Metadata.Constraints.MaxTags {
			tags = append(tags, keyword)
			tagSet[keyword] = true
		}
	}

	// Add content-specific tags based on patterns
	contentTags := g.extractContentSpecificTags(analysis, config)
	for _, tag := range contentTags {
		if !tagSet[tag] && len(tags) < config.YouTubeInfo.Metadata.Constraints.MaxTags {
			tags = append(tags, tag)
			tagSet[tag] = true
		}
	}

	// Validate total tag length
	totalLength := 0
	for _, tag := range tags {
		totalLength += utf8.RuneCountInString(tag)
	}

	if totalLength > config.YouTubeInfo.Metadata.Constraints.TagTotalMaxLength {
		// Remove tags from the end until we're under the limit
		for len(tags) > 0 && totalLength > config.YouTubeInfo.Metadata.Constraints.TagTotalMaxLength {
			removedTag := tags[len(tags)-1]
			tags = tags[:len(tags)-1]
			totalLength -= utf8.RuneCountInString(removedTag)
		}
	}

	return tags, nil
}

// extractTitleFromAnalysis extracts a suitable title from AI analysis
func (g *EnhancedMetadataGenerator) extractTitleFromAnalysis(analysis *ContentAnalysis) string {
	if analysis.MainTheme != "" {
		return analysis.MainTheme
	}

	if len(analysis.KeyMoments) > 0 {
		return analysis.KeyMoments[0]
	}

	return "특별한 이야기"
}

// getHookLine gets appropriate hook line based on content type
func (g *EnhancedMetadataGenerator) getHookLine(analysis *ContentAnalysis, config *ChannelMetadataConfig) string {
	hookLines := config.YouTubeInfo.Metadata.HookLines

	// Try to get specific hook line for content type
	if hookLine, exists := hookLines[analysis.ContentType]; exists {
		return hookLine
	}

	// Use AI suggestion if available
	if analysis.HookSuggestion != "" {
		return analysis.HookSuggestion
	}

	// Fall back to default
	if defaultHook, exists := hookLines["default"]; exists {
		return defaultHook
	}

	return "흥미진진한 이야기를 만나보세요!"
}

// generateSummaryFromAnalysis creates a summary from AI analysis
func (g *EnhancedMetadataGenerator) generateSummaryFromAnalysis(analysis *ContentAnalysis) string {
	if analysis.MainTheme != "" && len(analysis.KeyCharacters) > 0 {
		return fmt.Sprintf("%s의 %s", strings.Join(analysis.KeyCharacters, "와 "), analysis.MainTheme)
	}

	if analysis.MainTheme != "" {
		return analysis.MainTheme
	}

	if len(analysis.KeyMoments) > 0 {
		return analysis.KeyMoments[0]
	}

	return "특별한 이야기"
}

// extractContentSpecificTags extracts tags based on content patterns
func (g *EnhancedMetadataGenerator) extractContentSpecificTags(analysis *ContentAnalysis, config *ChannelMetadataConfig) []string {
	var tags []string
	patterns := config.YouTubeInfo.Metadata.ContentTags.Patterns

	// Check each pattern category
	for category, patternTags := range patterns {
		// Check if any analysis content matches this category
		if g.matchesCategory(analysis, category) {
			tags = append(tags, patternTags...)
		}
	}

	return tags
}

// matchesCategory checks if analysis content matches a specific category
func (g *EnhancedMetadataGenerator) matchesCategory(analysis *ContentAnalysis, category string) bool {
	allContent := strings.ToLower(analysis.MainTheme + " " +
		strings.Join(analysis.KeyCharacters, " ") + " " +
		strings.Join(analysis.KeyMoments, " ") + " " +
		strings.Join(analysis.SEOKeywords, " "))

	categoryKeywords := map[string][]string{
		"animals":       {"동물", "친구들", "숲속", "자연"},
		"magic":         {"마법", "마법사", "요정", "신비"},
		"adventure":     {"모험", "여행", "탐험", "용기"},
		"family":        {"가족", "엄마", "아빠", "형제"},
		"friendship":    {"친구", "우정", "도움", "협력"},
		"supernatural":  {"귀신", "유령", "초자연", "영혼"},
		"mystery":       {"수수께끼", "미스터리", "비밀", "진실"},
		"psychological": {"심리", "정신", "환상", "착각"},
		"location":      {"저택", "학교", "병원", "숲"},
		"atmosphere":    {"밤", "어둠", "소음", "침묵"},
		"meeting":       {"만남", "첫만남", "소개팅", "우연"},
		"emotions":      {"설렘", "사랑", "마음", "감정"},
		"places":        {"카페", "공원", "도서관", "회사"},
		"moments":       {"고백", "데이트", "프로포즈", "키스"},
		"relationships": {"연인", "커플", "애인", "남자친구", "여자친구"},
	}

	if keywords, exists := categoryKeywords[category]; exists {
		for _, keyword := range keywords {
			if strings.Contains(allContent, keyword) {
				return true
			}
		}
	}

	return false
}

// validateTextContent validates text for special characters and content guidelines
func (g *EnhancedMetadataGenerator) validateTextContent(text string, contentType string) error {
	// Check for prohibited characters
	prohibitedChars := []string{"<", ">", "[", "]", "{", "}"}
	for _, char := range prohibitedChars {
		if strings.Contains(text, char) {
			return errors.NewValidationError(
				errors.CodeValidationError,
				fmt.Sprintf("%s contains prohibited character: %s", contentType, char),
				map[string]interface{}{
					"content_type":    contentType,
					"prohibited_char": char,
					"text":            text,
				},
			)
		}
	}

	// Check for excessive special characters
	specialCharCount := 0
	for _, r := range text {
		// Check if character is NOT in allowed set (applying De Morgan's law for clarity)
		isNotAllowed := (r < 'a' || r > 'z') && (r < 'A' || r > 'Z') &&
			(r < '0' || r > '9') && (r < 0xAC00 || r > 0xD7A3) && // Korean
			r != ' ' && r != '.' && r != '!' && r != '?' && r != ',' &&
			r != ':' && r != ';' && r != '-' && r != '_'
		if isNotAllowed {
			specialCharCount++
		}
	}

	// Allow reasonable amount of emojis and special characters
	maxSpecialChars := len(text) / 10 // 10% of content can be special characters
	if maxSpecialChars < 5 {
		maxSpecialChars = 5 // Minimum allowance
	}

	if specialCharCount > maxSpecialChars {
		return errors.NewValidationError(
			errors.CodeValidationError,
			fmt.Sprintf("%s contains too many special characters", contentType),
			map[string]interface{}{
				"content_type":       contentType,
				"special_char_count": specialCharCount,
				"max_allowed":        maxSpecialChars,
			},
		)
	}

	return nil
}

// validateMetadataConstraints validates all metadata against channel constraints
func (g *EnhancedMetadataGenerator) validateMetadataConstraints(metadata *ports.Metadata, config *ChannelMetadataConfig) error {
	constraints := config.YouTubeInfo.Metadata.Constraints

	// Title length check
	if utf8.RuneCountInString(metadata.Title) > constraints.TitleMaxLength {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"title exceeds maximum length",
			map[string]interface{}{
				"title_length": utf8.RuneCountInString(metadata.Title),
				"max_length":   constraints.TitleMaxLength,
			},
		)
	}

	// Description length check
	if utf8.RuneCountInString(metadata.Description) > constraints.DescriptionMaxLength {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"description exceeds maximum length",
			map[string]interface{}{
				"description_length": utf8.RuneCountInString(metadata.Description),
				"max_length":         constraints.DescriptionMaxLength,
			},
		)
	}

	// Tags count check
	if len(metadata.Tags) > constraints.MaxTags {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"too many tags",
			map[string]interface{}{
				"tag_count": len(metadata.Tags),
				"max_tags":  constraints.MaxTags,
			},
		)
	}

	// Total tag length check
	totalTagLength := 0
	for _, tag := range metadata.Tags {
		totalTagLength += utf8.RuneCountInString(tag)
	}

	if totalTagLength > constraints.TagTotalMaxLength {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"total tag length exceeds limit",
			map[string]interface{}{
				"total_tag_length": totalTagLength,
				"max_length":       constraints.TagTotalMaxLength,
			},
		)
	}

	return nil
}

// validateInputs validates common inputs for metadata generation
func (g *EnhancedMetadataGenerator) validateInputs(storyContent string, channelType string) error {
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

// generateBasicMetadata provides fallback metadata generation without OpenAI
func (g *EnhancedMetadataGenerator) generateBasicMetadata(storyContent string, channelType string, config *ChannelMetadataConfig) (*ports.Metadata, error) {
	// Use mock analysis as fallback when OpenAI is unavailable
	analysis := g.getMockAnalysis(storyContent, channelType)

	// Generate metadata using the mock analysis
	title, err := g.generateEnhancedTitle(analysis, config)
	if err != nil {
		return nil, err
	}

	description, err := g.generateEnhancedDescription(analysis, config)
	if err != nil {
		return nil, err
	}

	tags, err := g.generateEnhancedTags(analysis, config)
	if err != nil {
		return nil, err
	}

	// Create metadata object
	metadata := &ports.Metadata{
		Title:           title,
		Description:     description,
		Tags:            tags,
		CategoryID:      config.YouTubeInfo.Metadata.CategoryID,
		DefaultLanguage: config.YouTubeInfo.Metadata.DefaultLanguage,
		Privacy:         config.YouTubeInfo.Metadata.Privacy,
	}

	// Validate constraints
	if err := g.validateMetadataConstraints(metadata, config); err != nil {
		return nil, err
	}

	return metadata, nil
}

// Interface implementations for compatibility

// GenerateTitle generates a compelling video title
func (g *EnhancedMetadataGenerator) GenerateTitle(ctx context.Context, storyContent string, channelType string) (string, error) {
	metadata, err := g.GenerateMetadata(ctx, storyContent, channelType)
	if err != nil {
		return "", err
	}
	return metadata.Title, nil
}

// GenerateDescription generates a video description
func (g *EnhancedMetadataGenerator) GenerateDescription(ctx context.Context, storyContent string, title string, channelType string) (string, error) {
	metadata, err := g.GenerateMetadata(ctx, storyContent, channelType)
	if err != nil {
		return "", err
	}
	return metadata.Description, nil
}

// GenerateTags generates relevant tags for the video
func (g *EnhancedMetadataGenerator) GenerateTags(ctx context.Context, storyContent string, channelType string) ([]string, error) {
	metadata, err := g.GenerateMetadata(ctx, storyContent, channelType)
	if err != nil {
		return nil, err
	}
	return metadata.Tags, nil
}
