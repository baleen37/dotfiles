package core

import (
	"context"
	"fmt"
	"ssulmeta-go/internal/tts/ports"
	"ssulmeta-go/pkg/models"
	"time"
)

// TTSService implements the TTS service
type TTSService struct {
	generator ports.Generator
	processor ports.Processor
}

// NewTTSService creates a new TTS service
func NewTTSService(generator ports.Generator, processor ports.Processor) *TTSService {
	return &TTSService{
		generator: generator,
		processor: processor,
	}
}

// GenerateNarration generates audio narration for story scenes
func (s *TTSService) GenerateNarration(ctx context.Context, story *models.Story) ([]*models.AudioFile, error) {
	var audioFiles []*models.AudioFile

	for i, scene := range story.Scenes {
		// Preprocess text for TTS
		processedText, err := s.processor.PreprocessText(scene.Description)
		if err != nil {
			return nil, fmt.Errorf("failed to preprocess text for scene %d: %w", i+1, err)
		}

		// Validate text
		if err := s.processor.ValidateText(processedText); err != nil {
			return nil, fmt.Errorf("text validation failed for scene %d: %w", i+1, err)
		}

		// Generate audio with Korean voice settings
		options := &ports.AudioOptions{
			Voice:         "ko-KR-Standard-A", // Korean female voice
			SpeakingRate:  1.0,
			Pitch:         0.0,
			VolumeGainDb:  0.0,
			SampleRateHz:  22050,
			AudioEncoding: "MP3",
			SSMLEnabled:   false,
		}

		audioPath, err := s.generator.GenerateAudio(ctx, processedText, options)
		if err != nil {
			return nil, fmt.Errorf("failed to generate audio for scene %d: %w", i+1, err)
		}

		// Get audio duration
		duration, err := s.generator.GetAudioDuration(audioPath)
		if err != nil {
			return nil, fmt.Errorf("failed to get audio duration for scene %d: %w", i+1, err)
		}

		// Create audio file model
		audioFile := &models.AudioFile{
			ID:         fmt.Sprintf("audio_%d_%d", time.Now().Unix(), i+1),
			Path:       audioPath,
			Format:     "mp3",
			Duration:   duration,
			SampleRate: options.SampleRateHz,
			Text:       processedText,
			Language:   "ko-KR",
			Voice:      options.Voice,
			CreatedAt:  time.Now(),
		}

		audioFiles = append(audioFiles, audioFile)
	}

	return audioFiles, nil
}

// GenerateAudio generates audio from text with options
func (s *TTSService) GenerateAudio(ctx context.Context, request *ports.AudioRequest) (*models.AudioFile, error) {
	// Preprocess text
	processedText, err := s.processor.PreprocessText(request.Text)
	if err != nil {
		return nil, fmt.Errorf("failed to preprocess text: %w", err)
	}

	// Validate text
	if err := s.processor.ValidateText(processedText); err != nil {
		return nil, fmt.Errorf("text validation failed: %w", err)
	}

	// Set default options if not provided
	options := request.Options
	if options == nil {
		options = &ports.AudioOptions{
			Voice:         "ko-KR-Standard-A",
			SpeakingRate:  1.0,
			Pitch:         0.0,
			VolumeGainDb:  0.0,
			SampleRateHz:  22050,
			AudioEncoding: "MP3",
			SSMLEnabled:   false,
		}
	}

	// Generate audio
	audioPath, err := s.generator.GenerateAudio(ctx, processedText, options)
	if err != nil {
		return nil, fmt.Errorf("failed to generate audio: %w", err)
	}

	// Get audio duration
	duration, err := s.generator.GetAudioDuration(audioPath)
	if err != nil {
		return nil, fmt.Errorf("failed to get audio duration: %w", err)
	}

	// Set default language if not provided
	language := request.Language
	if language == "" {
		language = "ko-KR"
	}

	// Create audio file model
	audioFile := &models.AudioFile{
		ID:         fmt.Sprintf("audio_%d", time.Now().Unix()),
		Path:       audioPath,
		Format:     "mp3",
		Duration:   duration,
		SampleRate: options.SampleRateHz,
		Text:       processedText,
		Language:   language,
		Voice:      options.Voice,
		CreatedAt:  time.Now(),
	}

	return audioFile, nil
}
