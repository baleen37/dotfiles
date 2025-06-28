package testutil

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/jpeg"
	"math"
	"os"
	"path/filepath"
)

// CreateTestImage creates a simple test JPEG image with text
func CreateTestImage(path string, width, height int, text string, bgColor color.Color) error {
	// Ensure directory exists
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return err
	}

	// Create image
	img := image.NewRGBA(image.Rect(0, 0, width, height))
	draw.Draw(img, img.Bounds(), &image.Uniform{bgColor}, image.Point{}, draw.Src)

	// TODO: Add text rendering (requires additional font packages)
	// For now, just create colored rectangles

	// Save as JPEG
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer func() {
		_ = file.Close() // Ignore close error in test util
	}()

	return jpeg.Encode(file, img, &jpeg.Options{Quality: 85})
}

// CreateTestAudio creates a simple WAV file with a sine wave
func CreateTestAudio(path string, durationSecs float64, frequency float64) error {
	// Ensure directory exists
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return err
	}

	// WAV parameters
	const (
		sampleRate    = 44100
		channels      = 1
		bitsPerSample = 16
	)

	numSamples := int(durationSecs * sampleRate)

	// Generate sine wave
	samples := make([]int16, numSamples)
	for i := 0; i < numSamples; i++ {
		t := float64(i) / sampleRate
		value := math.Sin(2 * math.Pi * frequency * t)
		samples[i] = int16(value * 32767) // Convert to 16-bit
	}

	// Create WAV file
	var buf bytes.Buffer

	// RIFF header
	buf.WriteString("RIFF")
	if err := binary.Write(&buf, binary.LittleEndian, uint32(36+numSamples*2)); err != nil {
		return fmt.Errorf("write RIFF header: %w", err)
	}
	buf.WriteString("WAVE")

	// fmt chunk
	buf.WriteString("fmt ")
	if err := binary.Write(&buf, binary.LittleEndian, uint32(16)); err != nil {
		return fmt.Errorf("write fmt chunk size: %w", err)
	}
	if err := binary.Write(&buf, binary.LittleEndian, uint16(1)); err != nil {
		return fmt.Errorf("write audio format: %w", err)
	}
	if err := binary.Write(&buf, binary.LittleEndian, uint16(channels)); err != nil {
		return fmt.Errorf("write channels: %w", err)
	}
	if err := binary.Write(&buf, binary.LittleEndian, uint32(sampleRate)); err != nil {
		return fmt.Errorf("write sample rate: %w", err)
	}
	if err := binary.Write(&buf, binary.LittleEndian, uint32(sampleRate*channels*bitsPerSample/8)); err != nil {
		return fmt.Errorf("write byte rate: %w", err)
	}
	if err := binary.Write(&buf, binary.LittleEndian, uint16(channels*bitsPerSample/8)); err != nil {
		return fmt.Errorf("write block align: %w", err)
	}
	if err := binary.Write(&buf, binary.LittleEndian, uint16(bitsPerSample)); err != nil {
		return fmt.Errorf("write bits per sample: %w", err)
	}

	// data chunk
	buf.WriteString("data")
	if err := binary.Write(&buf, binary.LittleEndian, uint32(numSamples*2)); err != nil {
		return fmt.Errorf("write data chunk size: %w", err)
	}

	// Write samples
	for _, sample := range samples {
		if err := binary.Write(&buf, binary.LittleEndian, sample); err != nil {
			return fmt.Errorf("write sample: %w", err)
		}
	}

	// Write to file
	return os.WriteFile(path, buf.Bytes(), 0644)
}

// CreateTestMediaFiles creates a set of test media files for integration testing
func CreateTestMediaFiles(baseDir string) error {
	// Create test images
	colors := []struct {
		name  string
		color color.Color
	}{
		{"red", color.RGBA{255, 0, 0, 255}},
		{"green", color.RGBA{0, 255, 0, 255}},
		{"blue", color.RGBA{0, 0, 255, 255}},
	}

	for i, c := range colors {
		imgPath := filepath.Join(baseDir, "images", fmt.Sprintf("test_%d.jpg", i+1))
		if err := CreateTestImage(imgPath, 1080, 1920, c.name, c.color); err != nil {
			return fmt.Errorf("create test image %d: %w", i+1, err)
		}
	}

	// Create test audio files
	// Narration (5 seconds)
	narrationPath := filepath.Join(baseDir, "audio", "narration.wav")
	if err := CreateTestAudio(narrationPath, 5.0, 440.0); err != nil {
		return fmt.Errorf("create narration audio: %w", err)
	}

	// Background music (10 seconds)
	bgMusicPath := filepath.Join(baseDir, "audio", "background.wav")
	if err := CreateTestAudio(bgMusicPath, 10.0, 220.0); err != nil {
		return fmt.Errorf("create background audio: %w", err)
	}

	return nil
}

// CleanupTestMedia removes test media files
func CleanupTestMedia(baseDir string) error {
	return os.RemoveAll(baseDir)
}
