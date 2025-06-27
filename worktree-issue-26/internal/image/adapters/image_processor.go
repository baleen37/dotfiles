package adapters

import (
	"context"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"golang.org/x/image/draw"
	_ "golang.org/x/image/webp" // Register WebP decoder

	"ssulmeta-go/internal/image/ports"
)

// ImageProcessor implements image processing operations
type ImageProcessor struct {
	logger *slog.Logger
}

// NewImageProcessor creates a new image processor
func NewImageProcessor(logger *slog.Logger) ports.ImageProcessor {
	return &ImageProcessor{
		logger: logger.With("adapter", "image_processor"),
	}
}

// ResizeImage resizes an image to specified dimensions
func (p *ImageProcessor) ResizeImage(ctx context.Context, imagePath string, width, height int) (string, error) {
	p.logger.Info("Resizing image",
		"path", imagePath,
		"target_width", width,
		"target_height", height,
	)

	// Open source image
	file, err := os.Open(imagePath)
	if err != nil {
		return "", fmt.Errorf("failed to open image: %w", err)
	}
	defer func() {
		if err := file.Close(); err != nil {
			p.logger.Warn("Failed to close file", "error", err)
		}
	}()

	// Decode image
	srcImg, format, err := image.Decode(file)
	if err != nil {
		return "", fmt.Errorf("failed to decode image: %w", err)
	}

	p.logger.Debug("Decoded image",
		"format", format,
		"bounds", srcImg.Bounds(),
	)

	// Create destination image
	dstImg := image.NewRGBA(image.Rect(0, 0, width, height))

	// Draw scaled image with BiLinear interpolation
	// This will automatically handle scaling to fit the destination bounds
	srcBounds := srcImg.Bounds()
	draw.BiLinear.Scale(dstImg, dstImg.Bounds(), srcImg, srcBounds, draw.Over, nil)

	// Generate output path
	dir := filepath.Dir(imagePath)
	base := filepath.Base(imagePath)
	ext := filepath.Ext(base)
	nameWithoutExt := strings.TrimSuffix(base, ext)
	outputPath := filepath.Join(dir, fmt.Sprintf("%s_resized_%dx%d%s", nameWithoutExt, width, height, ext))

	// Create output file
	outFile, err := os.Create(outputPath)
	if err != nil {
		return "", fmt.Errorf("failed to create output file: %w", err)
	}
	defer func() {
		if err := outFile.Close(); err != nil {
			p.logger.Warn("Failed to close output file", "error", err)
		}
	}()

	// Encode image based on format
	switch strings.ToLower(ext) {
	case ".jpg", ".jpeg":
		err = jpeg.Encode(outFile, dstImg, &jpeg.Options{Quality: 90})
	case ".png":
		err = png.Encode(outFile, dstImg)
	default:
		// Default to PNG for unknown formats
		err = png.Encode(outFile, dstImg)
	}

	if err != nil {
		return "", fmt.Errorf("failed to encode image: %w", err)
	}

	p.logger.Info("Image resized successfully",
		"output_path", outputPath,
	)

	return outputPath, nil
}

// ValidateImage checks if image meets requirements
func (p *ImageProcessor) ValidateImage(ctx context.Context, imagePath string) error {
	p.logger.Info("Validating image", "path", imagePath)

	// Check if file exists
	info, err := os.Stat(imagePath)
	if err != nil {
		return fmt.Errorf("image not found: %w", err)
	}

	// Check file size (max 10MB)
	maxSize := int64(10 * 1024 * 1024)
	if info.Size() > maxSize {
		return fmt.Errorf("image too large: %d bytes (max %d)", info.Size(), maxSize)
	}

	// Check file extension
	ext := strings.ToLower(filepath.Ext(imagePath))
	validExtensions := map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".webp": true,
	}

	if !validExtensions[ext] {
		return fmt.Errorf("invalid image format: %s", ext)
	}

	// Open and decode image to check dimensions
	file, err := os.Open(imagePath)
	if err != nil {
		return fmt.Errorf("failed to open image: %w", err)
	}
	defer func() {
		if err := file.Close(); err != nil {
			p.logger.Warn("Failed to close file", "error", err)
		}
	}()

	imgConfig, format, err := image.DecodeConfig(file)
	if err != nil {
		return fmt.Errorf("failed to decode image config: %w", err)
	}

	p.logger.Debug("Image validation details",
		"format", format,
		"width", imgConfig.Width,
		"height", imgConfig.Height,
	)

	// Check minimum dimensions
	minWidth := 720
	minHeight := 1280
	if imgConfig.Width < minWidth || imgConfig.Height < minHeight {
		return fmt.Errorf("image too small: %dx%d (min %dx%d)",
			imgConfig.Width, imgConfig.Height, minWidth, minHeight)
	}

	// Check aspect ratio (should be close to 9:16)
	aspectRatio := float64(imgConfig.Width) / float64(imgConfig.Height)
	targetAspectRatio := 9.0 / 16.0
	tolerance := 0.1

	if aspectRatio < targetAspectRatio-tolerance || aspectRatio > targetAspectRatio+tolerance {
		p.logger.Warn("Image aspect ratio not optimal for vertical video",
			"aspect_ratio", aspectRatio,
			"target", targetAspectRatio,
		)
	}

	p.logger.Info("Image validation successful",
		"format", format,
		"dimensions", fmt.Sprintf("%dx%d", imgConfig.Width, imgConfig.Height),
	)

	return nil
}
