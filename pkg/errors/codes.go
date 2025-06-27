package errors

// Common error codes across the application
const (
	// Story domain error codes
	CodeStoryGenerationFailed = "STORY_GENERATION_FAILED"
	CodeStoryValidationFailed = "STORY_VALIDATION_FAILED"
	CodeStoryTooShort         = "STORY_TOO_SHORT"
	CodeStoryTooLong          = "STORY_TOO_LONG"
	CodeStoryEmpty            = "STORY_EMPTY"

	// Channel domain error codes
	CodeChannelNotFound         = "CHANNEL_NOT_FOUND"
	CodeChannelAlreadyExists    = "CHANNEL_ALREADY_EXISTS"
	CodeChannelValidationFailed = "CHANNEL_VALIDATION_FAILED"
	CodeChannelListFailed       = "CHANNEL_LIST_FAILED"

	// External service error codes
	CodeOpenAIAPIError      = "OPENAI_API_ERROR"
	CodeOpenAIRateLimited   = "OPENAI_RATE_LIMITED"
	CodeOpenAITimeout       = "OPENAI_TIMEOUT"
	CodeRedisConnectionFail = "REDIS_CONNECTION_FAILED"
	CodeRedisOperationFail  = "REDIS_OPERATION_FAILED"
	CodeExternalAPIError    = "EXTERNAL_API_ERROR"

	// YouTube API error codes
	CodeYouTubeAPIError      = "YOUTUBE_API_ERROR"
	CodeYouTubeUploadFailed  = "YOUTUBE_UPLOAD_FAILED"
	CodeYouTubeAuthFailed    = "YOUTUBE_AUTH_FAILED"
	CodeYouTubeQuotaExceeded = "YOUTUBE_QUOTA_EXCEEDED"

	// Video domain error codes
	CodeDependencyUnavailable  = "DEPENDENCY_UNAVAILABLE"
	CodeVideoCompositionFailed = "VIDEO_COMPOSITION_FAILED"
	CodeVideoValidationFailed  = "VIDEO_VALIDATION_FAILED"
	CodeFFmpegNotFound         = "FFMPEG_NOT_FOUND"
	CodeFFprobeNotFound        = "FFPROBE_NOT_FOUND"

	// Configuration error codes
	CodeConfigNotFound   = "CONFIG_NOT_FOUND"
	CodeConfigParseError = "CONFIG_PARSE_ERROR"
	CodeConfigInvalid    = "CONFIG_INVALID"

	// General error codes
	CodeInternalError    = "INTERNAL_ERROR"
	CodeValidationError  = "VALIDATION_ERROR"
	CodeInvalidInput     = "INVALID_INPUT"
	CodeUnauthorized     = "UNAUTHORIZED"
	CodeForbidden        = "FORBIDDEN"
	CodeResourceNotFound = "RESOURCE_NOT_FOUND"
	CodeResourceConflict = "RESOURCE_CONFLICT"
)
