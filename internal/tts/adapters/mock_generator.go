package adapters

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"ssulmeta-go/internal/tts/ports"
	"time"
)

// MockTTSGenerator is a mock implementation of TTS Generator
type MockTTSGenerator struct {
	assetPath string
}

// NewMockTTSGenerator creates a new mock TTS generator
func NewMockTTSGenerator(assetPath string) *MockTTSGenerator {
	return &MockTTSGenerator{
		assetPath: assetPath,
	}
}

// GenerateAudio returns a path to a mock audio file
func (m *MockTTSGenerator) GenerateAudio(ctx context.Context, text string, options *ports.AudioOptions) (string, error) {
	// Create mock audio directory
	mockDir := filepath.Join(m.assetPath, "mock_audio")
	if err := os.MkdirAll(mockDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create mock audio directory: %w", err)
	}

	// Determine file extension based on options
	ext := ".mp3"
	if options != nil && options.AudioEncoding != "" {
		switch options.AudioEncoding {
		case "WAV":
			ext = ".wav"
		case "OGG_OPUS":
			ext = ".ogg"
		default:
			ext = ".mp3"
		}
	}

	// Generate unique filename
	filename := fmt.Sprintf("mock_tts_%d%s", time.Now().UnixNano(), ext)
	audioPath := filepath.Join(mockDir, filename)

	// Create a placeholder file with some content
	file, err := os.Create(audioPath)
	if err != nil {
		return "", fmt.Errorf("failed to create mock audio file: %w", err)
	}
	defer func() {
		_ = file.Close() // Ignore close error
	}()

	// Write mock audio header to make it look like a real file
	mockContent := fmt.Sprintf("Mock TTS Audio File\nText: %s\nGenerated: %s\n", text, time.Now().Format(time.RFC3339))
	if _, err := file.WriteString(mockContent); err != nil {
		return "", fmt.Errorf("failed to write mock content: %w", err)
	}

	return audioPath, nil
}

// GetAudioDuration returns a mock duration based on text length
func (m *MockTTSGenerator) GetAudioDuration(audioPath string) (float64, error) {
	// Check if file exists
	if _, err := os.Stat(audioPath); os.IsNotExist(err) {
		return 0, fmt.Errorf("mock audio file does not exist: %s", audioPath)
	}

	// Read file to get original text length (from mock content)
	content, err := os.ReadFile(audioPath)
	if err != nil {
		return 0, fmt.Errorf("failed to read mock audio file: %w", err)
	}

	// Calculate duration based on content length
	// Korean text: approximately 4-5 characters per second for natural speech
	textLength := len(content)
	duration := float64(textLength) / 4.0 // 4 characters per second

	// Ensure reasonable bounds
	if duration < 1.0 {
		duration = 1.0
	} else if duration > 60.0 {
		duration = 60.0
	}

	return duration, nil
}
