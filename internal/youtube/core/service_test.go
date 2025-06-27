package core

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/youtube/ports"
	"ssulmeta-go/pkg/errors"
)

// MockUploader is a mock implementation of the Uploader interface
type MockUploader struct {
	mock.Mock
}

func (m *MockUploader) UploadVideo(ctx context.Context, video *ports.Video, progressCallback func(*ports.UploadProgress)) (*ports.UploadResult, error) {
	args := m.Called(ctx, video, progressCallback)
	return args.Get(0).(*ports.UploadResult), args.Error(1)
}

func (m *MockUploader) UpdateVideo(ctx context.Context, videoID string, metadata *ports.Metadata) error {
	args := m.Called(ctx, videoID, metadata)
	return args.Error(0)
}

func (m *MockUploader) DeleteVideo(ctx context.Context, videoID string) error {
	args := m.Called(ctx, videoID)
	return args.Error(0)
}

func (m *MockUploader) GetVideo(ctx context.Context, videoID string) (*ports.UploadResult, error) {
	args := m.Called(ctx, videoID)
	return args.Get(0).(*ports.UploadResult), args.Error(1)
}

// MockMetadataGenerator is a mock implementation of the MetadataGenerator interface
type MockMetadataGenerator struct {
	mock.Mock
}

func (m *MockMetadataGenerator) GenerateMetadata(ctx context.Context, storyContent string, channelType string) (*ports.Metadata, error) {
	args := m.Called(ctx, storyContent, channelType)
	return args.Get(0).(*ports.Metadata), args.Error(1)
}

func (m *MockMetadataGenerator) GenerateTitle(ctx context.Context, storyContent string, channelType string) (string, error) {
	args := m.Called(ctx, storyContent, channelType)
	return args.String(0), args.Error(1)
}

func (m *MockMetadataGenerator) GenerateDescription(ctx context.Context, storyContent string, title string, channelType string) (string, error) {
	args := m.Called(ctx, storyContent, title, channelType)
	return args.String(0), args.Error(1)
}

func (m *MockMetadataGenerator) GenerateTags(ctx context.Context, storyContent string, channelType string) ([]string, error) {
	args := m.Called(ctx, storyContent, channelType)
	return args.Get(0).([]string), args.Error(1)
}

// MockAuthService is a mock implementation of the AuthService interface
type MockAuthService struct {
	mock.Mock
}

func (m *MockAuthService) GetAuthURL(state string) string {
	args := m.Called(state)
	return args.String(0)
}

func (m *MockAuthService) ExchangeCode(ctx context.Context, code string) (*ports.AuthToken, error) {
	args := m.Called(ctx, code)
	return args.Get(0).(*ports.AuthToken), args.Error(1)
}

func (m *MockAuthService) RefreshToken(ctx context.Context, refreshToken string) (*ports.AuthToken, error) {
	args := m.Called(ctx, refreshToken)
	return args.Get(0).(*ports.AuthToken), args.Error(1)
}

func (m *MockAuthService) ValidateToken(ctx context.Context, accessToken string) error {
	args := m.Called(ctx, accessToken)
	return args.Error(0)
}

func (m *MockAuthService) RevokeToken(ctx context.Context, token string) error {
	args := m.Called(ctx, token)
	return args.Error(0)
}

// MockChannelService is a mock implementation of the ChannelService interface
type MockChannelService struct {
	mock.Mock
}

func (m *MockChannelService) GetChannelInfo(ctx context.Context, accessToken string) (*ports.ChannelInfo, error) {
	args := m.Called(ctx, accessToken)
	return args.Get(0).(*ports.ChannelInfo), args.Error(1)
}

func (m *MockChannelService) ListVideos(ctx context.Context, accessToken string, maxResults int) ([]*ports.UploadResult, error) {
	args := m.Called(ctx, accessToken, maxResults)
	return args.Get(0).([]*ports.UploadResult), args.Error(1)
}

func (m *MockChannelService) GetChannelAnalytics(ctx context.Context, accessToken string, startDate, endDate time.Time) (map[string]interface{}, error) {
	args := m.Called(ctx, accessToken, startDate, endDate)
	return args.Get(0).(map[string]interface{}), args.Error(1)
}

func TestService_UploadStory(t *testing.T) {
	tests := []struct {
		name           string
		request        *ports.UploadStoryRequest
		setupMocks     func(*MockUploader, *MockMetadataGenerator, *MockAuthService)
		expectedResult *ports.UploadStoryResult
		expectedError  string
	}{
		{
			name: "성공적인 스토리 업로드",
			request: &ports.UploadStoryRequest{
				StoryContent:  "옛날 옛적에 한 왕국에 아름다운 공주가 살고 있었습니다. 공주는 매일 성 밖으로 나가 백성들과 함께 지내며 모든 이들에게 사랑받았습니다. 어느 날 마법사가 나타나 공주에게 특별한 능력을 주었고, 공주는 그 능력으로 왕국을 더욱 평화롭게 만들었습니다.",
				ChannelType:   "fairy_tale",
				VideoPath:     "/path/to/video.mp4",
				ThumbnailPath: "/path/to/thumbnail.jpg",
				AccessToken:   "valid_access_token",
			},
			setupMocks: func(uploader *MockUploader, generator *MockMetadataGenerator, auth *MockAuthService) {
				// Mock metadata generation
				generator.On("GenerateMetadata", mock.Anything, mock.AnythingOfType("string"), "fairy_tale").Return(
					&ports.Metadata{
						Title:           "마법의 공주 이야기",
						Description:     "아름다운 공주와 마법사의 감동적인 이야기입니다.",
						Tags:            []string{"동화", "공주", "마법", "교육"},
						CategoryID:      "27",
						DefaultLanguage: "ko",
						Privacy:         "public",
					}, nil)

				// Mock token validation
				auth.On("ValidateToken", mock.Anything, "valid_access_token").Return(nil)

				// Mock video upload
				uploader.On("UploadVideo", mock.Anything, mock.AnythingOfType("*ports.Video"), mock.AnythingOfType("func(*ports.UploadProgress)")).Return(
					&ports.UploadResult{
						VideoID:      "test_video_id_123",
						URL:          "https://www.youtube.com/watch?v=test_video_id_123",
						Title:        "마법의 공주 이야기",
						UploadedAt:   time.Now(),
						Status:       "processed",
						Duration:     "1:30",
						FileSize:     15728640, // 15MB
						ThumbnailURL: "https://i.ytimg.com/vi/test_video_id_123/maxresdefault.jpg",
					}, nil)
			},
			expectedResult: &ports.UploadStoryResult{
				VideoID:      "test_video_id_123",
				URL:          "https://www.youtube.com/watch?v=test_video_id_123",
				Title:        "마법의 공주 이야기",
				Status:       "processed",
				Duration:     "1:30",
				FileSize:     15728640,
				ThumbnailURL: "https://i.ytimg.com/vi/test_video_id_123/maxresdefault.jpg",
			},
		},
		{
			name: "잘못된 접근 토큰으로 인한 실패",
			request: &ports.UploadStoryRequest{
				StoryContent: "옛날 옛적에...",
				ChannelType:  "fairy_tale",
				VideoPath:    "/path/to/video.mp4",
				AccessToken:  "invalid_token",
			},
			setupMocks: func(uploader *MockUploader, generator *MockMetadataGenerator, auth *MockAuthService) {
				auth.On("ValidateToken", mock.Anything, "invalid_token").Return(
					errors.NewExternalError(errors.CodeUnauthorized, "invalid access token", nil))
			},
			expectedError: "failed to validate access token",
		},
		{
			name: "메타데이터 생성 실패",
			request: &ports.UploadStoryRequest{
				StoryContent: "옛날 옛적에...",
				ChannelType:  "fairy_tale",
				VideoPath:    "/path/to/video.mp4",
				AccessToken:  "valid_access_token",
			},
			setupMocks: func(uploader *MockUploader, generator *MockMetadataGenerator, auth *MockAuthService) {
				auth.On("ValidateToken", mock.Anything, "valid_access_token").Return(nil)
				generator.On("GenerateMetadata", mock.Anything, mock.AnythingOfType("string"), "fairy_tale").Return(
					(*ports.Metadata)(nil), errors.NewExternalError(errors.CodeExternalAPIError, "metadata generation failed", nil))
			},
			expectedError: "failed to generate video metadata",
		},
		{
			name: "비디오 업로드 실패",
			request: &ports.UploadStoryRequest{
				StoryContent: "옛날 옛적에...",
				ChannelType:  "fairy_tale",
				VideoPath:    "/path/to/video.mp4",
				AccessToken:  "valid_access_token",
			},
			setupMocks: func(uploader *MockUploader, generator *MockMetadataGenerator, auth *MockAuthService) {
				auth.On("ValidateToken", mock.Anything, "valid_access_token").Return(nil)
				generator.On("GenerateMetadata", mock.Anything, mock.AnythingOfType("string"), "fairy_tale").Return(
					&ports.Metadata{Title: "Test Title"}, nil)
				uploader.On("UploadVideo", mock.Anything, mock.AnythingOfType("*ports.Video"), mock.AnythingOfType("func(*ports.UploadProgress)")).Return(
					(*ports.UploadResult)(nil), errors.NewExternalError(errors.CodeYouTubeUploadFailed, "upload failed", nil))
			},
			expectedError: "failed to upload video to YouTube",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create mocks
			mockUploader := &MockUploader{}
			mockGenerator := &MockMetadataGenerator{}
			mockAuth := &MockAuthService{}
			mockChannel := &MockChannelService{}

			// Setup mocks
			tt.setupMocks(mockUploader, mockGenerator, mockAuth)

			// Create service
			service := NewService(mockUploader, mockGenerator, mockAuth, mockChannel)

			// Execute test
			result, err := service.UploadStory(context.Background(), tt.request)

			// Verify result
			if tt.expectedError != "" {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
				assert.Nil(t, result)
			} else {
				require.NoError(t, err)
				require.NotNil(t, result)
				assert.Equal(t, tt.expectedResult.VideoID, result.VideoID)
				assert.Equal(t, tt.expectedResult.URL, result.URL)
				assert.Equal(t, tt.expectedResult.Title, result.Title)
				assert.Equal(t, tt.expectedResult.Status, result.Status)
			}

			// Verify mock expectations
			mockUploader.AssertExpectations(t)
			mockGenerator.AssertExpectations(t)
			mockAuth.AssertExpectations(t)
		})
	}
}

func TestService_GetChannelInfo(t *testing.T) {
	tests := []struct {
		name           string
		accessToken    string
		setupMocks     func(*MockChannelService, *MockAuthService)
		expectedResult *ports.ChannelInfo
		expectedError  string
	}{
		{
			name:        "성공적인 채널 정보 조회",
			accessToken: "valid_token",
			setupMocks: func(channel *MockChannelService, auth *MockAuthService) {
				auth.On("ValidateToken", mock.Anything, "valid_token").Return(nil)
				channel.On("GetChannelInfo", mock.Anything, "valid_token").Return(
					&ports.ChannelInfo{
						ID:          "UC123456789",
						Title:       "동화 채널",
						Description: "아이들을 위한 동화 이야기",
						Subscribers: 10000,
						VideoCount:  50,
						ViewCount:   1000000,
					}, nil)
			},
			expectedResult: &ports.ChannelInfo{
				ID:          "UC123456789",
				Title:       "동화 채널",
				Description: "아이들을 위한 동화 이야기",
				Subscribers: 10000,
				VideoCount:  50,
				ViewCount:   1000000,
			},
		},
		{
			name:        "잘못된 토큰으로 인한 실패",
			accessToken: "invalid_token",
			setupMocks: func(channel *MockChannelService, auth *MockAuthService) {
				auth.On("ValidateToken", mock.Anything, "invalid_token").Return(
					errors.NewExternalError(errors.CodeUnauthorized, "invalid token", nil))
			},
			expectedError: "failed to validate access token",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create mocks
			mockUploader := &MockUploader{}
			mockGenerator := &MockMetadataGenerator{}
			mockAuth := &MockAuthService{}
			mockChannel := &MockChannelService{}

			// Setup mocks
			tt.setupMocks(mockChannel, mockAuth)

			// Create service
			service := NewService(mockUploader, mockGenerator, mockAuth, mockChannel)

			// Execute test
			result, err := service.GetChannelInfo(context.Background(), tt.accessToken)

			// Verify result
			if tt.expectedError != "" {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
				assert.Nil(t, result)
			} else {
				require.NoError(t, err)
				require.NotNil(t, result)
				assert.Equal(t, tt.expectedResult.ID, result.ID)
				assert.Equal(t, tt.expectedResult.Title, result.Title)
				assert.Equal(t, tt.expectedResult.Subscribers, result.Subscribers)
			}

			// Verify mock expectations
			mockChannel.AssertExpectations(t)
			mockAuth.AssertExpectations(t)
		})
	}
}

func TestService_UpdateVideoMetadata(t *testing.T) {
	tests := []struct {
		name          string
		videoID       string
		metadata      *ports.Metadata
		accessToken   string
		setupMocks    func(*MockUploader, *MockAuthService)
		expectedError string
	}{
		{
			name:    "성공적인 메타데이터 업데이트",
			videoID: "test_video_123",
			metadata: &ports.Metadata{
				Title:       "업데이트된 제목",
				Description: "업데이트된 설명",
				Tags:        []string{"업데이트", "태그"},
			},
			accessToken: "valid_token",
			setupMocks: func(uploader *MockUploader, auth *MockAuthService) {
				auth.On("ValidateToken", mock.Anything, "valid_token").Return(nil)
				uploader.On("UpdateVideo", mock.Anything, "test_video_123", mock.AnythingOfType("*ports.Metadata")).Return(nil)
			},
		},
		{
			name:    "잘못된 토큰으로 인한 실패",
			videoID: "test_video_123",
			metadata: &ports.Metadata{
				Title: "업데이트된 제목",
			},
			accessToken: "invalid_token",
			setupMocks: func(uploader *MockUploader, auth *MockAuthService) {
				auth.On("ValidateToken", mock.Anything, "invalid_token").Return(
					errors.NewExternalError(errors.CodeUnauthorized, "invalid token", nil))
			},
			expectedError: "failed to validate access token",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create mocks
			mockUploader := &MockUploader{}
			mockGenerator := &MockMetadataGenerator{}
			mockAuth := &MockAuthService{}
			mockChannel := &MockChannelService{}

			// Setup mocks
			tt.setupMocks(mockUploader, mockAuth)

			// Create service
			service := NewService(mockUploader, mockGenerator, mockAuth, mockChannel)

			// Execute test
			err := service.UpdateVideoMetadata(context.Background(), tt.videoID, tt.metadata, tt.accessToken)

			// Verify result
			if tt.expectedError != "" {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				require.NoError(t, err)
			}

			// Verify mock expectations
			mockUploader.AssertExpectations(t)
			mockAuth.AssertExpectations(t)
		})
	}
}

func TestService_ValidateRequest(t *testing.T) {
	tests := []struct {
		name    string
		request *ports.UploadStoryRequest
		wantErr bool
		errMsg  string
	}{
		{
			name: "유효한 요청",
			request: &ports.UploadStoryRequest{
				StoryContent: "옛날 옛적에 한 왕국에...",
				ChannelType:  "fairy_tale",
				VideoPath:    "/path/to/video.mp4",
				AccessToken:  "valid_token",
			},
			wantErr: false,
		},
		{
			name: "빈 스토리 콘텐츠",
			request: &ports.UploadStoryRequest{
				StoryContent: "",
				ChannelType:  "fairy_tale",
				VideoPath:    "/path/to/video.mp4",
				AccessToken:  "valid_token",
			},
			wantErr: true,
			errMsg:  "story content is required",
		},
		{
			name: "빈 채널 타입",
			request: &ports.UploadStoryRequest{
				StoryContent: "옛날 옛적에...",
				ChannelType:  "",
				VideoPath:    "/path/to/video.mp4",
				AccessToken:  "valid_token",
			},
			wantErr: true,
			errMsg:  "channel type is required",
		},
		{
			name: "빈 비디오 경로",
			request: &ports.UploadStoryRequest{
				StoryContent: "옛날 옛적에...",
				ChannelType:  "fairy_tale",
				VideoPath:    "",
				AccessToken:  "valid_token",
			},
			wantErr: true,
			errMsg:  "video path is required",
		},
		{
			name: "빈 접근 토큰",
			request: &ports.UploadStoryRequest{
				StoryContent: "옛날 옛적에...",
				ChannelType:  "fairy_tale",
				VideoPath:    "/path/to/video.mp4",
				AccessToken:  "",
			},
			wantErr: true,
			errMsg:  "access token is required",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create service
			service := NewService(nil, nil, nil, nil)

			// Execute validation
			err := service.validateUploadRequest(tt.request)

			if tt.wantErr {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.errMsg)
			} else {
				require.NoError(t, err)
			}
		})
	}
}
