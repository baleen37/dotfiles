package adapters

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/youtube/ports"
)

func TestYouTubeAdapter_UploadVideo(t *testing.T) {
	tests := []struct {
		name            string
		video           *ports.Video
		mockAPIResponse map[string]interface{}
		expectedResult  *ports.UploadResult
		expectedError   string
		skipInTest      bool // Skip actual API calls in test environment
	}{
		{
			name: "성공적인 비디오 업로드",
			video: &ports.Video{
				Title:       "테스트 동화 비디오",
				Description: "아이들을 위한 재미있는 동화 이야기입니다.",
				Tags:        []string{"동화", "아이들", "교육"},
				CategoryID:  "27", // Education
				Privacy:     "public",
				VideoPath:   "/path/to/test/video.mp4",
				Thumbnail:   "/path/to/test/thumbnail.jpg",
			},
			mockAPIResponse: map[string]interface{}{
				"id": "test_video_id_123",
				"snippet": map[string]interface{}{
					"title":       "테스트 동화 비디오",
					"description": "아이들을 위한 재미있는 동화 이야기입니다.",
					"tags":        []string{"동화", "아이들", "교육"},
					"categoryId":  "27",
				},
				"status": map[string]interface{}{
					"privacyStatus": "public",
					"uploadStatus":  "processed",
				},
				"contentDetails": map[string]interface{}{
					"duration": "PT1M30S", // ISO 8601 duration
				},
				"statistics": map[string]interface{}{
					"viewCount": "0",
				},
			},
			expectedResult: &ports.UploadResult{
				VideoID:    "test_video_id_123",
				URL:        "https://www.youtube.com/watch?v=test_video_id_123",
				Title:      "테스트 동화 비디오",
				Status:     "processed",
				Duration:   "1:30",
				FileSize:   15728640,   // Will be read from file
				UploadedAt: time.Now(), // Will be set during upload
			},
			skipInTest: true,
		},
		{
			name: "잘못된 비디오 파일 경로",
			video: &ports.Video{
				Title:     "테스트 비디오",
				VideoPath: "/non/existent/video.mp4",
			},
			expectedError: "video file not found",
			skipInTest:    true,
		},
		{
			name: "YouTube API 할당량 초과",
			video: &ports.Video{
				Title:     "테스트 비디오",
				VideoPath: "/path/to/valid/video.mp4",
			},
			expectedError: "quota exceeded",
			skipInTest:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.skipInTest {
				t.Skip("Skipping actual YouTube API test - requires real credentials and file")
			}

			// In a real test environment, we would use mock HTTP responses
			// For now, we'll test the interface compliance and error handling

			adapter := NewYouTubeAdapter("test_client_id", "test_client_secret")
			require.NotNil(t, adapter)

			// Test that adapter implements the interface
			var _ ports.Uploader = adapter
		})
	}
}

func TestYouTubeAdapter_ValidateVideo(t *testing.T) {
	tests := []struct {
		name          string
		video         *ports.Video
		expectedError string
	}{
		{
			name: "유효한 비디오",
			video: &ports.Video{
				Title:       "유효한 제목",
				Description: "유효한 설명입니다.",
				Tags:        []string{"태그1", "태그2"},
				CategoryID:  "27",
				Privacy:     "public",
				VideoPath:   "/path/to/video.mp4",
			},
		},
		{
			name: "빈 제목",
			video: &ports.Video{
				Title:     "",
				VideoPath: "/path/to/video.mp4",
			},
			expectedError: "title is required",
		},
		{
			name: "너무 긴 제목",
			video: &ports.Video{
				Title:     "이것은 매우 긴 제목입니다. YouTube는 제목의 길이를 100자로 제한하고 있습니다. 이 제목은 그 제한을 초과하는 매우 긴 제목입니다. 테스트를 위해 작성된 제목입니다.",
				VideoPath: "/path/to/video.mp4",
			},
			expectedError: "title exceeds maximum length",
		},
		{
			name: "빈 비디오 경로",
			video: &ports.Video{
				Title:     "유효한 제목",
				VideoPath: "",
			},
			expectedError: "video path is required",
		},
		{
			name: "잘못된 프라이버시 설정",
			video: &ports.Video{
				Title:     "유효한 제목",
				VideoPath: "/path/to/video.mp4",
				Privacy:   "invalid_privacy",
			},
			expectedError: "invalid privacy setting",
		},
		{
			name: "태그 수 초과",
			video: &ports.Video{
				Title:     "유효한 제목",
				VideoPath: "/path/to/video.mp4",
				Tags:      make([]string, 501), // YouTube limits to 500 tags
			},
			expectedError: "too many tags",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			adapter := NewYouTubeAdapter("test_client_id", "test_client_secret")

			err := adapter.validateVideo(tt.video)

			if tt.expectedError != "" {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

func TestYouTubeAdapter_UpdateVideo(t *testing.T) {
	tests := []struct {
		name          string
		videoID       string
		metadata      *ports.Metadata
		expectedError string
		skipInTest    bool
	}{
		{
			name:    "성공적인 메타데이터 업데이트",
			videoID: "valid_video_id",
			metadata: &ports.Metadata{
				Title:       "업데이트된 제목",
				Description: "업데이트된 설명",
				Tags:        []string{"업데이트", "태그"},
				Privacy:     "public",
			},
			skipInTest: true,
		},
		{
			name:    "빈 비디오 ID",
			videoID: "",
			metadata: &ports.Metadata{
				Title: "제목",
			},
			expectedError: "video ID is required",
		},
		{
			name:          "빈 메타데이터",
			videoID:       "valid_video_id",
			metadata:      nil,
			expectedError: "metadata is required",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.skipInTest {
				t.Skip("Skipping actual YouTube API test - requires real credentials")
			}

			adapter := NewYouTubeAdapter("test_client_id", "test_client_secret")

			err := adapter.UpdateVideo(context.Background(), tt.videoID, tt.metadata)

			if tt.expectedError != "" {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

func TestYouTubeAdapter_DeleteVideo(t *testing.T) {
	tests := []struct {
		name          string
		videoID       string
		expectedError string
		skipInTest    bool
	}{
		{
			name:       "성공적인 비디오 삭제",
			videoID:    "valid_video_id",
			skipInTest: true,
		},
		{
			name:          "빈 비디오 ID",
			videoID:       "",
			expectedError: "video ID is required",
		},
		{
			name:          "존재하지 않는 비디오",
			videoID:       "non_existent_video_id",
			expectedError: "video not found",
			skipInTest:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.skipInTest {
				t.Skip("Skipping actual YouTube API test - requires real credentials")
			}

			adapter := NewYouTubeAdapter("test_client_id", "test_client_secret")

			err := adapter.DeleteVideo(context.Background(), tt.videoID)

			if tt.expectedError != "" {
				require.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedError)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

func TestYouTubeAdapter_GetVideo(t *testing.T) {
	tests := []struct {
		name            string
		videoID         string
		mockAPIResponse map[string]interface{}
		expectedResult  *ports.UploadResult
		expectedError   string
		skipInTest      bool
	}{
		{
			name:    "성공적인 비디오 정보 조회",
			videoID: "valid_video_id",
			mockAPIResponse: map[string]interface{}{
				"id": "valid_video_id",
				"snippet": map[string]interface{}{
					"title":       "기존 비디오 제목",
					"description": "기존 비디오 설명",
					"publishedAt": "2024-01-01T00:00:00Z",
				},
				"status": map[string]interface{}{
					"uploadStatus": "processed",
				},
				"contentDetails": map[string]interface{}{
					"duration": "PT2M15S",
				},
				"statistics": map[string]interface{}{
					"viewCount": "1000",
				},
			},
			expectedResult: &ports.UploadResult{
				VideoID:  "valid_video_id",
				URL:      "https://www.youtube.com/watch?v=valid_video_id",
				Title:    "기존 비디오 제목",
				Status:   "processed",
				Duration: "2:15",
			},
			skipInTest: true,
		},
		{
			name:          "빈 비디오 ID",
			videoID:       "",
			expectedError: "video ID is required",
		},
		{
			name:          "존재하지 않는 비디오",
			videoID:       "non_existent_video_id",
			expectedError: "video not found",
			skipInTest:    true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.skipInTest {
				t.Skip("Skipping actual YouTube API test - requires real credentials")
			}

			adapter := NewYouTubeAdapter("test_client_id", "test_client_secret")

			result, err := adapter.GetVideo(context.Background(), tt.videoID)

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
			}
		})
	}
}

func TestYouTubeAdapter_FormatDuration(t *testing.T) {
	tests := []struct {
		name         string
		isoDuration  string
		expectedTime string
	}{
		{
			name:         "1분 30초",
			isoDuration:  "PT1M30S",
			expectedTime: "1:30",
		},
		{
			name:         "2시간 15분 30초",
			isoDuration:  "PT2H15M30S",
			expectedTime: "2:15:30",
		},
		{
			name:         "45초",
			isoDuration:  "PT45S",
			expectedTime: "0:45",
		},
		{
			name:         "1시간",
			isoDuration:  "PT1H",
			expectedTime: "1:00:00",
		},
		{
			name:         "빈 문자열",
			isoDuration:  "",
			expectedTime: "0:00",
		},
		{
			name:         "잘못된 형식",
			isoDuration:  "invalid",
			expectedTime: "0:00",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			adapter := NewYouTubeAdapter("test_client_id", "test_client_secret")

			result := adapter.formatDuration(tt.isoDuration)

			assert.Equal(t, tt.expectedTime, result)
		})
	}
}

func TestYouTubeAdapter_ChunkedUpload(t *testing.T) {
	tests := []struct {
		name       string
		fileSize   int64
		chunkSize  int64
		expectFunc func(t *testing.T, totalChunks int)
	}{
		{
			name:      "작은 파일 (1MB)",
			fileSize:  1048576, // 1MB
			chunkSize: 8388608, // 8MB chunk
			expectFunc: func(t *testing.T, totalChunks int) {
				assert.Equal(t, 1, totalChunks, "1MB 파일은 1개 청크여야 함")
			},
		},
		{
			name:      "중간 파일 (20MB)",
			fileSize:  20971520, // 20MB
			chunkSize: 8388608,  // 8MB chunk
			expectFunc: func(t *testing.T, totalChunks int) {
				assert.Equal(t, 3, totalChunks, "20MB 파일은 3개 청크여야 함")
			},
		},
		{
			name:      "큰 파일 (100MB)",
			fileSize:  104857600, // 100MB
			chunkSize: 8388608,   // 8MB chunk
			expectFunc: func(t *testing.T, totalChunks int) {
				assert.Equal(t, 13, totalChunks, "100MB 파일은 13개 청크여야 함")
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			adapter := NewYouTubeAdapter("test_client_id", "test_client_secret")

			totalChunks := adapter.calculateChunks(tt.fileSize, tt.chunkSize)

			tt.expectFunc(t, totalChunks)
		})
	}
}
