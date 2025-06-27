package adapters

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"ssulmeta-go/internal/config"
	"ssulmeta-go/pkg/models"
	"strings"
	"testing"
	"time"
)

// Mock HTTP transport for testing
type mockHTTPTransport struct {
	response   *http.Response
	err        error
	requestLog *http.Request
}

func (m *mockHTTPTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	// Clone request to avoid data races
	m.requestLog = req.Clone(req.Context())
	return m.response, m.err
}

// Helper function to create mock HTTP responses
func createMockResponse(statusCode int, body interface{}) *http.Response {
	var bodyBytes []byte
	if body != nil {
		bodyBytes, _ = json.Marshal(body)
	}
	
	return &http.Response{
		StatusCode: statusCode,
		Body:       io.NopCloser(bytes.NewReader(bodyBytes)),
		Header:     make(http.Header),
	}
}

func TestNewOpenAIGenerator(t *testing.T) {
	cfg := &config.OpenAIConfig{
		APIKey:      "test-api-key",
		Model:       "gpt-3.5-turbo",
		MaxTokens:   500,
		Temperature: 0.7,
	}
	
	generator := NewOpenAIGenerator(cfg)
	
	if generator == nil {
		t.Fatal("NewOpenAIGenerator() returned nil")
	}
	
	if generator.apiKey != cfg.APIKey {
		t.Errorf("apiKey = %v, want %v", generator.apiKey, cfg.APIKey)
	}
	
	if generator.model != cfg.Model {
		t.Errorf("model = %v, want %v", generator.model, cfg.Model)
	}
	
	if generator.maxTokens != cfg.MaxTokens {
		t.Errorf("maxTokens = %v, want %v", generator.maxTokens, cfg.MaxTokens)
	}
	
	if generator.temperature != cfg.Temperature {
		t.Errorf("temperature = %v, want %v", generator.temperature, cfg.Temperature)
	}
	
	if generator.httpClient == nil {
		t.Error("httpClient is nil")
	}
}

func TestOpenAIGenerator_GenerateStory(t *testing.T) {
	tests := []struct {
		name           string
		channel        *models.Channel
		mockResponse   interface{}
		mockStatusCode int
		mockErr        error
		wantErr        bool
		errContains    string
		verify         func(t *testing.T, story *models.Story, mockTransport *mockHTTPTransport)
	}{
		{
			name: "successful story generation",
			channel: &models.Channel{
				ID:   1,
				Name: "Test Channel",
			},
			mockResponse: openAIResponse{
				Choices: []choice{
					{
						Message: message{
							Content: "제목: 테스트 이야기\n내용: " + strings.Repeat("가", 280),
						},
					},
				},
				Usage: usage{
					TotalTokens: 100,
				},
			},
			mockStatusCode: http.StatusOK,
			wantErr:        false,
			verify: func(t *testing.T, story *models.Story, mockTransport *mockHTTPTransport) {
				if story == nil {
					t.Fatal("GenerateStory() returned nil story")
				}
				
				if story.Title != "테스트 이야기" {
					t.Errorf("Title = %v, want 테스트 이야기", story.Title)
				}
				
				if !strings.Contains(story.Content, "가") {
					t.Error("Content doesn't contain expected characters")
				}
			},
		},
		{
			name: "uses channel prompt template",
			channel: &models.Channel{
				ID:             2,
				Name:           "Custom Channel",
				PromptTemplate: "Custom prompt for testing",
			},
			mockResponse: openAIResponse{
				Choices: []choice{
					{
						Message: message{
							Content: "제목: 커스텀 이야기\n내용: 커스텀 내용",
						},
					},
				},
			},
			mockStatusCode: http.StatusOK,
			wantErr:        false,
			verify: func(t *testing.T, story *models.Story, mockTransport *mockHTTPTransport) {
				// Check that custom prompt was used
				body, _ := io.ReadAll(mockTransport.requestLog.Body)
				var reqBody openAIRequest
				json.Unmarshal(body, &reqBody)
				
				if len(reqBody.Messages) < 2 {
					t.Fatal("Request should have at least 2 messages")
				}
				
				if reqBody.Messages[1].Content != "Custom prompt for testing" {
					t.Errorf("User message = %v, want Custom prompt for testing", reqBody.Messages[1].Content)
				}
			},
		},
		{
			name: "handles API error response",
			channel: &models.Channel{
				ID: 3,
			},
			mockResponse: map[string]interface{}{
				"error": map[string]interface{}{
					"message": "Invalid API key",
					"type":    "invalid_request_error",
				},
			},
			mockStatusCode: http.StatusUnauthorized,
			wantErr:        true,
			errContains:    "OpenAI API error",
		},
		{
			name: "handles network error",
			channel: &models.Channel{
				ID: 3,
			},
			mockErr:     fmt.Errorf("network timeout"),
			wantErr:     true,
			errContains: "failed to send request",
		},
		{
			name: "handles empty choices",
			channel: &models.Channel{
				ID: 3,
			},
			mockResponse: openAIResponse{
				Choices: []choice{},
			},
			mockStatusCode: http.StatusOK,
			wantErr:        true,
			errContains:    "no choices returned",
		},
		{
			name: "handles malformed response",
			channel: &models.Channel{
				ID: 3,
			},
			mockResponse:   "not a valid JSON",
			mockStatusCode: http.StatusOK,
			wantErr:        true,
			errContains:    "failed to decode response",
		},
		{
			name: "fallback when parsing fails",
			channel: &models.Channel{
				ID: 3,
			},
			mockResponse: openAIResponse{
				Choices: []choice{
					{
						Message: message{
							Content: "이것은 구조화되지 않은 이야기 내용입니다",
						},
					},
				},
			},
			mockStatusCode: http.StatusOK,
			wantErr:        false,
			verify: func(t *testing.T, story *models.Story, mockTransport *mockHTTPTransport) {
				// When parsing fails, should use default title and full content
				if story.Title != "무제" {
					t.Errorf("Title = %v, want 무제", story.Title)
				}
				
				if story.Content != "이것은 구조화되지 않은 이야기 내용입니다" {
					t.Errorf("Content = %v, want full content", story.Content)
				}
			},
		},
		{
			name: "validates request headers",
			channel: &models.Channel{
				ID: 3,
			},
			mockResponse: openAIResponse{
				Choices: []choice{
					{
						Message: message{
							Content: "제목: 테스트\n내용: 테스트",
						},
					},
				},
			},
			mockStatusCode: http.StatusOK,
			wantErr:        false,
			verify: func(t *testing.T, story *models.Story, mockTransport *mockHTTPTransport) {
				// Check authorization header
				authHeader := mockTransport.requestLog.Header.Get("Authorization")
				if !strings.HasPrefix(authHeader, "Bearer ") {
					t.Errorf("Authorization header = %v, want Bearer prefix", authHeader)
				}
				
				// Check content type
				contentType := mockTransport.requestLog.Header.Get("Content-Type")
				if contentType != "application/json" {
					t.Errorf("Content-Type = %v, want application/json", contentType)
				}
			},
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create mock transport
			mockTransport := &mockHTTPTransport{
				err: tt.mockErr,
			}
			
			if tt.mockResponse != nil {
				mockTransport.response = createMockResponse(tt.mockStatusCode, tt.mockResponse)
			}
			
			// Create generator with mock transport
			generator := &OpenAIGenerator{
				apiKey:      "test-key",
				model:       "gpt-3.5-turbo",
				maxTokens:   500,
				temperature: 0.7,
				httpClient:  &http.Client{Transport: mockTransport},
			}
			
			ctx := context.Background()
			story, err := generator.GenerateStory(ctx, tt.channel)
			
			if (err != nil) != tt.wantErr {
				t.Errorf("GenerateStory() error = %v, wantErr %v", err, tt.wantErr)
			}
			
			if err != nil && tt.errContains != "" && !strings.Contains(err.Error(), tt.errContains) {
				t.Errorf("GenerateStory() error = %v, want error containing %s", err, tt.errContains)
			}
			
			if tt.verify != nil && err == nil {
				tt.verify(t, story, mockTransport)
			}
		})
	}
}

func TestOpenAIGenerator_buildPrompt(t *testing.T) {
	generator := &OpenAIGenerator{}
	
	tests := []struct {
		name     string
		channel  *models.Channel
		expected string
	}{
		{
			name: "uses default prompt when no template",
			channel: &models.Channel{
				ID: 3,
			},
			expected: `다음 형식으로 YouTube Shorts용 1분 짧은 이야기를 만들어주세요:

제목: [이야기 제목]
내용: [270-300자의 이야기 내용]

이야기는 시작, 중간, 끝이 명확해야 하고, 시각적으로 표현하기 좋은 장면들이 포함되어야 합니다.`,
		},
		{
			name: "uses channel prompt template",
			channel: &models.Channel{
				ID:             6,
				PromptTemplate: "Custom prompt template",
			},
			expected: "Custom prompt template",
		},
		{
			name: "empty template falls back to default",
			channel: &models.Channel{
				ID:             4,
				PromptTemplate: "",
			},
			expected: `다음 형식으로 YouTube Shorts용 1분 짧은 이야기를 만들어주세요:

제목: [이야기 제목]
내용: [270-300자의 이야기 내용]

이야기는 시작, 중간, 끝이 명확해야 하고, 시각적으로 표현하기 좋은 장면들이 포함되어야 합니다.`,
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := generator.buildPrompt(tt.channel)
			if result != tt.expected {
				t.Errorf("buildPrompt() = %v, want %v", result, tt.expected)
			}
		})
	}
}

func TestOpenAIGenerator_parseStoryResponse(t *testing.T) {
	generator := &OpenAIGenerator{}
	
	tests := []struct {
		name    string
		content string
		want    *models.Story
	}{
		{
			name: "parses well-formatted response",
			content: `제목: 작은 고양이의 모험
내용: 어느 날, 작은 고양이가 길을 잃었습니다. 고양이는 집을 찾아 헤맸지만 길은 낯설기만 했습니다. 그때 친절한 할머니가 고양이를 발견하고 따뜻한 우유를 주었습니다.`,
			want: &models.Story{
				Title:   "작은 고양이의 모험",
				Content: "어느 날, 작은 고양이가 길을 잃었습니다. 고양이는 집을 찾아 헤맸지만 길은 낯설기만 했습니다. 그때 친절한 할머니가 고양이를 발견하고 따뜻한 우유를 주었습니다.",
			},
		},
		{
			name: "handles extra whitespace",
			content: `제목:   많은 공백이 있는 제목   
내용:    내용도 공백으로 시작합니다   `,
			want: &models.Story{
				Title:   "많은 공백이 있는 제목",
				Content: "내용도 공백으로 시작합니다",
			},
		},
		{
			name: "handles multiline content",
			content: `제목: 여러 줄 이야기
내용: 첫 번째 줄입니다.
두 번째 줄입니다.
세 번째 줄입니다.`,
			want: &models.Story{
				Title:   "여러 줄 이야기",
				Content: "첫 번째 줄입니다. 두 번째 줄입니다. 세 번째 줄입니다.",
			},
		},
		{
			name:    "fallback for unformatted content",
			content: "이것은 형식이 없는 순수한 텍스트입니다.",
			want: &models.Story{
				Title:   "무제",
				Content: "이것은 형식이 없는 순수한 텍스트입니다.",
			},
		},
		{
			name: "handles missing title",
			content: `내용: 제목이 없는 이야기입니다.`,
			want: &models.Story{
				Title:   "무제",
				Content: "내용: 제목이 없는 이야기입니다.",
			},
		},
		{
			name: "handles missing content label",
			content: `제목: 레이블이 없는 내용
이것은 내용 레이블 없이 바로 시작하는 내용입니다.`,
			want: &models.Story{
				Title:   "무제",
				Content: `제목: 레이블이 없는 내용
이것은 내용 레이블 없이 바로 시작하는 내용입니다.`,
			},
		},
		{
			name:    "handles empty content",
			content: "",
			want: &models.Story{
				Title:   "무제",
				Content: "",
			},
		},
		{
			name: "handles content with colons",
			content: `제목: 시간: 오후 3시
내용: 그는 말했다: "안녕하세요". 그녀가 대답했다: "반갑습니다".`,
			want: &models.Story{
				Title:   "시간: 오후 3시",
				Content: "그는 말했다: \"안녕하세요\". 그녀가 대답했다: \"반갑습니다\".",
			},
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := generator.parseStoryResponse(tt.content)
			if err != nil {
				t.Fatalf("parseStoryResponse() error = %v", err)
			}
			
			if got.Title != tt.want.Title {
				t.Errorf("parseStoryResponse() title = %v, want %v", got.Title, tt.want.Title)
			}
			
			if got.Content != tt.want.Content {
				t.Errorf("parseStoryResponse() content = %v, want %v", got.Content, tt.want.Content)
			}
		})
	}
}

func TestOpenAIGenerator_DivideIntoScenes(t *testing.T) {
	generator := &OpenAIGenerator{}
	ctx := context.Background()
	
	tests := []struct {
		name    string
		story   *models.Story
		wantErr bool
		verify  func(t *testing.T, story *models.Story)
	}{
		{
			name: "divides story with multiple sentences",
			story: &models.Story{
				Title:   "Test Story",
				Content: "첫 번째 문장. 두 번째 문장. 세 번째 문장. 네 번째 문장.",
			},
			wantErr: false,
			verify: func(t *testing.T, story *models.Story) {
				// Should create 2 scenes (every 2 sentences)
				if len(story.Scenes) != 2 {
					t.Errorf("Expected 2 scenes, got %d", len(story.Scenes))
				}
				
				// Check first scene
				if story.Scenes[0].Number != 1 {
					t.Errorf("First scene number = %d, want 1", story.Scenes[0].Number)
				}
				
				// Check scene descriptions
				for i, scene := range story.Scenes {
					if scene.Description == "" {
						t.Errorf("Scene %d has empty description", i+1)
					}
				}
			},
		},
		{
			name: "creates appropriate image prompts",
			story: &models.Story{
				Title:   "Korean Story",
				Content: "아름다운 숲 속. 신비로운 동물들.",
			},
			wantErr: false,
			verify: func(t *testing.T, story *models.Story) {
				for i, scene := range story.Scenes {
					if !strings.Contains(scene.ImagePrompt, "Korean story illustration") {
						t.Errorf("Scene %d image prompt missing Korean story prefix", i+1)
					}
					
					if !strings.Contains(scene.ImagePrompt, "vertical format") {
						t.Errorf("Scene %d image prompt missing vertical format", i+1)
					}
					
					if !strings.Contains(scene.ImagePrompt, "soft colors") {
						t.Errorf("Scene %d image prompt missing soft colors", i+1)
					}
				}
			},
		},
		{
			name: "calculates duration based on text length",
			story: &models.Story{
				Title:   "Duration Test",
				Content: "짧은 문장. 이것은 매우 긴 문장으로 더 많은 시간이 필요합니다.",
			},
			wantErr: false,
			verify: func(t *testing.T, story *models.Story) {
				for i, scene := range story.Scenes {
					if scene.Duration <= 0 {
						t.Errorf("Scene %d has non-positive duration: %f", i+1, scene.Duration)
					}
					
					// Duration should be proportional to text length (len/30.0)
					expectedDuration := float64(len(scene.Description)) / 30.0
					if scene.Duration != expectedDuration {
						t.Errorf("Scene %d duration = %f, want %f", i+1, scene.Duration, expectedDuration)
					}
				}
			},
		},
		{
			name: "handles single sentence",
			story: &models.Story{
				Title:   "Single",
				Content: "하나의 문장만 있습니다.",
			},
			wantErr: false,
			verify: func(t *testing.T, story *models.Story) {
				if len(story.Scenes) != 1 {
					t.Errorf("Expected 1 scene for single sentence, got %d", len(story.Scenes))
				}
			},
		},
		{
			name: "handles empty content",
			story: &models.Story{
				Title:   "Empty",
				Content: "",
			},
			wantErr: false,
			verify: func(t *testing.T, story *models.Story) {
				// Empty content creates one scene with ". " as description
				if len(story.Scenes) != 1 {
					t.Errorf("Expected 1 scene for empty content, got %d", len(story.Scenes))
				}
				if len(story.Scenes) > 0 && story.Scenes[0].Description != ". " {
					t.Errorf("Expected scene description '. ', got %s", story.Scenes[0].Description)
				}
			},
		},
		{
			name: "handles odd number of sentences",
			story: &models.Story{
				Title:   "Odd",
				Content: "하나. 둘. 셋. 넷. 다섯.",
			},
			wantErr: false,
			verify: func(t *testing.T, story *models.Story) {
				// 5 sentences should create 3 scenes (2+2+1)
				if len(story.Scenes) != 3 {
					t.Errorf("Expected 3 scenes for 5 sentences, got %d", len(story.Scenes))
				}
			},
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create a copy to avoid modifying original
			storyCopy := &models.Story{
				Title:   tt.story.Title,
				Content: tt.story.Content,
			}
			
			err := generator.DivideIntoScenes(ctx, storyCopy)
			
			if (err != nil) != tt.wantErr {
				t.Errorf("DivideIntoScenes() error = %v, wantErr %v", err, tt.wantErr)
			}
			
			if err == nil && tt.verify != nil {
				tt.verify(t, storyCopy)
			}
		})
	}
}

func TestOpenAIGenerator_simpleDivideScenes(t *testing.T) {
	generator := &OpenAIGenerator{}
	
	tests := []struct {
		name  string
		story *models.Story
		want  int // expected number of scenes
	}{
		{
			name: "even number of sentences",
			story: &models.Story{
				Content: "문장 하나. 문장 둘. 문장 셋. 문장 넷.",
			},
			want: 2,
		},
		{
			name: "trailing spaces don't create empty scenes",
			story: &models.Story{
				Content: "문장 하나. 문장 둘. ",
			},
			want: 2, // Two sentences create 2 scenes (one at i%2==0, one at end)
		},
		{
			name: "handles period without space",
			story: &models.Story{
				Content: "문장하나.문장둘.문장셋.문장넷.",
			},
			want: 1, // All treated as one sentence since split is on ". "
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := generator.simpleDivideScenes(tt.story)
			if err != nil {
				t.Fatalf("simpleDivideScenes() error = %v", err)
			}
			
			if len(tt.story.Scenes) != tt.want {
				t.Errorf("simpleDivideScenes() created %d scenes, want %d", len(tt.story.Scenes), tt.want)
			}
		})
	}
}

func TestOpenAIGenerator_ContextCancellation(t *testing.T) {
	// Create a canceled context
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	
	generator := &OpenAIGenerator{
		apiKey:      "test-key",
		model:       "gpt-3.5-turbo",
		maxTokens:   500,
		temperature: 0.7,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
	
	channel := &models.Channel{ID: 5}
	
	_, err := generator.GenerateStory(ctx, channel)
	if err == nil {
		t.Error("GenerateStory() with canceled context should return error")
	}
	
	if !strings.Contains(err.Error(), "context canceled") {
		t.Errorf("Expected context canceled error, got %v", err)
	}
}

// Benchmarks

func BenchmarkOpenAIGenerator_parseStoryResponse(b *testing.B) {
	generator := &OpenAIGenerator{}
	content := `제목: 벤치마크 테스트 이야기
내용: 이것은 벤치마크를 위한 테스트 이야기입니다. 여러 문장이 포함되어 있으며, 파싱 성능을 측정하기 위한 것입니다. 세 번째 문장도 있습니다.`
	
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := generator.parseStoryResponse(content)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkOpenAIGenerator_simpleDivideScenes(b *testing.B) {
	generator := &OpenAIGenerator{}
	story := &models.Story{
		Title:   "Benchmark Story",
		Content: strings.Repeat("테스트 문장입니다. ", 20),
	}
	
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		storyCopy := &models.Story{
			Title:   story.Title,
			Content: story.Content,
		}
		
		err := generator.simpleDivideScenes(storyCopy)
		if err != nil {
			b.Fatal(err)
		}
	}
}