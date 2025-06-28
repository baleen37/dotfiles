# API Documentation

This document provides comprehensive API documentation for the ssulmeta-go YouTube Shorts generation system.

## Table of Contents

- [REST API](#rest-api)
  - [Channel Management](#channel-management)
  - [Health Check](#health-check)
- [CLI Interface](#cli-interface)
- [Domain Services](#domain-services)
- [Error Codes](#error-codes)

## REST API

Base URL: `http://localhost:8080`

### Authentication

Currently, the API does not require authentication for channel management endpoints. YouTube upload operations use OAuth2 authentication configured separately.

### Channel Management

Channels represent different content types (fairy_tale, horror, romance) with specific generation parameters.

#### Create Channel

Creates a new channel configuration.

**Endpoint:** `POST /channels`

**Request Body:**
```json
{
  "name": "fairy_tale",
  "description": "Children's fairy tale stories",
  "type": "fairy_tale",
  "active": true,
  "settings": {
    "story_length": 280,
    "voice_name": "ko-KR-Wavenet-A",
    "video_style": "dreamy"
  }
}
```

**Response:** `201 Created`
```json
{
  "id": "ch_1234567890",
  "name": "fairy_tale",
  "description": "Children's fairy tale stories",
  "type": "fairy_tale",
  "active": true,
  "settings": {
    "story_length": 280,
    "voice_name": "ko-KR-Wavenet-A",
    "video_style": "dreamy"
  },
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

#### List Channels

Retrieves all configured channels.

**Endpoint:** `GET /channels`

**Query Parameters:**
- `active` (optional): Filter by active status (true/false)
- `type` (optional): Filter by channel type

**Response:** `200 OK`
```json
{
  "channels": [
    {
      "id": "ch_1234567890",
      "name": "fairy_tale",
      "description": "Children's fairy tale stories",
      "type": "fairy_tale",
      "active": true,
      "created_at": "2024-01-15T10:30:00Z"
    },
    {
      "id": "ch_0987654321",
      "name": "horror",
      "description": "Scary horror stories",
      "type": "horror",
      "active": false,
      "created_at": "2024-01-14T09:00:00Z"
    }
  ],
  "total": 2
}
```

#### Get Channel

Retrieves details of a specific channel.

**Endpoint:** `GET /channels/{id}`

**Response:** `200 OK`
```json
{
  "id": "ch_1234567890",
  "name": "fairy_tale",
  "description": "Children's fairy tale stories",
  "type": "fairy_tale",
  "active": true,
  "settings": {
    "story_length": 280,
    "voice_name": "ko-KR-Wavenet-A",
    "video_style": "dreamy",
    "prompt_template": "Create a heartwarming fairy tale..."
  },
  "statistics": {
    "videos_generated": 42,
    "total_views": 125000,
    "last_generated": "2024-01-15T08:00:00Z"
  },
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

#### Update Channel Info

Updates basic channel information.

**Endpoint:** `PUT /channels/{id}`

**Request Body:**
```json
{
  "name": "fairy_tale_updated",
  "description": "Updated description"
}
```

**Response:** `200 OK`
```json
{
  "id": "ch_1234567890",
  "name": "fairy_tale_updated",
  "description": "Updated description",
  "updated_at": "2024-01-15T11:00:00Z"
}
```

#### Update Channel Settings

Updates channel-specific generation settings.

**Endpoint:** `PUT /channels/{id}/settings`

**Request Body:**
```json
{
  "story_length": 300,
  "voice_name": "ko-KR-Wavenet-B",
  "video_style": "magical",
  "tags": ["fairytale", "kids", "bedtime"]
}
```

**Response:** `200 OK`

#### Activate Channel

Activates a channel for content generation.

**Endpoint:** `POST /channels/{id}/activate`

**Response:** `200 OK`
```json
{
  "id": "ch_1234567890",
  "active": true,
  "activated_at": "2024-01-15T11:30:00Z"
}
```

#### Deactivate Channel

Deactivates a channel to pause content generation.

**Endpoint:** `POST /channels/{id}/deactivate`

**Response:** `200 OK`
```json
{
  "id": "ch_1234567890",
  "active": false,
  "deactivated_at": "2024-01-15T11:35:00Z"
}
```

#### Delete Channel

Permanently deletes a channel configuration.

**Endpoint:** `DELETE /channels/{id}`

**Response:** `204 No Content`

### Health Check

#### Get Health Status

Checks if the service is healthy and responsive.

**Endpoint:** `GET /health`

**Response:** `200 OK`
```json
{
  "status": "healthy",
  "service": "ssulmeta-go",
  "version": "0.1.0",
  "timestamp": "2024-01-15T10:00:00Z",
  "dependencies": {
    "redis": "connected",
    "postgresql": "connected",
    "openai": "available",
    "youtube": "authenticated"
  }
}
```

## CLI Interface

The CLI provides commands for managing the video generation pipeline.

### Basic Commands

```bash
# Show help
./youtube-shorts-generator --help

# Show version
./youtube-shorts-generator --version

# Set environment (overrides APP_ENV)
./youtube-shorts-generator --env=production
```

### Generate Command

Generates a complete YouTube Short for a channel.

```bash
# Generate video for a specific channel
./youtube-shorts-generator generate --channel fairy_tale

# Generate with custom prompt
./youtube-shorts-generator generate --channel horror --prompt "A scary story about an abandoned hospital"

# Generate without uploading
./youtube-shorts-generator generate --channel romance --no-upload

# Specify output directory
./youtube-shorts-generator generate --channel fairy_tale --output ./videos/
```

### Upload Command

Uploads an existing video to YouTube.

```bash
# Upload a video file
./youtube-shorts-generator upload --video ./videos/fairy_tale_001.mp4

# Upload with custom metadata
./youtube-shorts-generator upload \
  --video ./videos/story.mp4 \
  --title "Amazing Fairy Tale" \
  --description "A heartwarming story..." \
  --tags "fairytale,kids,bedtime"

# Upload to specific playlist
./youtube-shorts-generator upload \
  --video ./videos/story.mp4 \
  --playlist "PLxxxxxxxxxxxxx"
```

### Channel Commands

Manage channels from the command line.

```bash
# List all channels
./youtube-shorts-generator channels list

# Show channel details
./youtube-shorts-generator channels show fairy_tale

# Create new channel
./youtube-shorts-generator channels create \
  --name "mystery" \
  --type "mystery" \
  --description "Mystery and detective stories"

# Update channel
./youtube-shorts-generator channels update fairy_tale \
  --set "voice_name=ko-KR-Wavenet-C"

# Activate/deactivate channel
./youtube-shorts-generator channels activate fairy_tale
./youtube-shorts-generator channels deactivate horror
```

### Pipeline Commands

Test individual pipeline stages.

```bash
# Test story generation
./youtube-shorts-generator pipeline test-story --channel fairy_tale

# Test image generation
./youtube-shorts-generator pipeline test-image --story "Once upon a time..."

# Test TTS generation
./youtube-shorts-generator pipeline test-tts --text "안녕하세요"

# Test video composition
./youtube-shorts-generator pipeline test-video \
  --images ./temp/images/ \
  --audio ./temp/narration.mp3
```

## Domain Services

### Story Generation Service

Generates stories using OpenAI GPT models.

**Configuration:**
```yaml
api:
  openai:
    model: gpt-4
    temperature: 0.7
    max_tokens: 500
    system_prompt: "You are a creative storyteller..."
```

**Request Structure:**
```go
type GenerateRequest struct {
    ChannelType string
    Prompt      string  // Optional custom prompt
    Language    string  // Default: "ko"
}
```

**Response Structure:**
```go
type GenerateResponse struct {
    Story       string
    Title       string
    CharCount   int
    Scenes      []Scene
}
```

### Image Generation Service

Creates images for each story scene.

**Configuration:**
```yaml
api:
  image:
    provider: stable_diffusion
    width: 1080
    height: 1920
    steps: 50
    guidance_scale: 7.5
```

**Scene Structure:**
```go
type Scene struct {
    Number      int
    Text        string
    ImagePrompt string
    Duration    float64  // seconds
}
```

### TTS Service

Converts text to speech using Google Cloud TTS.

**Configuration:**
```yaml
api:
  tts:
    provider: google
    language_code: ko-KR
    speaking_rate: 1.0
    pitch: 0.0
    volume_gain: 0.0
```

**Voice Options:**
- `ko-KR-Wavenet-A`: Female voice (soft)
- `ko-KR-Wavenet-B`: Male voice (deep)
- `ko-KR-Wavenet-C`: Female voice (bright)
- `ko-KR-Wavenet-D`: Male voice (neutral)

### Video Composition Service

Combines images and audio into final video.

**Configuration:**
```yaml
video:
  fps: 30
  codec: h264
  preset: medium
  crf: 23
  audio_codec: aac
  audio_bitrate: 128k
```

**Effects Available:**
- Ken Burns (zoom/pan)
- Fade transitions
- Text overlays
- Background blur

### YouTube Upload Service

Handles video upload and metadata.

**OAuth2 Flow:**
1. Redirect to Google OAuth2
2. Receive authorization code
3. Exchange for access token
4. Store refresh token

**Upload Process:**
1. Validate video file
2. Generate optimized metadata
3. Create thumbnail
4. Upload video
5. Set video properties
6. Add to playlist

## Error Codes

### HTTP Status Codes

- `200 OK`: Success
- `201 Created`: Resource created
- `204 No Content`: Success with no response body
- `400 Bad Request`: Invalid request
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Access denied
- `404 Not Found`: Resource not found
- `409 Conflict`: Resource conflict
- `422 Unprocessable Entity`: Validation error
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error
- `503 Service Unavailable`: Service temporarily unavailable

### Application Error Codes

```json
{
  "error": {
    "code": "STORY_001",
    "message": "Story generation failed",
    "details": "OpenAI API returned an error"
  }
}
```

#### Story Domain Errors
- `STORY_001`: Story generation failed
- `STORY_002`: Story too short (< 270 chars)
- `STORY_003`: Story too long (> 300 chars)
- `STORY_004`: Invalid channel type

#### Channel Domain Errors
- `CHANNEL_001`: Channel not found
- `CHANNEL_002`: Channel already exists
- `CHANNEL_003`: Invalid channel configuration
- `CHANNEL_004`: Channel is inactive

#### Image Domain Errors
- `IMAGE_001`: Image generation failed
- `IMAGE_002`: Invalid image dimensions
- `IMAGE_003`: Scene splitting failed

#### TTS Domain Errors
- `TTS_001`: TTS generation failed
- `TTS_002`: Invalid voice selection
- `TTS_003`: Text too long for TTS

#### Video Domain Errors
- `VIDEO_001`: Video composition failed
- `VIDEO_002`: Invalid video format
- `VIDEO_003`: ffmpeg not available
- `VIDEO_004`: Insufficient disk space

#### YouTube Domain Errors
- `YOUTUBE_001`: Upload failed
- `YOUTUBE_002`: Authentication required
- `YOUTUBE_003`: Quota exceeded
- `YOUTUBE_004`: Invalid video metadata
- `YOUTUBE_005`: Token refresh failed

## Rate Limiting

API endpoints implement rate limiting to prevent abuse:

- Channel endpoints: 100 requests/minute
- Story generation: 10 requests/minute
- Image generation: 5 requests/minute
- YouTube upload: 50 uploads/day (YouTube quota)

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1705316400
```

## Webhooks

Configure webhooks to receive notifications:

```json
{
  "webhook_url": "https://your-server.com/webhook",
  "events": ["video.generated", "upload.completed", "upload.failed"],
  "secret": "your-webhook-secret"
}
```

### Event Types

- `video.generated`: Video creation completed
- `upload.completed`: YouTube upload successful
- `upload.failed`: YouTube upload failed
- `channel.activated`: Channel activated
- `channel.deactivated`: Channel deactivated

### Webhook Payload

```json
{
  "event": "upload.completed",
  "timestamp": "2024-01-15T10:00:00Z",
  "data": {
    "video_id": "abc123",
    "youtube_id": "dQw4w9WgXcQ",
    "channel": "fairy_tale",
    "title": "The Magic Forest",
    "duration": 58
  }
}
```

## Testing

### Using cURL

```bash
# Create channel
curl -X POST http://localhost:8080/channels \
  -H "Content-Type: application/json" \
  -d '{"name":"test","type":"fairy_tale","active":true}'

# Get channel
curl http://localhost:8080/channels/ch_1234567890

# Health check
curl http://localhost:8080/health
```

### Using HTTPie

```bash
# Create channel
http POST localhost:8080/channels \
  name=test type=fairy_tale active=true

# Update settings
http PUT localhost:8080/channels/ch_1234567890/settings \
  voice_name=ko-KR-Wavenet-B

# Activate channel
http POST localhost:8080/channels/ch_1234567890/activate
```

## SDK Examples

### Go Client

```go
import "github.com/your-org/ssulmeta-go-sdk"

client := ssulmeta.NewClient("http://localhost:8080")

// Create channel
channel, err := client.Channels.Create(&ssulmeta.ChannelRequest{
    Name:   "test",
    Type:   "fairy_tale",
    Active: true,
})

// Generate video
result, err := client.Pipeline.Generate(&ssulmeta.GenerateRequest{
    Channel: "fairy_tale",
    Upload:  true,
})
```

### Python Client

```python
from ssulmeta import Client

client = Client("http://localhost:8080")

# List channels
channels = client.channels.list(active=True)

# Generate video
result = client.pipeline.generate(
    channel="fairy_tale",
    upload=True
)
```

## Performance Tips

1. **Caching**: Channel configurations are cached in Redis for 5 minutes
2. **Batch Operations**: Use batch endpoints when processing multiple items
3. **Async Processing**: Video generation is asynchronous; poll for status
4. **CDN**: Serve generated videos through a CDN for better performance
5. **Connection Pooling**: Reuse HTTP connections for multiple requests

## Troubleshooting

### Common Issues

1. **"Channel not found"**: Ensure channel ID is correct and channel exists
2. **"Rate limit exceeded"**: Wait for rate limit reset or upgrade plan
3. **"Invalid API key"**: Check OpenAI/Google credentials in config
4. **"Upload failed"**: Verify YouTube OAuth2 token is valid
5. **"Generation timeout"**: Increase timeout values in configuration

### Debug Mode

Enable debug mode for detailed logging:

```bash
APP_LOG_LEVEL=debug ./youtube-shorts-generator
```

### Health Check Details

```bash
curl http://localhost:8080/health?detailed=true
```

Returns detailed status of all components and dependencies.