package core

import (
	"context"
	"strings"

	"ssulmeta-go/internal/youtube/ports"
	"ssulmeta-go/pkg/errors"
)

// Service implements YouTube business logic
type Service struct {
	uploader          ports.Uploader
	metadataGenerator ports.MetadataGenerator
	authService       ports.AuthService
	channelService    ports.ChannelService
}

// NewService creates a new YouTube service instance
func NewService(
	uploader ports.Uploader,
	metadataGenerator ports.MetadataGenerator,
	authService ports.AuthService,
	channelService ports.ChannelService,
) *Service {
	return &Service{
		uploader:          uploader,
		metadataGenerator: metadataGenerator,
		authService:       authService,
		channelService:    channelService,
	}
}

// UploadStory uploads a story video to YouTube with generated metadata
func (s *Service) UploadStory(ctx context.Context, request *ports.UploadStoryRequest) (*ports.UploadStoryResult, error) {
	// Validate request
	if err := s.validateUploadRequest(request); err != nil {
		return nil, err
	}

	// Validate access token
	if err := s.authService.ValidateToken(ctx, request.AccessToken); err != nil {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeAuthFailed,
			"failed to validate access token",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}

	// Generate metadata from story content
	metadata, err := s.metadataGenerator.GenerateMetadata(ctx, request.StoryContent, request.ChannelType)
	if err != nil {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to generate video metadata",
			map[string]interface{}{
				"error":        err.Error(),
				"channel_type": request.ChannelType,
			},
		)
	}

	// Set scheduled time if provided
	if request.ScheduledTime != nil {
		metadata.PublishAt = request.ScheduledTime
	}

	// Create video object for upload
	video := &ports.Video{
		Title:       metadata.Title,
		Description: metadata.Description,
		Tags:        metadata.Tags,
		CategoryID:  metadata.CategoryID,
		Privacy:     metadata.Privacy,
		Thumbnail:   request.ThumbnailPath,
		VideoPath:   request.VideoPath,
	}

	// Upload video with progress tracking
	uploadResult, err := s.uploader.UploadVideo(ctx, video, func(progress *ports.UploadProgress) {
		// Progress callback - could be extended to notify external systems
		// For now, we'll just let the uploader handle progress internally
	})
	if err != nil {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeUploadFailed,
			"failed to upload video to YouTube",
			map[string]interface{}{
				"error":      err.Error(),
				"video_path": request.VideoPath,
			},
		)
	}

	// Convert upload result to story result
	result := &ports.UploadStoryResult{
		VideoID:      uploadResult.VideoID,
		URL:          uploadResult.URL,
		Title:        uploadResult.Title,
		UploadedAt:   uploadResult.UploadedAt,
		Status:       uploadResult.Status,
		Duration:     uploadResult.Duration,
		FileSize:     uploadResult.FileSize,
		ThumbnailURL: uploadResult.ThumbnailURL,
	}

	return result, nil
}

// GetChannelInfo retrieves channel information
func (s *Service) GetChannelInfo(ctx context.Context, accessToken string) (*ports.ChannelInfo, error) {
	// Validate access token
	if err := s.authService.ValidateToken(ctx, accessToken); err != nil {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeAuthFailed,
			"failed to validate access token",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}

	// Get channel information
	channelInfo, err := s.channelService.GetChannelInfo(ctx, accessToken)
	if err != nil {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to retrieve channel information",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}

	return channelInfo, nil
}

// UpdateVideoMetadata updates an existing video's metadata
func (s *Service) UpdateVideoMetadata(ctx context.Context, videoID string, metadata *ports.Metadata, accessToken string) error {
	// Validate access token
	if err := s.authService.ValidateToken(ctx, accessToken); err != nil {
		return errors.NewExternalError(
			errors.CodeYouTubeAuthFailed,
			"failed to validate access token",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}

	// Validate video ID
	if strings.TrimSpace(videoID) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"video ID is required",
			map[string]interface{}{
				"video_id": videoID,
			},
		)
	}

	// Validate metadata
	if metadata == nil {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"metadata is required",
			nil,
		)
	}

	// Update video metadata
	if err := s.uploader.UpdateVideo(ctx, videoID, metadata); err != nil {
		return errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to update video metadata",
			map[string]interface{}{
				"error":    err.Error(),
				"video_id": videoID,
			},
		)
	}

	return nil
}

// DeleteVideo deletes a video from YouTube
func (s *Service) DeleteVideo(ctx context.Context, videoID string, accessToken string) error {
	// Validate access token
	if err := s.authService.ValidateToken(ctx, accessToken); err != nil {
		return errors.NewExternalError(
			errors.CodeYouTubeAuthFailed,
			"failed to validate access token",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}

	// Validate video ID
	if strings.TrimSpace(videoID) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"video ID is required",
			map[string]interface{}{
				"video_id": videoID,
			},
		)
	}

	// Delete video
	if err := s.uploader.DeleteVideo(ctx, videoID); err != nil {
		return errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to delete video",
			map[string]interface{}{
				"error":    err.Error(),
				"video_id": videoID,
			},
		)
	}

	return nil
}

// GetVideoAnalytics retrieves video analytics (simplified implementation)
func (s *Service) GetVideoAnalytics(ctx context.Context, videoID string, accessToken string) (map[string]interface{}, error) {
	// Validate access token
	if err := s.authService.ValidateToken(ctx, accessToken); err != nil {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeAuthFailed,
			"failed to validate access token",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}

	// Validate video ID
	if strings.TrimSpace(videoID) == "" {
		return nil, errors.NewValidationError(
			errors.CodeValidationError,
			"video ID is required",
			map[string]interface{}{
				"video_id": videoID,
			},
		)
	}

	// Get video information (as a basic form of analytics)
	videoInfo, err := s.uploader.GetVideo(ctx, videoID)
	if err != nil {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to retrieve video information",
			map[string]interface{}{
				"error":    err.Error(),
				"video_id": videoID,
			},
		)
	}

	// Convert to analytics format
	analytics := map[string]interface{}{
		"video_id":      videoInfo.VideoID,
		"title":         videoInfo.Title,
		"status":        videoInfo.Status,
		"duration":      videoInfo.Duration,
		"file_size":     videoInfo.FileSize,
		"uploaded_at":   videoInfo.UploadedAt,
		"thumbnail_url": videoInfo.ThumbnailURL,
	}

	return analytics, nil
}

// validateUploadRequest validates the upload story request
func (s *Service) validateUploadRequest(request *ports.UploadStoryRequest) error {
	if request == nil {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"request is required",
			nil,
		)
	}

	if strings.TrimSpace(request.StoryContent) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"story content is required",
			map[string]interface{}{
				"story_content": request.StoryContent,
			},
		)
	}

	if strings.TrimSpace(request.ChannelType) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"channel type is required",
			map[string]interface{}{
				"channel_type": request.ChannelType,
			},
		)
	}

	if strings.TrimSpace(request.VideoPath) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"video path is required",
			map[string]interface{}{
				"video_path": request.VideoPath,
			},
		)
	}

	if strings.TrimSpace(request.AccessToken) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"access token is required",
			map[string]interface{}{
				"access_token_length": len(request.AccessToken),
			},
		)
	}

	// Validate channel type
	validChannelTypes := map[string]bool{
		"fairy_tale": true,
		"horror":     true,
		"romance":    true,
	}

	if !validChannelTypes[request.ChannelType] {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"invalid channel type",
			map[string]interface{}{
				"channel_type":        request.ChannelType,
				"valid_channel_types": []string{"fairy_tale", "horror", "romance"},
			},
		)
	}

	return nil
}
