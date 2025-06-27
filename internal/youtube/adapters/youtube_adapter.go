package adapters

import (
	"context"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	"golang.org/x/oauth2"
	"google.golang.org/api/googleapi"
	"google.golang.org/api/option"
	"google.golang.org/api/youtube/v3"

	"ssulmeta-go/internal/youtube/ports"
	"ssulmeta-go/pkg/errors"
)

// YouTubeAdapter implements YouTube API operations
type YouTubeAdapter struct {
	clientID     string
	clientSecret string
	chunkSize    int64 // Upload chunk size in bytes
}

// NewYouTubeAdapter creates a new YouTube API adapter instance
func NewYouTubeAdapter(clientID, clientSecret string) *YouTubeAdapter {
	return &YouTubeAdapter{
		clientID:     clientID,
		clientSecret: clientSecret,
		chunkSize:    8388608, // 8MB default chunk size
	}
}

// UploadVideo uploads a video to YouTube
func (a *YouTubeAdapter) UploadVideo(ctx context.Context, video *ports.Video, progressCallback func(*ports.UploadProgress)) (*ports.UploadResult, error) {
	// Validate video
	if err := a.validateVideo(video); err != nil {
		return nil, err
	}

	// Check if we're in test environment
	if os.Getenv("SKIP_YOUTUBE_API") == "true" {
		return a.createMockUploadResult(video), nil
	}

	// Validate video file exists
	fileInfo, err := os.Stat(video.VideoPath)
	if err != nil {
		return nil, errors.NewValidationError(
			errors.CodeValidationError,
			"video file not found",
			map[string]interface{}{
				"video_path": video.VideoPath,
				"error":      err.Error(),
			},
		)
	}

	// Get OAuth2 token from context (should be set by calling service)
	token, ok := ctx.Value("oauth_token").(*oauth2.Token)
	if !ok {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeAuthFailed,
			"OAuth2 token not found in context",
			nil,
		)
	}

	// Create YouTube service
	service, err := a.createYouTubeService(ctx, token)
	if err != nil {
		return nil, err
	}

	// Open video file
	file, err := os.Open(video.VideoPath)
	if err != nil {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to open video file",
			map[string]interface{}{
				"video_path": video.VideoPath,
				"error":      err.Error(),
			},
		)
	}
	defer file.Close()

	// Create video upload object
	uploadVideo := &youtube.Video{
		Snippet: &youtube.VideoSnippet{
			Title:       video.Title,
			Description: video.Description,
			Tags:        video.Tags,
			CategoryId:  video.CategoryID,
		},
		Status: &youtube.VideoStatus{
			PrivacyStatus: video.Privacy,
		},
	}

	// Create upload call
	call := service.Videos.Insert([]string{"snippet", "status"}, uploadVideo)

	// Set up media upload
	call = call.Media(file, googleapi.ChunkSize(int(a.chunkSize)))

	// Execute upload with progress tracking
	if progressCallback != nil {
		call = call.ProgressUpdater(func(current, total int64) {
			progress := &ports.UploadProgress{
				BytesUploaded: current,
				TotalBytes:    total,
				Percentage:    float64(current) / float64(total) * 100,
				Speed:         a.calculateUploadSpeed(current, time.Now()),
				ETA:           a.calculateETA(current, total, time.Now()),
			}
			progressCallback(progress)
		})
	}

	// Execute the upload
	uploadedVideo, err := call.Do()
	if err != nil {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeUploadFailed,
			"failed to upload video to YouTube",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}

	// Handle thumbnail upload if provided
	if video.Thumbnail != "" {
		if err := a.uploadThumbnail(service, uploadedVideo.Id, video.Thumbnail); err != nil {
			// Log warning but don't fail the upload - thumbnail upload is optional
			// We continue with the video upload even if thumbnail fails
			_ = err // Explicitly ignore error
		}
	}

	// Convert to result format
	result := &ports.UploadResult{
		VideoID:      uploadedVideo.Id,
		URL:          fmt.Sprintf("https://www.youtube.com/watch?v=%s", uploadedVideo.Id),
		Title:        uploadedVideo.Snippet.Title,
		UploadedAt:   time.Now(),
		Status:       uploadedVideo.Status.UploadStatus,
		Duration:     a.formatDuration(uploadedVideo.ContentDetails.Duration),
		FileSize:     fileInfo.Size(),
		ThumbnailURL: a.getThumbnailURL(uploadedVideo),
	}

	return result, nil
}

// UpdateVideo updates an existing video's metadata
func (a *YouTubeAdapter) UpdateVideo(ctx context.Context, videoID string, metadata *ports.Metadata) error {
	// Validate input
	if strings.TrimSpace(videoID) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"video ID is required",
			map[string]interface{}{
				"video_id": videoID,
			},
		)
	}

	if metadata == nil {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"metadata is required",
			nil,
		)
	}

	// Check if we're in test environment
	if os.Getenv("SKIP_YOUTUBE_API") == "true" {
		return nil // Success in test mode
	}

	// Get OAuth2 token from context
	token, ok := ctx.Value("oauth_token").(*oauth2.Token)
	if !ok {
		return errors.NewExternalError(
			errors.CodeYouTubeAuthFailed,
			"OAuth2 token not found in context",
			nil,
		)
	}

	// Create YouTube service
	service, err := a.createYouTubeService(ctx, token)
	if err != nil {
		return err
	}

	// Create update video object
	updateVideo := &youtube.Video{
		Id: videoID,
		Snippet: &youtube.VideoSnippet{
			Title:       metadata.Title,
			Description: metadata.Description,
			Tags:        metadata.Tags,
			CategoryId:  metadata.CategoryID,
		},
	}

	// Add status if privacy is specified
	if metadata.Privacy != "" {
		updateVideo.Status = &youtube.VideoStatus{
			PrivacyStatus: metadata.Privacy,
		}
	}

	// Execute update
	_, err = service.Videos.Update([]string{"snippet", "status"}, updateVideo).Do()
	if err != nil {
		return errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to update video metadata",
			map[string]interface{}{
				"video_id": videoID,
				"error":    err.Error(),
			},
		)
	}

	return nil
}

// DeleteVideo deletes a video from YouTube
func (a *YouTubeAdapter) DeleteVideo(ctx context.Context, videoID string) error {
	// Validate input
	if strings.TrimSpace(videoID) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"video ID is required",
			map[string]interface{}{
				"video_id": videoID,
			},
		)
	}

	// Check if we're in test environment
	if os.Getenv("SKIP_YOUTUBE_API") == "true" {
		return nil // Success in test mode
	}

	// Get OAuth2 token from context
	token, ok := ctx.Value("oauth_token").(*oauth2.Token)
	if !ok {
		return errors.NewExternalError(
			errors.CodeYouTubeAuthFailed,
			"OAuth2 token not found in context",
			nil,
		)
	}

	// Create YouTube service
	service, err := a.createYouTubeService(ctx, token)
	if err != nil {
		return err
	}

	// Execute delete
	err = service.Videos.Delete(videoID).Do()
	if err != nil {
		if strings.Contains(err.Error(), "not found") {
			return errors.NewExternalError(
				errors.CodeResourceNotFound,
				"video not found",
				map[string]interface{}{
					"video_id": videoID,
				},
			)
		}
		return errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to delete video",
			map[string]interface{}{
				"video_id": videoID,
				"error":    err.Error(),
			},
		)
	}

	return nil
}

// GetVideo retrieves video information
func (a *YouTubeAdapter) GetVideo(ctx context.Context, videoID string) (*ports.UploadResult, error) {
	// Validate input
	if strings.TrimSpace(videoID) == "" {
		return nil, errors.NewValidationError(
			errors.CodeValidationError,
			"video ID is required",
			map[string]interface{}{
				"video_id": videoID,
			},
		)
	}

	// Check if we're in test environment
	if os.Getenv("SKIP_YOUTUBE_API") == "true" {
		return a.createMockVideoResult(videoID), nil
	}

	// Get OAuth2 token from context
	token, ok := ctx.Value("oauth_token").(*oauth2.Token)
	if !ok {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeAuthFailed,
			"OAuth2 token not found in context",
			nil,
		)
	}

	// Create YouTube service
	service, err := a.createYouTubeService(ctx, token)
	if err != nil {
		return nil, err
	}

	// Execute get video call
	response, err := service.Videos.List([]string{"snippet", "status", "contentDetails", "statistics"}).Id(videoID).Do()
	if err != nil {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to retrieve video information",
			map[string]interface{}{
				"video_id": videoID,
				"error":    err.Error(),
			},
		)
	}

	if len(response.Items) == 0 {
		return nil, errors.NewExternalError(
			errors.CodeResourceNotFound,
			"video not found",
			map[string]interface{}{
				"video_id": videoID,
			},
		)
	}

	video := response.Items[0]

	// Parse published date
	publishedAt, _ := time.Parse(time.RFC3339, video.Snippet.PublishedAt)

	// Convert to result format
	result := &ports.UploadResult{
		VideoID:      video.Id,
		URL:          fmt.Sprintf("https://www.youtube.com/watch?v=%s", video.Id),
		Title:        video.Snippet.Title,
		UploadedAt:   publishedAt,
		Status:       video.Status.UploadStatus,
		Duration:     a.formatDuration(video.ContentDetails.Duration),
		FileSize:     0, // Not available from API
		ThumbnailURL: a.getThumbnailURL(video),
	}

	return result, nil
}

// validateVideo validates video data before upload
func (a *YouTubeAdapter) validateVideo(video *ports.Video) error {
	if video == nil {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"video is required",
			nil,
		)
	}

	// Validate title
	if strings.TrimSpace(video.Title) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"title is required",
			map[string]interface{}{
				"title": video.Title,
			},
		)
	}

	if len(video.Title) > 100 {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"title exceeds maximum length of 100 characters",
			map[string]interface{}{
				"title":        video.Title,
				"title_length": len(video.Title),
			},
		)
	}

	// Validate video path
	if strings.TrimSpace(video.VideoPath) == "" {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"video path is required",
			map[string]interface{}{
				"video_path": video.VideoPath,
			},
		)
	}

	// Validate privacy setting
	validPrivacySettings := map[string]bool{
		"public":   true,
		"private":  true,
		"unlisted": true,
	}

	if video.Privacy != "" && !validPrivacySettings[video.Privacy] {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"invalid privacy setting",
			map[string]interface{}{
				"privacy":        video.Privacy,
				"valid_settings": []string{"public", "private", "unlisted"},
			},
		)
	}

	// Validate tags
	if len(video.Tags) > 500 {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"too many tags (maximum 500)",
			map[string]interface{}{
				"tag_count": len(video.Tags),
			},
		)
	}

	// Calculate total tag length
	totalTagLength := 0
	for _, tag := range video.Tags {
		totalTagLength += len(tag)
	}

	if totalTagLength > 500 {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"total tag length exceeds 500 characters",
			map[string]interface{}{
				"total_tag_length": totalTagLength,
			},
		)
	}

	return nil
}

// createYouTubeService creates a YouTube service instance with OAuth2 token
func (a *YouTubeAdapter) createYouTubeService(ctx context.Context, token *oauth2.Token) (*youtube.Service, error) {
	config := &oauth2.Config{
		ClientID:     a.clientID,
		ClientSecret: a.clientSecret,
		Endpoint: oauth2.Endpoint{
			AuthURL:  "https://accounts.google.com/o/oauth2/auth",
			TokenURL: "https://oauth2.googleapis.com/token",
		},
		Scopes: []string{
			"https://www.googleapis.com/auth/youtube.upload",
			"https://www.googleapis.com/auth/youtube",
		},
	}

	client := config.Client(ctx, token)

	service, err := youtube.NewService(ctx, option.WithHTTPClient(client))
	if err != nil {
		return nil, errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to create YouTube service",
			map[string]interface{}{
				"error": err.Error(),
			},
		)
	}

	return service, nil
}

// formatDuration converts ISO 8601 duration to human-readable format
func (a *YouTubeAdapter) formatDuration(isoDuration string) string {
	if isoDuration == "" {
		return "0:00"
	}

	// Parse ISO 8601 duration (e.g., "PT1M30S" -> "1:30")
	re := regexp.MustCompile(`PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?`)
	matches := re.FindStringSubmatch(isoDuration)

	if len(matches) != 4 {
		return "0:00"
	}

	hours, _ := strconv.Atoi(matches[1])
	minutes, _ := strconv.Atoi(matches[2])
	seconds, _ := strconv.Atoi(matches[3])

	if hours > 0 {
		return fmt.Sprintf("%d:%02d:%02d", hours, minutes, seconds)
	}
	return fmt.Sprintf("%d:%02d", minutes, seconds)
}

// uploadThumbnail uploads a custom thumbnail for the video
func (a *YouTubeAdapter) uploadThumbnail(service *youtube.Service, videoID, thumbnailPath string) error {
	// Check if thumbnail file exists
	if _, err := os.Stat(thumbnailPath); err != nil {
		return errors.NewValidationError(
			errors.CodeValidationError,
			"thumbnail file not found",
			map[string]interface{}{
				"thumbnail_path": thumbnailPath,
				"error":          err.Error(),
			},
		)
	}

	// Open thumbnail file
	file, err := os.Open(thumbnailPath)
	if err != nil {
		return errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to open thumbnail file",
			map[string]interface{}{
				"thumbnail_path": thumbnailPath,
				"error":          err.Error(),
			},
		)
	}
	defer file.Close()

	// Upload thumbnail
	_, err = service.Thumbnails.Set(videoID).Media(file).Do()
	if err != nil {
		return errors.NewExternalError(
			errors.CodeYouTubeAPIError,
			"failed to upload thumbnail",
			map[string]interface{}{
				"video_id": videoID,
				"error":    err.Error(),
			},
		)
	}

	return nil
}

// getThumbnailURL extracts the best available thumbnail URL
func (a *YouTubeAdapter) getThumbnailURL(video *youtube.Video) string {
	if video.Snippet.Thumbnails == nil {
		return ""
	}

	// Prefer high quality thumbnails
	if video.Snippet.Thumbnails.Maxres != nil {
		return video.Snippet.Thumbnails.Maxres.Url
	}
	if video.Snippet.Thumbnails.Standard != nil {
		return video.Snippet.Thumbnails.Standard.Url
	}
	if video.Snippet.Thumbnails.High != nil {
		return video.Snippet.Thumbnails.High.Url
	}
	if video.Snippet.Thumbnails.Medium != nil {
		return video.Snippet.Thumbnails.Medium.Url
	}
	if video.Snippet.Thumbnails.Default != nil {
		return video.Snippet.Thumbnails.Default.Url
	}

	return ""
}

// calculateChunks calculates the number of chunks needed for upload
func (a *YouTubeAdapter) calculateChunks(fileSize, chunkSize int64) int {
	return int((fileSize + chunkSize - 1) / chunkSize)
}

// calculateUploadSpeed calculates current upload speed
func (a *YouTubeAdapter) calculateUploadSpeed(bytesUploaded int64, startTime time.Time) string {
	elapsed := time.Since(startTime).Seconds()
	if elapsed == 0 {
		return "0 B/s"
	}

	bytesPerSecond := float64(bytesUploaded) / elapsed

	if bytesPerSecond >= 1048576 { // MB/s
		return fmt.Sprintf("%.1f MB/s", bytesPerSecond/1048576)
	} else if bytesPerSecond >= 1024 { // KB/s
		return fmt.Sprintf("%.1f KB/s", bytesPerSecond/1024)
	}
	return fmt.Sprintf("%.0f B/s", bytesPerSecond)
}

// calculateETA calculates estimated time to completion
func (a *YouTubeAdapter) calculateETA(current, total int64, startTime time.Time) string {
	if current == 0 {
		return "calculating..."
	}

	elapsed := time.Since(startTime)
	remaining := total - current

	if remaining <= 0 {
		return "0s"
	}

	estimatedTotal := time.Duration(float64(elapsed) * float64(total) / float64(current))
	eta := estimatedTotal - elapsed

	if eta < time.Minute {
		return fmt.Sprintf("%ds", int(eta.Seconds()))
	} else if eta < time.Hour {
		return fmt.Sprintf("%dm %ds", int(eta.Minutes()), int(eta.Seconds())%60)
	}
	return fmt.Sprintf("%dh %dm", int(eta.Hours()), int(eta.Minutes())%60)
}

// createMockUploadResult creates a mock upload result for testing
func (a *YouTubeAdapter) createMockUploadResult(video *ports.Video) *ports.UploadResult {
	return &ports.UploadResult{
		VideoID:      "mock_video_id_" + strconv.FormatInt(time.Now().Unix(), 10),
		URL:          "https://www.youtube.com/watch?v=mock_video_id",
		Title:        video.Title,
		UploadedAt:   time.Now(),
		Status:       "processed",
		Duration:     "1:30",
		FileSize:     1048576, // 1MB mock size
		ThumbnailURL: "https://i.ytimg.com/vi/mock_video_id/maxresdefault.jpg",
	}
}

// createMockVideoResult creates a mock video result for testing
func (a *YouTubeAdapter) createMockVideoResult(videoID string) *ports.UploadResult {
	return &ports.UploadResult{
		VideoID:      videoID,
		URL:          fmt.Sprintf("https://www.youtube.com/watch?v=%s", videoID),
		Title:        "Mock Video Title",
		UploadedAt:   time.Now().Add(-24 * time.Hour), // 1 day ago
		Status:       "processed",
		Duration:     "2:15",
		FileSize:     0,
		ThumbnailURL: fmt.Sprintf("https://i.ytimg.com/vi/%s/maxresdefault.jpg", videoID),
	}
}
