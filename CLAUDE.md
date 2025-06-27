# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a YouTube Shorts automatic generation system that creates storytelling-based videos and uploads them automatically. The project follows Hexagonal Architecture (Ports and Adapters Pattern) and is currently in active development (Phase 2 completed).

## Development Commands

### Build and Run

```bash
# Build the CLI application
make build

# Run in development mode
make dev

# Run with specific environment
APP_ENV=test go run ./cmd/cli

# Build and run API server
go run ./cmd/api

# Run pipeline test
go run ./cmd/pipeline-test
```

### Testing

```bash
# Run all tests
make test

# Run tests with coverage
make coverage

# Run specific package tests
go test -v ./internal/story/...
go test -v ./internal/channel/...

# Run integration tests with Docker
docker-compose -f docker-compose.test.yml up --abort-on-error
```

### Code Quality

```bash
# Format code (gofmt + goimports)
make fmt

# Run linter
make lint

# Run all CI checks locally
make fmt && make lint && make test
```

### Database Operations

```bash
# Run PostgreSQL and Redis locally
docker-compose up -d

# Connect to database
psql "host=localhost port=5432 user=ssulmeta password=ssulmeta123! dbname=ssulmeta sslmode=disable"
```

## Architecture

This project follows **Hexagonal Architecture** with clear separation of concerns:

```
internal/{feature}/
├── core/       # Business logic (no external dependencies)
├── ports/      # Interface definitions
└── adapters/   # External system implementations (HTTP, Redis, APIs)
```

### Key Domains

1. **Story**: Story generation using OpenAI API
   - Prompt templates per channel (configs/channels/*.yaml)
   - 270-300 character validation
   - Mock mode available for testing

2. **Channel**: Channel management with Redis caching
   - HTTP API endpoints
   - Redis-based caching for performance
   - Channel configurations in YAML

3. **Image**: Scene splitting and image generation (TODO)
   - Stable Diffusion API integration planned
   - 1080x1920 vertical format

4. **TTS**: Text-to-speech generation (TODO)
   - Google Cloud TTS integration planned
   - Korean voice support

5. **Video**: Video composition with ffmpeg (TODO)
   - Ken Burns effects
   - Scene transitions

6. **YouTube**: Upload automation (TODO)
   - OAuth2 authentication
   - Metadata generation

## Configuration

### Environment-based Config Files

```yaml
# configs/test.yaml    - Test environment (uses mocks)
# configs/local.yaml   - Local development
# configs/dev.yaml     - Development server
# configs/prod.yaml    - Production
```

Set environment with `APP_ENV` variable (defaults to "local").

### Channel Configurations

Channel-specific settings in `configs/channels/*.yaml`:
- fairy_tale: Children's fairy tales
- horror: Horror stories
- romance: Romance stories

## Working with APIs

### Current Integrations

1. **OpenAI API** (Story Generation)
   ```go
   // Set OPENAI_API_KEY environment variable
   // Implementation in internal/story/adapters/openai_client.go
   ```

2. **Redis** (Channel Caching)
   ```go
   // Connection configured in config files
   // Implementation in internal/channel/adapters/redis_repository.go
   ```

### Mock Mode

Test environment (`APP_ENV=test`) uses mock implementations:
- Returns predefined test data
- No external API calls
- Useful for development and testing

## CI/CD Pipeline

GitHub Actions workflow includes:

1. **format-check**: Ensures code is properly formatted
2. **lint-check**: Runs golangci-lint
3. **test-check**: Executes all tests
4. **coverage-check**: Generates coverage report
5. **ci-complete**: Final status check for auto-merge

### Auto-merge Setup

```bash
# Enable auto-merge after PR creation
gh pr merge --auto --squash [PR_NUMBER]
```

## Development Status

### Completed Phases (0-2)
- ✅ Project foundation and configuration system
- ✅ Hexagonal architecture implementation
- ✅ Domain models and interfaces
- ✅ Mock implementations
- ✅ Story generation with OpenAI
- ✅ Channel management with Redis

### In Progress (Phase 3+)
- ⏳ Scene splitting and image generation
- ⏳ TTS narration generation
- ⏳ Video composition with ffmpeg-go
- ⏳ YouTube upload automation
- ⏳ CLI interface improvements
- ⏳ Scheduler implementation

## Important Implementation Notes

1. **Error Handling**: Always check and handle errors explicitly (Go philosophy)
2. **Testing**: Maintain high test coverage for business logic packages
3. **Configuration**: Use YAML files for all configurations, not hardcoded values
4. **Logging**: Use structured logging with slog package
5. **Dependencies**: Check go.mod before adding new dependencies

## Common Tasks

### Adding a New Feature

1. Create package structure following hexagonal architecture:
   ```
   internal/newfeature/
   ├── core/
   │   └── service.go
   ├── ports/
   │   └── interfaces.go
   └── adapters/
       └── implementation.go
   ```

2. Define interfaces in ports package
3. Implement business logic in core package
4. Add external integrations in adapters
5. Write comprehensive tests
6. Update configuration if needed

### Running Specific Services

```bash
# Story generation test
go run ./cmd/pipeline-test

# API server
go run ./cmd/api

# CLI with specific channel
go run ./cmd/cli generate --channel fairy_tale
```

### Debugging

```bash
# Enable debug logging
APP_LOG_LEVEL=debug go run ./cmd/cli

# Check Redis connection
redis-cli ping

# View PostgreSQL logs
docker-compose logs -f postgres
```

## Project-Specific Guidelines

1. **Phase-based Development**: Follow the plan.md for feature implementation order
2. **Mock First**: Implement mock versions before integrating external services
3. **Channel Abstraction**: All content generation should be channel-aware
4. **Resource Management**: Clean up temporary files in assets/temp/
5. **API Keys**: Never commit API keys; use environment variables

## Troubleshooting

### Common Issues

1. **"Missing configuration"**: Ensure APP_ENV is set correctly
2. **"Redis connection failed"**: Run `docker-compose up -d`
3. **"API key not found"**: Set required environment variables
4. **Test failures**: Check if using test environment (`APP_ENV=test`)

### Development Tips

- Use `make dev` for quick development cycles
- Run `make coverage` to check test coverage
- Always run `make fmt` before committing
- Check `plan.md` for current development phase