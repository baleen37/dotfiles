package tts

import (
	"ssulmeta-go/internal/tts/adapters"
	"ssulmeta-go/internal/tts/core"
	"ssulmeta-go/internal/tts/ports"
)

// ServiceFactory creates TTS service instances
type ServiceFactory struct {
	googleAPIKey string
	assetPath    string
	mockMode     bool
}

// NewServiceFactory creates a new TTS service factory
func NewServiceFactory(googleAPIKey, assetPath string, mockMode bool) *ServiceFactory {
	return &ServiceFactory{
		googleAPIKey: googleAPIKey,
		assetPath:    assetPath,
		mockMode:     mockMode,
	}
}

// CreateService creates a TTS service with appropriate implementations
func (f *ServiceFactory) CreateService() ports.Service {
	// Create text processor
	processor := core.NewTextProcessor()

	// Create generator based on mode
	var generator ports.Generator
	if f.mockMode || f.googleAPIKey == "" {
		generator = adapters.NewMockTTSGenerator(f.assetPath)
	} else {
		generator = adapters.NewGoogleTTSClient(f.googleAPIKey, f.assetPath)
	}

	// Create and return service
	return core.NewTTSService(generator, processor)
}

// CreateGenerator creates a TTS generator
func (f *ServiceFactory) CreateGenerator() ports.Generator {
	if f.mockMode || f.googleAPIKey == "" {
		return adapters.NewMockTTSGenerator(f.assetPath)
	}
	return adapters.NewGoogleTTSClient(f.googleAPIKey, f.assetPath)
}

// CreateProcessor creates a text processor
func (f *ServiceFactory) CreateProcessor() ports.Processor {
	return core.NewTextProcessor()
}
