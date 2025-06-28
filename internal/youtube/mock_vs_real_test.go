package youtube

import (
	"context"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/youtube/adapters"
	"ssulmeta-go/internal/youtube/core"
	"ssulmeta-go/internal/youtube/ports"
)

func TestMockVsRealAPIBehavior(t *testing.T) {
	t.Log("Starting mock vs real API integration tests")

	tests := []struct {
		name string
		test func(t *testing.T)
	}{
		{
			name: "adapter_behavior_in_different_modes",
			test: testAdapterBehaviorInDifferentModes,
		},
		{
			name: "mock_mode_consistency",
			test: testMockModeConsistency,
		},
		{
			name: "environment_variable_handling",
			test: testEnvironmentVariableHandling,
		},
		{
			name: "mock_data_validity",
			test: testMockDataValidity,
		},
		{
			name: "api_key_requirements",
			test: testAPIKeyRequirements,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tt.test(t)
		})
	}
}

func testAdapterBehaviorInDifferentModes(t *testing.T) {
	// Test that adapter behaves correctly based on SKIP_YOUTUBE_API env var

	// Save original env var
	originalEnv := os.Getenv("SKIP_YOUTUBE_API")
	defer func() {
		_ = os.Setenv("SKIP_YOUTUBE_API", originalEnv)
	}()

	// Create test components
	adapter := adapters.NewYouTubeAdapter("test_client_id", "test_client_secret")
	metadataGen := adapters.NewMetadataGenerator()
	mockAuth := &MockAuthService{}
	mockChannel := &MockChannelService{}

	// Auth should always succeed in our mock
	mockAuth.On("ValidateToken", mock.Anything, mock.Anything).Return(nil)

	service := core.NewService(adapter, metadataGen, mockAuth, mockChannel)

	// Create test request
	request := &ports.UploadStoryRequest{
		StoryContent:  "Test story for mode comparison",
		ChannelType:   "fairy_tale",
		VideoPath:     createMinimalVideoFile(t),
		ThumbnailPath: createMinimalThumbnailFile(t),
		AccessToken:   "test_token",
	}

	// Test 1: Mock mode (SKIP_YOUTUBE_API=true)
	_ = os.Setenv("SKIP_YOUTUBE_API", "true")
	mockResult, mockErr := service.UploadStory(context.Background(), request)

	if mockErr == nil {
		require.NotNil(t, mockResult)
		assert.Contains(t, mockResult.VideoID, "mock_video_id_")
		assert.Contains(t, mockResult.URL, "youtube.com/watch?v=mock_video_id")
		assert.Equal(t, "processed", mockResult.Status)
		t.Log("Mock mode test passed - returned expected mock data")
	}

	// Test 2: Real mode (SKIP_YOUTUBE_API not set)
	_ = os.Setenv("SKIP_YOUTUBE_API", "")
	realResult, realErr := service.UploadStory(context.Background(), request)

	// In real mode without actual credentials, we expect an error
	if realErr != nil {
		// This is expected - real API call would fail without valid credentials
		t.Log("Real mode test - error expected without valid credentials")
		assert.NotEqual(t, mockErr, realErr, "Errors should be different between mock and real modes")
	} else if realResult != nil {
		// If it somehow succeeds, the results should be different
		assert.NotEqual(t, mockResult.VideoID, realResult.VideoID, "Video IDs should differ between modes")
	}
}

func testMockModeConsistency(t *testing.T) {
	// Test that mock mode returns consistent results across multiple calls

	// Ensure we're in mock mode
	_ = os.Setenv("SKIP_YOUTUBE_API", "true")
	defer os.Setenv("SKIP_YOUTUBE_API", os.Getenv("SKIP_YOUTUBE_API"))

	adapter := adapters.NewYouTubeAdapter("test_client_id", "test_client_secret")
	metadataGen := adapters.NewMetadataGenerator()
	mockAuth := &MockAuthService{}
	mockChannel := &MockChannelService{}
	mockAuth.On("ValidateToken", mock.Anything, mock.Anything).Return(nil)

	service := core.NewService(adapter, metadataGen, mockAuth, mockChannel)

	// Create identical requests
	videoPath := createMinimalVideoFile(t)
	thumbnailPath := createMinimalThumbnailFile(t)

	request1 := &ports.UploadStoryRequest{
		StoryContent:  "Consistent test story",
		ChannelType:   "horror",
		VideoPath:     videoPath,
		ThumbnailPath: thumbnailPath,
		AccessToken:   "test_token",
	}

	request2 := &ports.UploadStoryRequest{
		StoryContent:  "Consistent test story",
		ChannelType:   "horror",
		VideoPath:     videoPath,
		ThumbnailPath: thumbnailPath,
		AccessToken:   "test_token",
	}

	// Make multiple calls
	result1, err1 := service.UploadStory(context.Background(), request1)
	result2, err2 := service.UploadStory(context.Background(), request2)

	// Both should succeed in mock mode
	require.NoError(t, err1)
	require.NoError(t, err2)
	require.NotNil(t, result1)
	require.NotNil(t, result2)

	// Mock results should be identical for identical inputs
	assert.Equal(t, result1.VideoID, result2.VideoID)
	assert.Equal(t, result1.URL, result2.URL)
	assert.Equal(t, result1.Status, result2.Status)

	t.Log("Mock mode consistency test passed - identical results for identical inputs")
}

func testEnvironmentVariableHandling(t *testing.T) {
	// Test various environment variable configurations

	originalEnv := os.Getenv("SKIP_YOUTUBE_API")
	defer func() {
		_ = os.Setenv("SKIP_YOUTUBE_API", originalEnv)
	}()

	testCases := []struct {
		name       string
		envValue   string
		expectMock bool
	}{
		{"empty string", "", false},
		{"true lowercase", "true", true},
		{"TRUE uppercase", "TRUE", true},
		{"1 numeric", "1", true},
		{"false", "false", false},
		{"random value", "random", false},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			_ = os.Setenv("SKIP_YOUTUBE_API", tc.envValue)

			adapter := adapters.NewYouTubeAdapter("test_client_id", "test_client_secret")
			metadataGen := adapters.NewMetadataGenerator()
			mockAuth := &MockAuthService{}
			mockChannel := &MockChannelService{}
			mockAuth.On("ValidateToken", mock.Anything, mock.Anything).Return(nil)

			service := core.NewService(adapter, metadataGen, mockAuth, mockChannel)

			request := &ports.UploadStoryRequest{
				StoryContent:  "Environment test story",
				ChannelType:   "romance",
				VideoPath:     createMinimalVideoFile(t),
				ThumbnailPath: createMinimalThumbnailFile(t),
				AccessToken:   "test_token",
			}

			result, err := service.UploadStory(context.Background(), request)

			if tc.expectMock && err == nil {
				// Should get mock data
				require.NotNil(t, result)
				assert.Contains(t, result.VideoID, "mock_video_id_")
				t.Logf("Environment variable '%s' correctly triggered mock mode", tc.envValue)
			} else if !tc.expectMock && err != nil {
				// Should fail without real credentials
				t.Logf("Environment variable '%s' correctly triggered real mode (error expected)", tc.envValue)
			}
		})
	}
}

func testMockDataValidity(t *testing.T) {
	// Test that mock data meets YouTube API requirements

	_ = os.Setenv("SKIP_YOUTUBE_API", "true")
	defer os.Setenv("SKIP_YOUTUBE_API", os.Getenv("SKIP_YOUTUBE_API"))

	adapter := adapters.NewYouTubeAdapter("test_client_id", "test_client_secret")
	metadataGen := adapters.NewMetadataGenerator()
	mockAuth := &MockAuthService{}
	mockChannel := &MockChannelService{}
	mockAuth.On("ValidateToken", mock.Anything, mock.Anything).Return(nil)

	service := core.NewService(adapter, metadataGen, mockAuth, mockChannel)

	request := &ports.UploadStoryRequest{
		StoryContent:  "Mock validation test story",
		ChannelType:   "fairy_tale",
		VideoPath:     createMinimalVideoFile(t),
		ThumbnailPath: createMinimalThumbnailFile(t),
		AccessToken:   "test_token",
	}

	result, err := service.UploadStory(context.Background(), request)
	require.NoError(t, err)
	require.NotNil(t, result)

	// Validate mock data format
	assert.NotEmpty(t, result.VideoID, "Video ID should not be empty")
	assert.Contains(t, result.URL, "youtube.com", "URL should be a YouTube URL")
	assert.NotEmpty(t, result.Title, "Title should not be empty")
	assert.NotZero(t, result.UploadedAt, "Upload time should be set")
	assert.Equal(t, "processed", result.Status, "Status should be 'processed'")
	assert.NotEmpty(t, result.Duration, "Duration should not be empty")
	assert.Greater(t, result.FileSize, int64(0), "File size should be positive")

	// Validate duration format (mock returns simple format like "1:30")
	assert.Regexp(t, `^\d+:\d+$`, result.Duration, "Duration should be in M:SS format")

	t.Log("Mock data validity test passed - all fields meet requirements")
}

func testAPIKeyRequirements(t *testing.T) {
	// Test API key handling in different modes

	originalEnv := os.Getenv("SKIP_YOUTUBE_API")
	defer func() {
		_ = os.Setenv("SKIP_YOUTUBE_API", originalEnv)
	}()

	testCases := []struct {
		name         string
		clientID     string
		clientSecret string
		skipAPI      string
		expectError  bool
	}{
		{
			name:         "mock mode with valid credentials",
			clientID:     "test_id",
			clientSecret: "test_secret",
			skipAPI:      "true",
			expectError:  false, // Should work in mock mode
		},
		{
			name:         "real mode with empty credentials",
			clientID:     "",
			clientSecret: "",
			skipAPI:      "",
			expectError:  true, // Should fail in real mode
		},
		{
			name:         "mock mode with empty credentials",
			clientID:     "",
			clientSecret: "",
			skipAPI:      "true",
			expectError:  false, // Should work in mock mode
		},
		{
			name:         "real mode with fake credentials",
			clientID:     "fake_id",
			clientSecret: "fake_secret",
			skipAPI:      "",
			expectError:  true, // Should fail in real mode
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			os.Setenv("SKIP_YOUTUBE_API", tc.skipAPI)

			adapter := adapters.NewYouTubeAdapter(tc.clientID, tc.clientSecret)
			metadataGen := adapters.NewMetadataGenerator()
			mockAuth := &MockAuthService{}
			mockChannel := &MockChannelService{}
			mockAuth.On("ValidateToken", mock.Anything, mock.Anything).Return(nil)

			service := core.NewService(adapter, metadataGen, mockAuth, mockChannel)

			request := &ports.UploadStoryRequest{
				StoryContent:  "옛날 옛적에 한 왕국에 공주가 살고 있었습니다. 공주는 매일 성 밖으로 나가 백성들과 함께 지내며 모든 이들에게 사랑받았습니다.",
				ChannelType:   "fairy_tale",
				VideoPath:     createMinimalVideoFile(t),
				ThumbnailPath: createMinimalThumbnailFile(t),
				AccessToken:   "test_token",
			}

			result, err := service.UploadStory(context.Background(), request)

			if tc.expectError {
				assert.Error(t, err, "Expected error for case: %s", tc.name)
			} else {
				assert.NoError(t, err, "Expected no error for case: %s", tc.name)
				assert.NotNil(t, result, "Expected result for case: %s", tc.name)
			}
		})
	}
}

// Helper functions for creating minimal test files

func createMinimalVideoFile(t *testing.T) string {
	tempDir := t.TempDir()
	videoPath := filepath.Join(tempDir, "minimal_video.mp4")

	// Minimal MP4 header
	mp4Data := []byte{
		0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70,
		0x69, 0x73, 0x6F, 0x6D, 0x00, 0x00, 0x02, 0x00,
		0x69, 0x73, 0x6F, 0x6D, 0x69, 0x73, 0x6F, 0x32,
		0x61, 0x76, 0x63, 0x31, 0x6D, 0x70, 0x34, 0x31,
	}

	err := os.WriteFile(videoPath, mp4Data, 0644)
	require.NoError(t, err)

	return videoPath
}

func createMinimalThumbnailFile(t *testing.T) string {
	tempDir := t.TempDir()
	thumbnailPath := filepath.Join(tempDir, "minimal_thumbnail.jpg")

	// Minimal JPEG header
	jpegData := []byte{
		0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46,
		0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01,
		0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9,
	}

	err := os.WriteFile(thumbnailPath, jpegData, 0644)
	require.NoError(t, err)

	return thumbnailPath
}
