package testutil

import (
	"fmt"
	"image/color"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCreateTestMediaFiles(t *testing.T) {
	tempDir := filepath.Join(os.TempDir(), "test_media")
	defer func() {
		if err := CleanupTestMedia(tempDir); err != nil {
			t.Logf("Failed to cleanup test media: %v", err)
		}
	}()

	err := CreateTestMediaFiles(tempDir)
	require.NoError(t, err)

	// Check that images were created
	for i := 1; i <= 3; i++ {
		imgPath := filepath.Join(tempDir, "images", fmt.Sprintf("test_%d.jpg", i))
		info, err := os.Stat(imgPath)
		require.NoError(t, err)
		assert.True(t, info.Size() > 0)
	}

	// Check that audio files were created
	narrationPath := filepath.Join(tempDir, "audio", "narration.wav")
	info, err := os.Stat(narrationPath)
	require.NoError(t, err)
	assert.True(t, info.Size() > 0)

	bgMusicPath := filepath.Join(tempDir, "audio", "background.wav")
	info, err = os.Stat(bgMusicPath)
	require.NoError(t, err)
	assert.True(t, info.Size() > 0)
}

func TestCreateTestImage(t *testing.T) {
	tempDir := filepath.Join(os.TempDir(), "test_image")
	defer func() {
		if err := os.RemoveAll(tempDir); err != nil {
			t.Logf("Failed to remove temp dir: %v", err)
		}
	}()

	imgPath := filepath.Join(tempDir, "test.jpg")
	err := CreateTestImage(imgPath, 100, 200, "test", &color.RGBA{255, 0, 0, 255})
	require.NoError(t, err)

	info, err := os.Stat(imgPath)
	require.NoError(t, err)
	assert.True(t, info.Size() > 0)
}

func TestCreateTestAudio(t *testing.T) {
	tempDir := filepath.Join(os.TempDir(), "test_audio")
	defer func() {
		if err := os.RemoveAll(tempDir); err != nil {
			t.Logf("Failed to remove temp dir: %v", err)
		}
	}()

	audioPath := filepath.Join(tempDir, "test.wav")
	err := CreateTestAudio(audioPath, 1.0, 440.0)
	require.NoError(t, err)

	info, err := os.Stat(audioPath)
	require.NoError(t, err)
	assert.True(t, info.Size() > 0)
}
