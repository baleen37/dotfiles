# Sample Assets

This directory contains sample files for testing and development of the YouTube Shorts generation pipeline.

## Directory Structure

```
samples/
├── stories/          # Sample story texts
├── images/           # Sample generated images
├── audio/            # Sample TTS audio files
├── videos/           # Sample output videos
└── metadata/         # Sample metadata JSON files
```

## Sample Files

### Stories
- `fairy_tale_sample.txt` - Example fairy tale story (270-300 chars)
- `horror_sample.txt` - Example horror story
- `romance_sample.txt` - Example romance story

### Images
- `scene_*.jpg` - Sample scene images (1080x1920)
- Generated for testing image composition

### Audio
- `narration_*.mp3` - Sample TTS narration files
- Korean language samples with different voices

### Videos
- `output_sample.mp4` - Complete generated video sample
- Shows expected quality and format

### Metadata
- `youtube_metadata.json` - Sample YouTube upload metadata
- `channel_config.json` - Sample channel configuration

## Usage

These samples are used for:
1. Unit testing without external API calls
2. Integration testing of the pipeline
3. Performance benchmarking
4. Documentation examples

## Generating New Samples

```bash
# Generate sample story
./youtube-shorts-generator pipeline test-story --channel fairy_tale --output samples/stories/

# Generate sample images
./youtube-shorts-generator pipeline test-image --story "sample story text" --output samples/images/

# Generate sample audio
./youtube-shorts-generator pipeline test-tts --text "샘플 텍스트" --output samples/audio/
```

## Mock Testing

When `APP_ENV=test` or `api.use_mock=true`, the system uses these samples instead of calling external APIs:
- Mock story generator returns predefined stories
- Mock image generator copies sample images
- Mock TTS returns sample audio files
- Mock YouTube uploader simulates upload without actual API calls

## Notes

- All samples are excluded from version control (see .gitignore)
- Samples are automatically generated during test runs
- Do not include actual API responses or user data
- Keep file sizes reasonable for quick testing