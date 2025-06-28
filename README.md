# ssulmeta-go

An automated YouTube Shorts generation system that creates storytelling-based videos with AI-generated content, narration, and automatic upload capabilities.

## Overview

This project automatically generates YouTube Shorts by:
1. Creating stories using OpenAI GPT
2. Generating scene images with AI
3. Converting text to speech for narration
4. Composing videos with transitions and effects
5. Uploading to YouTube with optimized metadata

Built with Go 1.24+ following Hexagonal Architecture principles for clean separation of business logic and external integrations.

## Features

- **AI Story Generation**: Creates channel-specific stories (fairy tales, horror, romance) using OpenAI
- **Scene Splitting**: Intelligently divides stories into visual scenes
- **Image Generation**: Creates vertical format (1080x1920) images for each scene
- **Text-to-Speech**: Generates Korean narration using Google Cloud TTS
- **Video Composition**: Combines images with Ken Burns effects using ffmpeg
- **YouTube Integration**: OAuth2-based automatic upload with SEO-optimized metadata
- **Channel Management**: Redis-cached channel configurations and templates
- **Production Ready**: Comprehensive testing, CI/CD pipeline, and monitoring

## Quick Start

### Prerequisites

- Go 1.24+
- Docker & Docker Compose
- ffmpeg (for video processing)
- Redis (for caching)
- PostgreSQL (for data persistence)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/ssulmeta-go.git
cd ssulmeta-go

# Install dependencies and development tools
make setup-dev

# Start infrastructure services
docker-compose up -d

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your API keys and configuration
```

### Configuration

Create configuration files for your environment:

```bash
# Copy the example configuration
cp configs/local.yaml configs/local.yaml

# Required API Keys (add to .env or config files):
# - OPENAI_API_KEY: For story generation
# - GOOGLE_APPLICATION_CREDENTIALS: For TTS
# - YouTube OAuth2 credentials in configs/oauth.yaml
```

### Running the Application

```bash
# Run in development mode
make dev

# Or run specific components:
go run ./cmd/cli          # CLI interface
go run ./cmd/api          # REST API server
go run ./cmd/pipeline-test # Test the full pipeline
```

## Architecture

This project follows Hexagonal Architecture (Ports and Adapters) with feature-based organization:

```
internal/
├── story/       # Story generation domain
├── channel/     # Channel management
├── image/       # Image generation
├── tts/         # Text-to-speech
├── video/       # Video composition
└── youtube/     # YouTube upload
    ├── core/    # Business logic
    ├── ports/   # Interfaces
    └── adapters/ # External integrations
```

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed architecture documentation.

## API Documentation

### REST API Endpoints

Start the API server:
```bash
go run ./cmd/api  # Runs on :8080
```

#### Channel Management
- `POST /channels` - Create a new channel
- `GET /channels` - List all channels
- `GET /channels/{id}` - Get channel details
- `PUT /channels/{id}` - Update channel info
- `DELETE /channels/{id}` - Delete channel
- `PUT /channels/{id}/settings` - Update channel settings
- `POST /channels/{id}/activate` - Activate channel
- `POST /channels/{id}/deactivate` - Deactivate channel

#### Health Check
- `GET /health` - Service health status

### CLI Commands

```bash
# Generate a video for a specific channel
./youtube-shorts-generator generate --channel fairy_tale

# Upload existing video
./youtube-shorts-generator upload --video path/to/video.mp4

# List available channels
./youtube-shorts-generator channels list

# Show version
./youtube-shorts-generator --version
```

## Development

### Testing

```bash
# Run all tests with coverage
make test

# Run architecture tests
make arch-test

# Generate coverage report
make coverage-html

# Run specific domain tests
go test -v ./internal/story/...
```

### Code Quality

```bash
# Format code
make fmt

# Run linter
make lint

# Run all CI checks locally
make ci-check
```

### Adding New Features

1. Create domain structure:
   ```bash
   mkdir -p internal/newfeature/{core,ports,adapters}
   ```

2. Define interfaces in `ports/`
3. Implement business logic in `core/`
4. Add external integrations in `adapters/`
5. Write comprehensive tests
6. Update configuration if needed

## Configuration

### Environment Variables

See `.env.example` for all available options. Key variables:

- `APP_ENV`: Environment (test/local/dev/prod)
- `OPENAI_API_KEY`: OpenAI API key for story generation
- `GOOGLE_APPLICATION_CREDENTIALS`: Path to Google Cloud credentials
- `REDIS_URL`: Redis connection URL
- `DATABASE_URL`: PostgreSQL connection string

### Channel Configuration

Channel-specific prompts and settings in `configs/channels/`:
- `fairy_tale.yaml` - Children's fairy tale generation
- `horror.yaml` - Horror story generation
- `romance.yaml` - Romance story generation

## Deployment

### Docker

```bash
# Build Docker image
docker build -t ssulmeta-go .

# Run with Docker Compose
docker-compose up
```

### Environment-Specific Configs

- `configs/test.yaml` - Test environment (uses mocks)
- `configs/local.yaml` - Local development
- `configs/dev.yaml` - Development server
- `configs/prod.yaml` - Production

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines.

### Branch Naming
- Format: `{type}/{username}/{scope}-{description}`
- Example: `feat/jito/youtube-metadata-generation`

### Pre-commit Hooks
Automatically installed with `make setup-dev`. Ensures code quality before commits.

## Development Status

### Current Phase: 6.4 - Metadata Generator Implementation

See [progress.md](./progress.md) for detailed development status.

**Completed**:
- ✅ Core architecture and configuration
- ✅ Story generation with OpenAI
- ✅ Channel management with Redis
- ✅ Video composition with ffmpeg
- ✅ YouTube API integration

**In Progress**:
- 🔄 Metadata generation for SEO
- 🔄 CLI improvements

**Planned**:
- ⏳ Scheduler implementation
- ⏳ Job queue system
- ⏳ Analytics dashboard

## Troubleshooting

### Common Issues

1. **"Redis connection failed"**
   ```bash
   docker-compose up -d redis
   ```

2. **"Missing API key"**
   - Check `.env` file has all required keys
   - Ensure `APP_ENV` matches your config file

3. **"ffmpeg not found"**
   ```bash
   # macOS
   brew install ffmpeg
   
   # Ubuntu/Debian
   sudo apt-get install ffmpeg
   ```

4. **Test failures**
   - Run with test environment: `APP_ENV=test go test ./...`
   - Check if mocks are properly configured

## License

MIT License - see LICENSE file for details.

## Support

- Issues: [GitHub Issues](https://github.com/your-org/ssulmeta-go/issues)
- Documentation: See `/docs` folder
- Slack: #ssulmeta-dev channel