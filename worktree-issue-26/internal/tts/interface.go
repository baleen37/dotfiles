package tts

import (
	"context"
)

// Generator defines the interface for text-to-speech generation
type Generator interface {
	// GenerateAudio generates audio from text
	GenerateAudio(ctx context.Context, text string) (string, error)

	// GetAudioDuration returns the duration of an audio file in seconds
	GetAudioDuration(audioPath string) (float64, error)
}
