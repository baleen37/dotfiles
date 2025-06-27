package adapters

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"ssulmeta-go/internal/tts/ports"
	"time"
)

// GoogleTTSClient implements TTS generation using Google Cloud TTS API
type GoogleTTSClient struct {
	apiKey     string
	assetPath  string
	httpClient *http.Client
}

// NewGoogleTTSClient creates a new Google TTS client
func NewGoogleTTSClient(apiKey, assetPath string) *GoogleTTSClient {
	return &GoogleTTSClient{
		apiKey:     apiKey,
		assetPath:  assetPath,
		httpClient: &http.Client{Timeout: 30 * time.Second},
	}
}

// TTSRequest represents a Google Cloud TTS API request
type TTSRequest struct {
	Input       TTSInput       `json:"input"`
	Voice       TTSVoice       `json:"voice"`
	AudioConfig TTSAudioConfig `json:"audioConfig"`
}

// TTSInput represents the input text
type TTSInput struct {
	Text string `json:"text,omitempty"`
	SSML string `json:"ssml,omitempty"`
}

// TTSVoice represents voice configuration
type TTSVoice struct {
	LanguageCode string `json:"languageCode"`
	Name         string `json:"name,omitempty"`
	SSMLGender   string `json:"ssmlGender,omitempty"`
}

// TTSAudioConfig represents audio configuration
type TTSAudioConfig struct {
	AudioEncoding   string  `json:"audioEncoding"`
	SpeakingRate    float64 `json:"speakingRate,omitempty"`
	Pitch           float64 `json:"pitch,omitempty"`
	VolumeGainDb    float64 `json:"volumeGainDb,omitempty"`
	SampleRateHertz int     `json:"sampleRateHertz,omitempty"`
}

// TTSResponse represents a Google Cloud TTS API response
type TTSResponse struct {
	AudioContent string `json:"audioContent"`
}

// GenerateAudio generates audio from text using Google Cloud TTS
func (c *GoogleTTSClient) GenerateAudio(ctx context.Context, text string, options *ports.AudioOptions) (string, error) {
	if c.apiKey == "" {
		return "", fmt.Errorf("google Cloud TTS API key not configured")
	}

	// Create TTS request
	request := c.buildTTSRequest(text, options)

	// Make API request
	response, err := c.callTTSAPI(ctx, request)
	if err != nil {
		return "", fmt.Errorf("TTS API call failed: %w", err)
	}

	// Save audio file
	audioPath, err := c.saveAudioFile(response.AudioContent, options)
	if err != nil {
		return "", fmt.Errorf("failed to save audio file: %w", err)
	}

	return audioPath, nil
}

// GetAudioDuration returns the duration of an audio file
func (c *GoogleTTSClient) GetAudioDuration(audioPath string) (float64, error) {
	// Check if file exists
	if _, err := os.Stat(audioPath); os.IsNotExist(err) {
		return 0, fmt.Errorf("audio file does not exist: %s", audioPath)
	}

	// Get file info
	fileInfo, err := os.Stat(audioPath)
	if err != nil {
		return 0, fmt.Errorf("failed to get file info: %w", err)
	}

	// Estimate duration based on file size (rough approximation)
	// For MP3 at 22050 Hz, approximately 2KB per second
	fileSizeKB := float64(fileInfo.Size()) / 1024
	estimatedDuration := fileSizeKB / 2.0

	// Ensure minimum reasonable duration
	if estimatedDuration < 1.0 {
		estimatedDuration = 1.0
	}

	return estimatedDuration, nil
}

// buildTTSRequest creates a TTS API request from text and options
func (c *GoogleTTSClient) buildTTSRequest(text string, options *ports.AudioOptions) *TTSRequest {
	request := &TTSRequest{
		Voice: TTSVoice{
			LanguageCode: "ko-KR",
			SSMLGender:   "FEMALE",
		},
		AudioConfig: TTSAudioConfig{
			AudioEncoding: "MP3",
			SpeakingRate:  1.0,
			Pitch:         0.0,
			VolumeGainDb:  0.0,
		},
	}

	// Set input text (check for SSML)
	if options != nil && options.SSMLEnabled {
		request.Input.SSML = text
	} else {
		request.Input.Text = text
	}

	// Apply options if provided
	if options != nil {
		if options.Voice != "" {
			request.Voice.Name = options.Voice
		}
		if options.SpeakingRate > 0 {
			request.AudioConfig.SpeakingRate = options.SpeakingRate
		}
		if options.Pitch != 0 {
			request.AudioConfig.Pitch = options.Pitch
		}
		if options.VolumeGainDb != 0 {
			request.AudioConfig.VolumeGainDb = options.VolumeGainDb
		}
		if options.SampleRateHz > 0 {
			request.AudioConfig.SampleRateHertz = options.SampleRateHz
		}
		if options.AudioEncoding != "" {
			request.AudioConfig.AudioEncoding = options.AudioEncoding
		}
	}

	return request
}

// callTTSAPI makes the actual API call to Google Cloud TTS
func (c *GoogleTTSClient) callTTSAPI(ctx context.Context, request *TTSRequest) (*TTSResponse, error) {
	// Serialize request
	requestBody, err := json.Marshal(request)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	// Create HTTP request
	url := fmt.Sprintf("https://texttospeech.googleapis.com/v1/text:synthesize?key=%s", c.apiKey)
	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(requestBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	// Make request
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("HTTP request failed: %w", err)
	}
	defer func() {
		_ = resp.Body.Close() // Ignore close error
	}()

	// Read response
	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// Check for API errors
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API error (status %d): %s", resp.StatusCode, string(responseBody))
	}

	// Parse response
	var ttsResponse TTSResponse
	if err := json.Unmarshal(responseBody, &ttsResponse); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	return &ttsResponse, nil
}

// saveAudioFile saves the base64-encoded audio content to a file
func (c *GoogleTTSClient) saveAudioFile(audioContent string, options *ports.AudioOptions) (string, error) {
	// Create audio directory
	audioDir := filepath.Join(c.assetPath, "audio")
	if err := os.MkdirAll(audioDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create audio directory: %w", err)
	}

	// Determine file extension
	var ext string
	if options != nil && options.AudioEncoding != "" {
		switch options.AudioEncoding {
		case "MP3":
			ext = ".mp3"
		case "WAV":
			ext = ".wav"
		case "OGG_OPUS":
			ext = ".ogg"
		default:
			ext = ".mp3"
		}
	} else {
		ext = ".mp3"
	}

	// Generate unique filename
	filename := fmt.Sprintf("tts_%d%s", time.Now().UnixNano(), ext)
	audioPath := filepath.Join(audioDir, filename)

	// Decode base64 audio content
	audioData, err := base64.StdEncoding.DecodeString(audioContent)
	if err != nil {
		return "", fmt.Errorf("failed to decode audio content: %w", err)
	}

	// Write to file
	if err := os.WriteFile(audioPath, audioData, 0644); err != nil {
		return "", fmt.Errorf("failed to write audio file: %w", err)
	}

	return audioPath, nil
}
