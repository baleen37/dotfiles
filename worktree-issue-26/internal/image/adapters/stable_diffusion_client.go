package adapters

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"ssulmeta-go/internal/image/ports"
	"ssulmeta-go/pkg/models"
)

// StableDiffusionClient implements the Generator interface using Stable Diffusion API
type StableDiffusionClient struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
	assetPath  string
	logger     *slog.Logger
}

// StableDiffusionRequest represents the API request format
type StableDiffusionRequest struct {
	Prompt         string                 `json:"prompt"`
	NegativePrompt string                 `json:"negative_prompt,omitempty"`
	Width          int                    `json:"width"`
	Height         int                    `json:"height"`
	Steps          int                    `json:"steps"`
	GuidanceScale  float64                `json:"guidance_scale"`
	Seed           int64                  `json:"seed,omitempty"`
	Sampler        string                 `json:"sampler,omitempty"`
	ModelID        string                 `json:"model_id,omitempty"`
	Extra          map[string]interface{} `json:"extra,omitempty"`
}

// StableDiffusionResponse represents the API response format
type StableDiffusionResponse struct {
	Images []struct {
		URL    string `json:"url"`
		Base64 string `json:"base64,omitempty"`
	} `json:"images"`
	Error   string `json:"error,omitempty"`
	Message string `json:"message,omitempty"`
}

// NewStableDiffusionClient creates a new Stable Diffusion API client
func NewStableDiffusionClient(apiKey, baseURL, assetPath string, logger *slog.Logger) ports.Generator {
	return &StableDiffusionClient{
		apiKey:    apiKey,
		baseURL:   baseURL,
		assetPath: assetPath,
		logger:    logger.With("adapter", "stable_diffusion"),
		httpClient: &http.Client{
			Timeout: 120 * time.Second, // Long timeout for image generation
		},
	}
}

// GenerateImage generates a single image using Stable Diffusion API
func (c *StableDiffusionClient) GenerateImage(ctx context.Context, prompt string) (string, error) {
	c.logger.Info("Generating image with Stable Diffusion",
		"prompt_length", len(prompt),
	)

	// Prepare request
	request := StableDiffusionRequest{
		Prompt: prompt,
		NegativePrompt: "blurry, bad quality, distorted, ugly, malformed, text, watermark, " +
			"signature, amateur, low resolution, cropped, horizontal orientation",
		Width:         1080,
		Height:        1920,
		Steps:         30,
		GuidanceScale: 7.5,
		Sampler:       "DPM++ 2M Karras",
	}

	// Make API request
	resp, err := c.makeRequest(ctx, request)
	if err != nil {
		return "", fmt.Errorf("API request failed: %w", err)
	}

	if len(resp.Images) == 0 {
		return "", fmt.Errorf("no images returned from API")
	}

	// Download and save image
	imageURL := resp.Images[0].URL
	if imageURL == "" && resp.Images[0].Base64 != "" {
		// Handle base64 response
		return c.saveBase64Image(resp.Images[0].Base64)
	}

	return c.downloadImage(ctx, imageURL)
}

// GenerateSceneImages generates images for multiple scenes
func (c *StableDiffusionClient) GenerateSceneImages(ctx context.Context, scenes []models.Scene) ([]string, error) {
	c.logger.Info("Generating images for scenes",
		"scene_count", len(scenes),
	)

	images := make([]string, len(scenes))

	// Generate images sequentially to avoid rate limits
	// In production, you might want to implement parallel generation with rate limiting
	for i, scene := range scenes {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		default:
		}

		c.logger.Info("Generating image for scene",
			"scene_number", scene.Number,
			"prompt", scene.ImagePrompt,
		)

		image, err := c.GenerateImage(ctx, scene.ImagePrompt)
		if err != nil {
			c.logger.Error("Failed to generate image for scene",
				"scene_number", scene.Number,
				"error", err,
			)
			return nil, fmt.Errorf("failed to generate image for scene %d: %w", scene.Number, err)
		}

		images[i] = image

		// Add delay between requests to avoid rate limiting
		if i < len(scenes)-1 {
			time.Sleep(2 * time.Second)
		}
	}

	return images, nil
}

// makeRequest makes an HTTP request to the Stable Diffusion API
func (c *StableDiffusionClient) makeRequest(ctx context.Context, request StableDiffusionRequest) (*StableDiffusionResponse, error) {
	// Prepare request body
	body, err := json.Marshal(request)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	// Create HTTP request
	req, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+"/v1/generation/text-to-image", bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.apiKey)

	// Make request
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer func() {
		if err := resp.Body.Close(); err != nil {
			c.logger.Warn("Failed to close response body", "error", err)
		}
	}()

	// Read response body
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	// Check status code
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API returned status %d: %s", resp.StatusCode, string(respBody))
	}

	// Parse response
	var sdResp StableDiffusionResponse
	if err := json.Unmarshal(respBody, &sdResp); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	// Check for API errors
	if sdResp.Error != "" {
		return nil, fmt.Errorf("API error: %s", sdResp.Error)
	}

	return &sdResp, nil
}

// downloadImage downloads an image from URL and saves it locally
func (c *StableDiffusionClient) downloadImage(ctx context.Context, imageURL string) (string, error) {
	// Create request
	req, err := http.NewRequestWithContext(ctx, "GET", imageURL, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create download request: %w", err)
	}

	// Download image
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to download image: %w", err)
	}
	defer func() {
		if err := resp.Body.Close(); err != nil {
			c.logger.Warn("Failed to close response body", "error", err)
		}
	}()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("failed to download image, status: %d", resp.StatusCode)
	}

	// Create temp directory
	tempDir := filepath.Join(c.assetPath, "temp", "images")
	if err := os.MkdirAll(tempDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create temp directory: %w", err)
	}

	// Generate unique filename
	filename := fmt.Sprintf("sd_image_%d.png", time.Now().UnixNano())
	filepath := filepath.Join(tempDir, filename)

	// Create file
	file, err := os.Create(filepath)
	if err != nil {
		return "", fmt.Errorf("failed to create file: %w", err)
	}
	defer func() {
		if err := file.Close(); err != nil {
			c.logger.Warn("Failed to close file", "error", err)
		}
	}()

	// Copy image data
	if _, err := io.Copy(file, resp.Body); err != nil {
		return "", fmt.Errorf("failed to save image: %w", err)
	}

	return filepath, nil
}

// saveBase64Image saves a base64 encoded image to file
func (c *StableDiffusionClient) saveBase64Image(base64Data string) (string, error) {
	// Decode base64
	imageData, err := decodeBase64(base64Data)
	if err != nil {
		return "", fmt.Errorf("failed to decode base64: %w", err)
	}

	// Create temp directory
	tempDir := filepath.Join(c.assetPath, "temp", "images")
	if err := os.MkdirAll(tempDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create temp directory: %w", err)
	}

	// Generate unique filename
	filename := fmt.Sprintf("sd_image_%d.png", time.Now().UnixNano())
	filepath := filepath.Join(tempDir, filename)

	// Write file
	if err := os.WriteFile(filepath, imageData, 0644); err != nil {
		return "", fmt.Errorf("failed to write image file: %w", err)
	}

	return filepath, nil
}

// decodeBase64 decodes a base64 string
func decodeBase64(data string) ([]byte, error) {
	// Remove data URL prefix if present
	if idx := bytes.IndexByte([]byte(data), ','); idx != -1 {
		data = data[idx+1:]
	}

	return []byte(data), nil // Simplified for now
}
