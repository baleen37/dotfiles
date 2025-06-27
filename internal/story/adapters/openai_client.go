package adapters

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/story/ports"
	"ssulmeta-go/pkg/errors"
	"ssulmeta-go/pkg/logger"
	"ssulmeta-go/pkg/models"
	"strings"
	"time"
)

// OpenAIGenerator implements Generator using OpenAI API
type OpenAIGenerator struct {
	apiKey        string
	baseURL       string
	model         string
	maxTokens     int
	temperature   float64
	systemPrompt  string
	storyConfig   *config.StoryConfig
	httpClient    *http.Client
	sceneSplitter *SceneSplitter
}

// Ensure OpenAIGenerator implements the Generator interface
var _ ports.Generator = (*OpenAIGenerator)(nil)

// NewOpenAIGenerator creates a new OpenAI generator
func NewOpenAIGenerator(cfg *config.OpenAIConfig, storyCfg *config.StoryConfig, httpTimeout time.Duration) *OpenAIGenerator {
	return &OpenAIGenerator{
		apiKey:       cfg.APIKey,
		baseURL:      cfg.BaseURL,
		model:        cfg.Model,
		maxTokens:    cfg.MaxTokens,
		temperature:  cfg.Temperature,
		systemPrompt: cfg.SystemPrompt,
		storyConfig:  storyCfg,
		httpClient: &http.Client{
			Timeout: httpTimeout,
		},
		sceneSplitter: NewSceneSplitter(),
	}
}

// OpenAI API request/response structures
type openAIRequest struct {
	Model       string    `json:"model"`
	Messages    []message `json:"messages"`
	MaxTokens   int       `json:"max_tokens"`
	Temperature float64   `json:"temperature"`
}

type message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type openAIResponse struct {
	ID      string   `json:"id"`
	Object  string   `json:"object"`
	Created int64    `json:"created"`
	Model   string   `json:"model"`
	Choices []choice `json:"choices"`
	Usage   usage    `json:"usage"`
}

type choice struct {
	Index        int     `json:"index"`
	Message      message `json:"message"`
	FinishReason string  `json:"finish_reason"`
}

type usage struct {
	PromptTokens     int `json:"prompt_tokens"`
	CompletionTokens int `json:"completion_tokens"`
	TotalTokens      int `json:"total_tokens"`
}

// GenerateStory generates a story using OpenAI API
func (g *OpenAIGenerator) GenerateStory(ctx context.Context, channel *models.Channel) (*models.Story, error) {
	startTime := time.Now()
	apiLogger := logger.WithOperation("openai_generate_story")

	prompt := g.buildPrompt(channel)

	apiLogger.Debug("starting story generation",
		"channel_name", channel.Name,
		"model", g.model,
		"max_tokens", g.maxTokens,
	)

	// Prepare request
	reqBody := openAIRequest{
		Model: g.model,
		Messages: []message{
			{
				Role:    "system",
				Content: g.systemPrompt,
			},
			{
				Role:    "user",
				Content: prompt,
			},
		},
		MaxTokens:   g.maxTokens,
		Temperature: g.temperature,
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return nil, errors.Wrap(err, errors.ErrorTypeInternal, errors.CodeInternalError, "failed to marshal request")
	}

	// Create HTTP request
	req, err := http.NewRequestWithContext(ctx, "POST", g.baseURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, errors.Wrap(err, errors.ErrorTypeInternal, errors.CodeInternalError, "failed to create request")
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", g.apiKey))

	// Send request
	resp, err := g.httpClient.Do(req)
	duration := time.Since(startTime)

	if err != nil {
		logger.LogAPICall("openai", "chat/completions", 0, duration, err)
		// Check if it's a timeout
		if ctx.Err() == context.DeadlineExceeded {
			return nil, errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeOpenAITimeout, "OpenAI API request timed out")
		}
		return nil, errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeOpenAIAPIError, "failed to send request to OpenAI")
	}
	defer func() {
		if closeErr := resp.Body.Close(); closeErr != nil {
			logger.Warn("failed to close response body", "error", closeErr)
		}
	}()

	// Check status code
	if resp.StatusCode != http.StatusOK {
		logger.LogAPICall("openai", "chat/completions", resp.StatusCode, duration, nil)

		var errorResp map[string]interface{}
		if decodeErr := json.NewDecoder(resp.Body).Decode(&errorResp); decodeErr != nil {
			apiLogger.Error("failed to decode openai error response",
				"status_code", resp.StatusCode,
				"decode_error", decodeErr,
			)
			return nil, errors.Wrap(decodeErr, errors.ErrorTypeExternal, errors.CodeOpenAIAPIError, "failed to decode OpenAI error response").
				WithDetails("statusCode", resp.StatusCode)
		}

		apiLogger.Error("openai api returned error",
			"status_code", resp.StatusCode,
			"error_response", errorResp,
		)

		// Determine specific error type based on status code
		var errorCode string
		var errorType errors.ErrorType

		switch resp.StatusCode {
		case http.StatusTooManyRequests:
			errorCode = errors.CodeOpenAIRateLimited
			errorType = errors.ErrorTypeExternal
		case http.StatusUnauthorized:
			errorCode = errors.CodeUnauthorized
			errorType = errors.ErrorTypeUnauthorized
		default:
			errorCode = errors.CodeOpenAIAPIError
			errorType = errors.ErrorTypeExternal
		}

		return nil, errors.New(errorType, errorCode, "OpenAI API error").
			WithDetails("statusCode", resp.StatusCode).
			WithDetails("error", errorResp)
	}

	logger.LogAPICall("openai", "chat/completions", resp.StatusCode, duration, nil)

	// Parse response
	var openAIResp openAIResponse
	if err := json.NewDecoder(resp.Body).Decode(&openAIResp); err != nil {
		apiLogger.Error("failed to decode openai response", "error", err)
		return nil, errors.Wrap(err, errors.ErrorTypeExternal, errors.CodeOpenAIAPIError, "failed to decode OpenAI response")
	}

	if len(openAIResp.Choices) == 0 {
		apiLogger.Error("no choices returned from openai")
		return nil, errors.New(errors.ErrorTypeExternal, errors.CodeOpenAIAPIError, "no choices returned from OpenAI")
	}

	// Extract story content
	content := openAIResp.Choices[0].Message.Content

	// Parse the structured response
	story, err := g.parseStoryResponse(content)
	if err != nil {
		apiLogger.Error("failed to parse story response", "error", err, "content", content)
		return nil, errors.Wrap(err, errors.ErrorTypeInternal, errors.CodeStoryGenerationFailed, "failed to parse story response")
	}

	// Log successful operation with structured fields
	totalDuration := time.Since(startTime)
	logger.LogOperation("openai_generate_story", totalDuration, nil)

	apiLogger.Info("story generated successfully",
		"title", story.Title,
		"content_length", len(story.Content),
		"tokens_used", openAIResp.Usage.TotalTokens,
		"prompt_tokens", openAIResp.Usage.PromptTokens,
		"completion_tokens", openAIResp.Usage.CompletionTokens,
		"channel", channel.Name,
	)

	return story, nil
}

// buildPrompt builds the prompt for story generation
func (g *OpenAIGenerator) buildPrompt(channel *models.Channel) string {
	if channel.PromptTemplate != "" {
		return channel.PromptTemplate
	}

	return g.storyConfig.DefaultPrompt
}

// parseStoryResponse parses the structured response from OpenAI
func (g *OpenAIGenerator) parseStoryResponse(content string) (*models.Story, error) {
	// Simple parsing logic - can be improved
	story := &models.Story{}

	// Try to extract title and content
	lines := bytes.Split([]byte(content), []byte("\n"))
	for i, line := range lines {
		if bytes.HasPrefix(line, []byte("제목:")) {
			story.Title = string(bytes.TrimSpace(bytes.TrimPrefix(line, []byte("제목:"))))
		} else if bytes.HasPrefix(line, []byte("내용:")) {
			// Combine all remaining lines as content
			contentLines := lines[i:]
			contentBytes := bytes.Join(contentLines, []byte(" "))
			story.Content = string(bytes.TrimSpace(bytes.TrimPrefix(contentBytes, []byte("내용:"))))
			break
		}
	}

	// Validate
	if story.Title == "" || story.Content == "" {
		// If parsing failed, use the entire content as story
		story.Title = g.storyConfig.DefaultTitle
		story.Content = content
	}

	return story, nil
}

// DivideIntoScenes divides the story into scenes using advanced splitting logic
func (g *OpenAIGenerator) DivideIntoScenes(ctx context.Context, story *models.Story) error {
	// Use the advanced scene splitter
	result, err := g.sceneSplitter.SplitIntoScenes(story)
	if err != nil {
		return fmt.Errorf("failed to split story into scenes: %w", err)
	}

	// Convert SceneContent to models.Scene
	scenes := make([]models.Scene, len(result.Scenes))
	for i, sceneContent := range result.Scenes {
		scenes[i] = models.Scene{
			Number:      sceneContent.Number,
			Description: sceneContent.Text,
			ImagePrompt: g.generateImagePrompt(sceneContent),
			Duration:    g.calculateSceneDuration(sceneContent.Text),
		}
	}

	story.Scenes = scenes

	logger.Info("story divided into scenes successfully",
		"total_scenes", len(scenes),
		"story_title", story.Title,
	)

	return nil
}

// generateImagePrompt creates an optimized image prompt based on scene content
func (g *OpenAIGenerator) generateImagePrompt(scene SceneContent) string {
	basePrompt := fmt.Sprintf("Korean story illustration: %s", scene.Text)

	// Add style modifiers based on scene type
	var styleModifiers string
	switch scene.SceneType {
	case OpeningScene:
		styleModifiers = "opening scene, establishing shot, soft lighting"
	case ActionScene:
		styleModifiers = "dynamic action scene, motion blur, dramatic lighting"
	case DialogueScene:
		styleModifiers = "character interaction, emotional expression, warm lighting"
	case TransitionScene:
		styleModifiers = "transition scene, atmospheric, cinematic"
	case ClimaxScene:
		styleModifiers = "climactic moment, intense drama, high contrast"
	case ClosingScene:
		styleModifiers = "resolution scene, peaceful atmosphere, golden hour"
	default:
		styleModifiers = "narrative scene, balanced composition"
	}

	// Include key phrases if available
	if len(scene.KeyPhrases) > 0 {
		keyPhrasesStr := fmt.Sprintf(", featuring: %s", strings.Join(scene.KeyPhrases, ", "))
		basePrompt += keyPhrasesStr
	}

	return fmt.Sprintf("%s, %s, vertical format 9:16, high quality illustration",
		basePrompt, styleModifiers)
}

// calculateSceneDuration estimates the duration based on text length and scene type
func (g *OpenAIGenerator) calculateSceneDuration(text string) float64 {
	// Base duration calculation (characters per second for Korean reading)
	textLength := float64(len([]rune(text)))

	// Base duration from text length
	baseDuration := textLength / g.storyConfig.ReadingRate

	// Ensure minimum and maximum duration bounds
	if baseDuration < g.storyConfig.MinDuration {
		return g.storyConfig.MinDuration
	}
	if baseDuration > g.storyConfig.MaxDuration {
		return g.storyConfig.MaxDuration
	}

	return baseDuration
}
