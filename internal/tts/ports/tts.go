package ports

import (
	"context"
	"ssulmeta-go/pkg/models"
)

// Service defines the interface for TTS services
type Service interface {
	// GenerateNarration generates audio narration for story scenes
	GenerateNarration(ctx context.Context, story *models.Story) ([]*models.AudioFile, error)

	// GenerateAudio generates audio from text with options
	GenerateAudio(ctx context.Context, request *AudioRequest) (*models.AudioFile, error)
}

// Generator defines the interface for text-to-speech generation
type Generator interface {
	// GenerateAudio generates audio from text
	GenerateAudio(ctx context.Context, text string, options *AudioOptions) (string, error)

	// GetAudioDuration returns the duration of an audio file in seconds
	GetAudioDuration(audioPath string) (float64, error)
}

// Processor defines the interface for text processing
type Processor interface {
	// PreprocessText processes text before TTS generation
	PreprocessText(text string) (string, error)

	// ValidateText validates text for TTS requirements
	ValidateText(text string) error
}

// AudioRequest represents a TTS generation request
type AudioRequest struct {
	Text     string        `json:"text"`
	Options  *AudioOptions `json:"options,omitempty"`
	Language string        `json:"language,omitempty"`
}

// AudioOptions represents TTS generation options
type AudioOptions struct {
	Voice         string  `json:"voice,omitempty"`
	SpeakingRate  float64 `json:"speaking_rate,omitempty"`
	Pitch         float64 `json:"pitch,omitempty"`
	VolumeGainDb  float64 `json:"volume_gain_db,omitempty"`
	SampleRateHz  int     `json:"sample_rate_hz,omitempty"`
	AudioEncoding string  `json:"audio_encoding,omitempty"`
	SSMLEnabled   bool    `json:"ssml_enabled,omitempty"`
}
