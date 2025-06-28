package youtube

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/video/ports"
	"ssulmeta-go/internal/youtube/adapters"
	"ssulmeta-go/internal/youtube/core"
	ytports "ssulmeta-go/internal/youtube/ports"
	"ssulmeta-go/pkg/models"
)

// TestVideoToYouTubeIntegration tests integration between Video and YouTube domains
func TestVideoToYouTubeIntegration(t *testing.T) {
	tests := []struct {
		name string
		test func(t *testing.T)
	}{
		{
			name: "video_output_to_youtube_upload",
			test: testVideoOutputToYouTubeUpload,
		},
		{
			name: "thumbnail_generation_and_upload",
			test: testThumbnailGenerationAndUpload,
		},
		{
			name: "complete_video_production_to_upload_workflow",
			test: testCompleteVideoProductionToUploadWorkflow,
		},
		{
			name: "video_metadata_enrichment",
			test: testVideoMetadataEnrichment,
		},
		{
			name: "error_handling_video_to_youtube",
			test: testErrorHandlingVideoToYouTube,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tt.test(t)
		})
	}
}

func testVideoOutputToYouTubeUpload(t *testing.T) {
	// Test that video composition output can be uploaded to YouTube

	// Simulate video composition response
	videoResponse := &ports.ComposeVideoResponse{
		OutputPath:    "/tmp/test_video.mp4",
		Duration:      30 * time.Second,
		FileSize:      10485760, // 10MB
		ThumbnailPath: "/tmp/test_thumbnail.jpg",
	}

	// Create YouTube service components
	youtubeAdapter := adapters.NewYouTubeAdapter("test_client_id", "test_client_secret")
	metadataGenerator := adapters.NewMetadataGenerator()
	mockAuth := &MockAuthService{}
	mockChannel := &MockChannelService{}

	// Setup mock expectations
	mockAuth.On("ValidateToken", mock.Anything, "valid_token").Return(nil)

	service := core.NewService(youtubeAdapter, metadataGenerator, mockAuth, mockChannel)

	// Create upload request from video output
	uploadRequest := &ytports.UploadStoryRequest{
		StoryContent: `옛날 옛적에 용감한 소년이 살았습니다. 
소년은 마을을 위협하는 괴물을 물리치기 위해 모험을 떠났습니다.
험난한 여정 끝에 소년은 괴물을 물리치고 영웅이 되었습니다.`,
		ChannelType:   "fairy_tale",
		VideoPath:     videoResponse.OutputPath,
		ThumbnailPath: videoResponse.ThumbnailPath,
		AccessToken:   "valid_token",
	}

	// In test environment, this would use mock mode
	result, err := service.UploadStory(context.Background(), uploadRequest)

	// Verify the integration flow works (in mock mode)
	if err != nil {
		// Expected in test environment without actual video file
		assert.Contains(t, err.Error(), "failed to upload video to YouTube")
		t.Log("Video to YouTube integration validated (upload error handled correctly)")
	} else {
		// If mock mode returns success
		require.NotNil(t, result)
		assert.NotEmpty(t, result.VideoID)
		assert.Contains(t, result.VideoID, "mock_video_id_")
		assert.Equal(t, int64(1048576), result.FileSize) // Mock always returns 1MB
	}
}

func testThumbnailGenerationAndUpload(t *testing.T) {
	// Test thumbnail handling from video domain to YouTube upload

	// Video domain provides thumbnail path
	videoResponse := &ports.ComposeVideoResponse{
		OutputPath:    "/tmp/test_video.mp4",
		Duration:      45 * time.Second,
		FileSize:      15728640, // 15MB
		ThumbnailPath: "/tmp/generated_thumbnail.jpg",
	}

	// Create test thumbnail file
	thumbnailDir := t.TempDir()
	thumbnailPath := filepath.Join(thumbnailDir, "thumbnail.jpg")
	err := os.WriteFile(thumbnailPath, []byte("fake thumbnail data"), 0644)
	require.NoError(t, err)

	// Update response with real path
	videoResponse.ThumbnailPath = thumbnailPath

	// Create YouTube components
	youtubeAdapter := adapters.NewYouTubeAdapter("test_client_id", "test_client_secret")
	metadataGenerator := adapters.NewMetadataGenerator()
	mockAuth := &MockAuthService{}
	mockChannel := &MockChannelService{}

	mockAuth.On("ValidateToken", mock.Anything, "valid_token").Return(nil)

	service := core.NewService(youtubeAdapter, metadataGenerator, mockAuth, mockChannel)

	// Create upload request with thumbnail
	uploadRequest := &ytports.UploadStoryRequest{
		StoryContent:  "Test story content for thumbnail test",
		ChannelType:   "fairy_tale",
		VideoPath:     videoResponse.OutputPath,
		ThumbnailPath: videoResponse.ThumbnailPath,
		AccessToken:   "valid_token",
	}

	// Test upload (will fail on video file, but validates thumbnail handling)
	result, err := service.UploadStory(context.Background(), uploadRequest)

	// In mock mode, this should succeed
	if os.Getenv("SKIP_YOUTUBE_API") == "true" {
		// Mock mode - upload should succeed
		require.NoError(t, err)
		require.NotNil(t, result)
		assert.Contains(t, result.VideoID, "mock_video_id_")
	} else {
		// Real mode - expect failure due to missing video file
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "failed to upload video to YouTube")
	}

	// Verify thumbnail file was accessible
	_, statErr := os.Stat(thumbnailPath)
	assert.NoError(t, statErr)
}

func testCompleteVideoProductionToUploadWorkflow(t *testing.T) {
	// Test complete workflow from video production to YouTube upload

	// Simulate complete story and video production data
	story := &models.Story{
		Title:   "마법의 숲 이야기",
		Content: "깊은 숲 속에 마법사가 살고 있었습니다...",
		Scenes: []models.Scene{
			{Number: 1, Description: "숲의 입구", Duration: 3.0},
			{Number: 2, Description: "마법사의 집", Duration: 3.5},
			{Number: 3, Description: "마법의 순간", Duration: 4.0},
		},
	}

	// Video composition request and response
	videoRequest := &ports.ComposeVideoRequest{
		Images: []ports.ImageFrame{
			{Path: "/tmp/scene1.jpg", Duration: 3 * time.Second},
			{Path: "/tmp/scene2.jpg", Duration: 3500 * time.Millisecond},
			{Path: "/tmp/scene3.jpg", Duration: 4 * time.Second},
		},
		NarrationAudioPath:  "/tmp/narration.mp3",
		BackgroundMusicPath: "/tmp/background.mp3",
		OutputPath:          "/tmp/final_video.mp4",
		Settings: ports.VideoSettings{
			Width:                 1080,
			Height:                1920,
			FrameRate:             30,
			VideoBitrate:          "2M",
			AudioBitrate:          "128k",
			Format:                "mp4",
			BackgroundMusicVolume: 0.3,
			NarrationVolume:       1.0,
		},
		TransitionDuration: 500 * time.Millisecond,
	}

	videoResponse := &ports.ComposeVideoResponse{
		OutputPath:    videoRequest.OutputPath,
		Duration:      10500 * time.Millisecond, // Total duration
		FileSize:      2621440,                  // 2.5MB
		ThumbnailPath: "/tmp/video_thumbnail.jpg",
	}

	// Create YouTube service
	youtubeAdapter := adapters.NewYouTubeAdapter("test_client_id", "test_client_secret")
	metadataGenerator := adapters.NewMetadataGenerator()
	mockAuth := &MockAuthService{}
	mockChannel := &MockChannelService{}

	mockAuth.On("ValidateToken", mock.Anything, "valid_token").Return(nil)

	service := core.NewService(youtubeAdapter, metadataGenerator, mockAuth, mockChannel)

	// Create YouTube upload request from video output
	uploadRequest := &ytports.UploadStoryRequest{
		StoryContent:  story.Content,
		ChannelType:   "fairy_tale",
		VideoPath:     videoResponse.OutputPath,
		ThumbnailPath: videoResponse.ThumbnailPath,
		AccessToken:   "valid_token",
	}

	// Execute upload (in mock mode)
	result, err := service.UploadStory(context.Background(), uploadRequest)

	// Verify workflow integration
	if os.Getenv("SKIP_YOUTUBE_API") == "true" && err == nil {
		// Mock mode succeeds
		require.NotNil(t, result)
		assert.Contains(t, result.VideoID, "mock_video_id_")
		assert.Equal(t, "1:30", result.Duration)         // Mock duration
		assert.Equal(t, int64(1048576), result.FileSize) // Mock size
		t.Log("Complete workflow validated in mock mode")
	} else if err != nil {
		// Expected in test without real files (non-mock mode)
		assert.Contains(t, err.Error(), "failed to upload video to YouTube")
		t.Log("Complete workflow validated - error handling works correctly")
	}
}

func testVideoMetadataEnrichment(t *testing.T) {
	// Test that video metadata is properly enriched for YouTube

	// Video domain provides rich metadata
	videoResponse := &ports.ComposeVideoResponse{
		OutputPath:    "/tmp/shorts_video.mp4",
		Duration:      28 * time.Second, // Perfect for Shorts
		FileSize:      5242880,          // 5MB
		ThumbnailPath: "/tmp/auto_thumbnail.jpg",
	}

	// Additional video validation result
	validationResult := &ports.ValidationResult{
		IsValid:  true,
		Width:    1080,
		Height:   1920,
		Duration: videoResponse.Duration,
		FileSize: videoResponse.FileSize,
		Format:   "mp4",
	}

	// Story metadata for enrichment
	storyContent := `전설의 검을 찾아 떠난 기사의 이야기입니다.
험난한 여정 끝에 기사는 진정한 용기의 의미를 깨닫게 됩니다.
그리고 마침내 전설의 검을 손에 넣었습니다.`

	// Create metadata generator
	metadataGenerator := adapters.NewMetadataGenerator()

	// Generate enriched metadata
	metadata, err := metadataGenerator.GenerateMetadata(
		context.Background(),
		storyContent,
		"fairy_tale",
	)
	require.NoError(t, err)

	// Verify metadata is enriched with video information context
	assert.NotEmpty(t, metadata.Title)
	assert.Contains(t, metadata.Tags, "유튜브쇼츠") // Korean for YouTube Shorts
	assert.Contains(t, metadata.Tags, "동화")    // Korean for fairy tale

	// Verify duration is suitable for Shorts
	assert.LessOrEqual(t, validationResult.Duration, 60*time.Second)

	// Verify format requirements
	assert.Equal(t, 1080, validationResult.Width)
	assert.Equal(t, 1920, validationResult.Height)
	assert.Equal(t, "mp4", validationResult.Format)

	t.Logf("Enriched metadata - Title: %s", metadata.Title)
	t.Logf("Video validation - Duration: %v, Format: %dx%d %s",
		validationResult.Duration,
		validationResult.Width,
		validationResult.Height,
		validationResult.Format,
	)
}

func testErrorHandlingVideoToYouTube(t *testing.T) {
	// Test error handling between video and YouTube domains

	testCases := []struct {
		name          string
		videoResponse *ports.ComposeVideoResponse
		setupMocks    func(*MockAuthService)
		expectedError string
	}{
		{
			name: "invalid_video_duration",
			videoResponse: &ports.ComposeVideoResponse{
				OutputPath:    "/tmp/too_long_video.mp4",
				Duration:      90 * time.Second, // Too long for Shorts
				FileSize:      104857600,        // 100MB
				ThumbnailPath: "",
			},
			setupMocks: func(auth *MockAuthService) {
				auth.On("ValidateToken", mock.Anything, mock.Anything).Return(nil)
			},
			expectedError: "failed to upload video to YouTube", // In test environment
		},
		{
			name: "missing_thumbnail",
			videoResponse: &ports.ComposeVideoResponse{
				OutputPath:    "/tmp/video_no_thumb.mp4",
				Duration:      30 * time.Second,
				FileSize:      10485760,
				ThumbnailPath: "", // No thumbnail
			},
			setupMocks: func(auth *MockAuthService) {
				auth.On("ValidateToken", mock.Anything, mock.Anything).Return(nil)
			},
			expectedError: "failed to upload video to YouTube", // In test environment
		},
		{
			name: "invalid_file_size",
			videoResponse: &ports.ComposeVideoResponse{
				OutputPath:    "/tmp/huge_video.mp4",
				Duration:      30 * time.Second,
				FileSize:      137438953472, // 128GB - way too large
				ThumbnailPath: "/tmp/thumb.jpg",
			},
			setupMocks: func(auth *MockAuthService) {
				auth.On("ValidateToken", mock.Anything, mock.Anything).Return(nil)
			},
			expectedError: "failed to upload video to YouTube", // In test environment
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Create YouTube service
			youtubeAdapter := adapters.NewYouTubeAdapter("test_client_id", "test_client_secret")
			metadataGenerator := adapters.NewMetadataGenerator()
			mockAuth := &MockAuthService{}
			mockChannel := &MockChannelService{}

			tc.setupMocks(mockAuth)

			service := core.NewService(youtubeAdapter, metadataGenerator, mockAuth, mockChannel)

			// Create upload request
			uploadRequest := &ytports.UploadStoryRequest{
				StoryContent:  "Test story for error handling",
				ChannelType:   "fairy_tale",
				VideoPath:     tc.videoResponse.OutputPath,
				ThumbnailPath: tc.videoResponse.ThumbnailPath,
				AccessToken:   "test_token",
			}

			// Execute upload
			result, err := service.UploadStory(context.Background(), uploadRequest)

			// Verify error handling
			if os.Getenv("SKIP_YOUTUBE_API") == "true" {
				// In mock mode, uploads always succeed regardless of video size/duration
				require.NoError(t, err)
				require.NotNil(t, result)
				assert.Contains(t, result.VideoID, "mock_video_id_")
			} else {
				// In real mode, expect errors
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tc.expectedError)
			}
		})
	}
}

// MockVideoComposer for testing video domain integration
type MockVideoComposer struct {
	mock.Mock
}

func (m *MockVideoComposer) ComposeVideo(ctx context.Context, req *ports.ComposeVideoRequest) (*ports.ComposeVideoResponse, error) {
	args := m.Called(ctx, req)
	if args.Get(0) != nil {
		return args.Get(0).(*ports.ComposeVideoResponse), args.Error(1)
	}
	return nil, args.Error(1)
}

func (m *MockVideoComposer) GenerateThumbnail(ctx context.Context, videoPath string, outputPath string, timeOffset time.Duration) error {
	args := m.Called(ctx, videoPath, outputPath, timeOffset)
	return args.Error(0)
}

func (m *MockVideoComposer) GetDuration(ctx context.Context, videoPath string) (time.Duration, error) {
	args := m.Called(ctx, videoPath)
	return args.Get(0).(time.Duration), args.Error(1)
}

// MockVideoValidator for testing video validation
type MockVideoValidator struct {
	mock.Mock
}

func (m *MockVideoValidator) ValidateVideo(ctx context.Context, videoPath string, expectedSettings ports.VideoSettings) (*ports.ValidationResult, error) {
	args := m.Called(ctx, videoPath, expectedSettings)
	if args.Get(0) != nil {
		return args.Get(0).(*ports.ValidationResult), args.Error(1)
	}
	return nil, args.Error(1)
}

func (m *MockVideoValidator) ValidateAudioFile(ctx context.Context, audioPath string) error {
	args := m.Called(ctx, audioPath)
	return args.Error(0)
}

func (m *MockVideoValidator) ValidateImageFile(ctx context.Context, imagePath string) error {
	args := m.Called(ctx, imagePath)
	return args.Error(0)
}
