package story

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"ssulmeta-go/internal/config"
	"ssulmeta-go/pkg/logger"
	"ssulmeta-go/pkg/models"
	"time"
)

// OpenAIGenerator implements Generator using OpenAI API
type OpenAIGenerator struct {
	apiKey      string
	model       string
	maxTokens   int
	temperature float64
	httpClient  *http.Client
}

// NewOpenAIGenerator creates a new OpenAI generator
func NewOpenAIGenerator(cfg *config.OpenAIConfig) *OpenAIGenerator {
	return &OpenAIGenerator{
		apiKey:      cfg.APIKey,
		model:       cfg.Model,
		maxTokens:   cfg.MaxTokens,
		temperature: cfg.Temperature,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
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
	prompt := g.buildPrompt(channel)

	// Prepare request
	reqBody := openAIRequest{
		Model: g.model,
		Messages: []message{
			{
				Role:    "system",
				Content: "당신은 YouTube Shorts를 위한 1분 분량의 짧은 스토리를 작성하는 전문 작가입니다. 270-300자 내외로 작성해주세요.",
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
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	// Create HTTP request
	req, err := http.NewRequestWithContext(ctx, "POST", "https://api.openai.com/v1/chat/completions", bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", g.apiKey))

	// Send request
	resp, err := g.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer func() {
		if closeErr := resp.Body.Close(); closeErr != nil {
			slog.Warn("Failed to close response body", "error", closeErr)
		}
	}()

	// Check status code
	if resp.StatusCode != http.StatusOK {
		var errorResp map[string]interface{}
		if decodeErr := json.NewDecoder(resp.Body).Decode(&errorResp); decodeErr != nil {
			return nil, fmt.Errorf("OpenAI API error (status %d): failed to decode error response: %w", resp.StatusCode, decodeErr)
		}
		return nil, fmt.Errorf("OpenAI API error (status %d): %v", resp.StatusCode, errorResp)
	}

	// Parse response
	var openAIResp openAIResponse
	if err := json.NewDecoder(resp.Body).Decode(&openAIResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	if len(openAIResp.Choices) == 0 {
		return nil, fmt.Errorf("no choices returned from OpenAI")
	}

	// Extract story content
	content := openAIResp.Choices[0].Message.Content

	// Parse the structured response
	story, err := g.parseStoryResponse(content)
	if err != nil {
		return nil, fmt.Errorf("failed to parse story response: %w", err)
	}

	logger.Info("story generated successfully",
		"title", story.Title,
		"length", len(story.Content),
		"tokens_used", openAIResp.Usage.TotalTokens,
	)

	return story, nil
}

// buildPrompt builds the prompt for story generation
func (g *OpenAIGenerator) buildPrompt(channel *models.Channel) string {
	basePrompt := `다음 형식으로 YouTube Shorts용 1분 짧은 이야기를 만들어주세요:

제목: [이야기 제목]
내용: [270-300자의 이야기 내용]

이야기는 시작, 중간, 끝이 명확해야 하고, 시각적으로 표현하기 좋은 장면들이 포함되어야 합니다.`

	if channel.PromptTemplate != "" {
		return channel.PromptTemplate
	}

	return basePrompt
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
		story.Title = "무제"
		story.Content = content
	}

	return story, nil
}

// DivideIntoScenes divides the story into scenes using AI
func (g *OpenAIGenerator) DivideIntoScenes(ctx context.Context, story *models.Story) error {
	// TODO: Implement AI-based scene division
	// For now, we'll implement a simple sentence-based division

	// This is a placeholder implementation
	return g.simpleDivideScenes(story)
}

// simpleDivideScenes provides a simple implementation of scene division
func (g *OpenAIGenerator) simpleDivideScenes(story *models.Story) error {
	// This is a simplified version - in production, use AI for better results
	sentences := bytes.Split([]byte(story.Content), []byte(". "))

	scenes := make([]models.Scene, 0)
	sceneText := ""
	sceneNum := 1

	for i, sentence := range sentences {
		sceneText += string(sentence) + ". "

		// Create a scene every 2-3 sentences or at the end
		if (i+1)%2 == 0 || i == len(sentences)-1 {
			if sceneText != "" {
				scene := models.Scene{
					Number:      sceneNum,
					Description: sceneText,
					ImagePrompt: fmt.Sprintf("Korean story illustration: %s, vertical format, soft colors", sceneText),
					Duration:    float64(len(sceneText)) / 30.0, // Rough estimate
				}
				scenes = append(scenes, scene)
				sceneNum++
				sceneText = ""
			}
		}
	}

	story.Scenes = scenes
	return nil
}
