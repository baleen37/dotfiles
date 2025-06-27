package tts

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
)

// MockGenerator is a mock implementation of Generator
type MockGenerator struct {
	assetPath string
}

// NewMockGenerator creates a new mock generator
func NewMockGenerator(assetPath string) *MockGenerator {
	return &MockGenerator{
		assetPath: assetPath,
	}
}

// GenerateAudio returns a path to a mock audio file
func (m *MockGenerator) GenerateAudio(ctx context.Context, text string) (string, error) {
	// Create mock audio directory
	mockDir := filepath.Join(m.assetPath, "mock_audio")
	if err := os.MkdirAll(mockDir, 0755); err != nil {
		return "", err
	}

	// Return path to a placeholder audio file
	audioPath := filepath.Join(mockDir, fmt.Sprintf("narration_%d.mp3", len(text)))

	// Create a placeholder file
	file, err := os.Create(audioPath)
	if err != nil {
		return "", err
	}
	if err := file.Close(); err != nil {
		return "", fmt.Errorf("failed to close file: %w", err)
	}

	return audioPath, nil
}

// GetAudioDuration returns a mock duration
func (m *MockGenerator) GetAudioDuration(audioPath string) (float64, error) {
	// Mock duration: approximately 1 second per 5 characters
	// Korean text is roughly 270-300 chars per minute
	return 60.0, nil // Return 60 seconds for testing
}
