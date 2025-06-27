package core

import (
	"context"
	"errors"
	"ssulmeta-go/internal/tts/ports"
	"ssulmeta-go/pkg/models"
	"testing"
)

// mockGenerator is a test mock for Generator
type mockGenerator struct {
	generateAudioFunc    func(ctx context.Context, text string, options *ports.AudioOptions) (string, error)
	getAudioDurationFunc func(audioPath string) (float64, error)
}

func (m *mockGenerator) GenerateAudio(ctx context.Context, text string, options *ports.AudioOptions) (string, error) {
	if m.generateAudioFunc != nil {
		return m.generateAudioFunc(ctx, text, options)
	}
	return "/mock/audio.mp3", nil
}

func (m *mockGenerator) GetAudioDuration(audioPath string) (float64, error) {
	if m.getAudioDurationFunc != nil {
		return m.getAudioDurationFunc(audioPath)
	}
	return 10.0, nil
}

// mockProcessor is a test mock for Processor
type mockProcessor struct {
	preprocessTextFunc func(text string) (string, error)
	validateTextFunc   func(text string) error
}

func (m *mockProcessor) PreprocessText(text string) (string, error) {
	if m.preprocessTextFunc != nil {
		return m.preprocessTextFunc(text)
	}
	return text, nil
}

func (m *mockProcessor) ValidateText(text string) error {
	if m.validateTextFunc != nil {
		return m.validateTextFunc(text)
	}
	return nil
}

func TestTTSService_GenerateNarration(t *testing.T) {
	tests := []struct {
		name          string
		story         *models.Story
		expectedFiles int
		wantError     bool
	}{
		{
			name: "successful narration generation",
			story: &models.Story{
				Title:   "Test Story",
				Content: "This is a test story.",
				Scenes: []models.Scene{
					{Number: 1, Description: "First scene", Duration: 5.0},
					{Number: 2, Description: "Second scene", Duration: 7.0},
				},
			},
			expectedFiles: 2,
			wantError:     false,
		},
		{
			name: "empty story scenes",
			story: &models.Story{
				Title:   "Empty Story",
				Content: "No scenes",
				Scenes:  []models.Scene{},
			},
			expectedFiles: 0,
			wantError:     false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			generator := &mockGenerator{}
			processor := &mockProcessor{}
			service := NewTTSService(generator, processor)

			audioFiles, err := service.GenerateNarration(context.Background(), tt.story)

			if tt.wantError {
				if err == nil {
					t.Error("expected error but got none")
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if len(audioFiles) != tt.expectedFiles {
				t.Errorf("expected %d audio files, got %d", tt.expectedFiles, len(audioFiles))
			}

			// Verify audio file properties
			for i, audioFile := range audioFiles {
				if audioFile.ID == "" {
					t.Errorf("audio file %d: missing ID", i)
				}
				if audioFile.Path == "" {
					t.Errorf("audio file %d: missing path", i)
				}
				if audioFile.Format != "mp3" {
					t.Errorf("audio file %d: expected format 'mp3', got '%s'", i, audioFile.Format)
				}
				if audioFile.Language != "ko-KR" {
					t.Errorf("audio file %d: expected language 'ko-KR', got '%s'", i, audioFile.Language)
				}
				if audioFile.CreatedAt.IsZero() {
					t.Errorf("audio file %d: missing created timestamp", i)
				}
			}
		})
	}
}

func TestTTSService_GenerateAudio(t *testing.T) {
	tests := []struct {
		name    string
		request *ports.AudioRequest
		wantErr bool
	}{
		{
			name: "successful generation with options",
			request: &ports.AudioRequest{
				Text:     "안녕하세요, 테스트입니다.",
				Language: "ko-KR",
				Options: &ports.AudioOptions{
					Voice:         "ko-KR-Standard-A",
					SpeakingRate:  1.0,
					AudioEncoding: "MP3",
				},
			},
			wantErr: false,
		},
		{
			name: "successful generation without options",
			request: &ports.AudioRequest{
				Text: "기본 설정으로 생성합니다.",
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			generator := &mockGenerator{}
			processor := &mockProcessor{}
			service := NewTTSService(generator, processor)

			audioFile, err := service.GenerateAudio(context.Background(), tt.request)

			if tt.wantErr {
				if err == nil {
					t.Error("expected error but got none")
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if audioFile == nil {
				t.Fatal("expected audio file but got nil")
			}

			// Verify audio file properties
			if audioFile.ID == "" {
				t.Error("missing audio file ID")
			}
			if audioFile.Text == "" {
				t.Error("missing audio file text")
			}
			if audioFile.Language == "" {
				t.Error("missing audio file language")
			}
		})
	}
}

func TestTTSService_ErrorHandling(t *testing.T) {
	t.Run("generator error", func(t *testing.T) {
		generator := &mockGenerator{
			generateAudioFunc: func(ctx context.Context, text string, options *ports.AudioOptions) (string, error) {
				return "", errors.New("generator error")
			},
		}
		processor := &mockProcessor{}
		service := NewTTSService(generator, processor)

		story := &models.Story{
			Scenes: []models.Scene{
				{Number: 1, Description: "Test scene"},
			},
		}

		_, err := service.GenerateNarration(context.Background(), story)
		if err == nil {
			t.Error("expected error but got none")
		}
	})

	t.Run("processor error", func(t *testing.T) {
		generator := &mockGenerator{}
		processor := &mockProcessor{
			preprocessTextFunc: func(text string) (string, error) {
				return "", errors.New("processor error")
			},
		}
		service := NewTTSService(generator, processor)

		story := &models.Story{
			Scenes: []models.Scene{
				{Number: 1, Description: "Test scene"},
			},
		}

		_, err := service.GenerateNarration(context.Background(), story)
		if err == nil {
			t.Error("expected error but got none")
		}
	})
}
