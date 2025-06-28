# Hexagonal Architecture Guide

This document describes the Hexagonal Architecture implementation in the ssulmeta-go project, an automated YouTube Shorts generation system.

## Architecture Overview

This project implements **Hexagonal Architecture** (Ports and Adapters Pattern) with **Domain-Driven Design** principles to create a maintainable, testable, and scalable system for generating YouTube Shorts automatically.

### Core Principles

1. **Business Logic Isolation**: Core domain logic is completely separated from external dependencies
2. **Dependency Inversion**: All dependencies point inward toward the core
3. **Domain-First Organization**: Features are organized by business domains
4. **Test-Driven Development**: Each layer is independently testable with high coverage
5. **Clean Boundaries**: Clear interfaces between layers prevent coupling

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         External Systems                         │
│  (OpenAI, Google TTS, YouTube API, Redis, PostgreSQL, ffmpeg)   │
└────────────────────────────┬───────────────────────────────────┘
                             │
┌────────────────────────────▼───────────────────────────────────┐
│                          Adapters                               │
│  (HTTP Handlers, API Clients, Database Repositories, CLI)      │
└────────────────────────────┬───────────────────────────────────┘
                             │
┌────────────────────────────▼───────────────────────────────────┐
│                           Ports                                 │
│              (Interfaces defining contracts)                    │
└────────────────────────────┬───────────────────────────────────┘
                             │
┌────────────────────────────▼───────────────────────────────────┐
│                           Core                                  │
│         (Pure Business Logic - No External Dependencies)        │
└─────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
ssulmeta-go/
├── cmd/                        # Application entry points
│   ├── api/                    # REST API server
│   ├── cli/                    # Command-line interface
│   └── pipeline-test/          # Pipeline testing tool
│
├── internal/                   # Private application code
│   ├── story/                  # Story generation domain
│   │   ├── core/              
│   │   │   ├── service.go      # Story generation logic
│   │   │   └── validator.go    # Story validation rules
│   │   ├── ports/             
│   │   │   └── interfaces.go   # StoryGenerator, StoryValidator interfaces
│   │   └── adapters/          
│   │       ├── openai_client.go    # OpenAI API integration
│   │       └── mock_generator.go   # Mock for testing
│   │
│   ├── channel/                # Channel management domain
│   │   ├── core/              
│   │   │   └── service.go      # Channel business logic
│   │   ├── ports/             
│   │   │   └── repository.go   # ChannelRepository interface
│   │   ├── adapters/          
│   │   │   ├── http.go         # REST API handlers
│   │   │   └── redis_repository.go # Redis caching
│   │   └── service/           
│   │       └── channel_service.go  # Service orchestration
│   │
│   ├── image/                  # Image generation domain
│   │   ├── core/              
│   │   │   └── service.go      # Scene splitting logic
│   │   ├── ports/             
│   │   │   └── interfaces.go   # ImageGenerator, SceneSplitter
│   │   └── adapters/          
│   │       └── stable_diffusion.go # AI image generation
│   │
│   ├── tts/                    # Text-to-speech domain
│   │   ├── core/              
│   │   │   └── service.go      # TTS orchestration
│   │   ├── ports/             
│   │   │   └── interfaces.go   # TTSGenerator interface
│   │   └── adapters/          
│   │       └── google_tts.go   # Google Cloud TTS
│   │
│   ├── video/                  # Video composition domain
│   │   ├── core/              
│   │   │   └── service.go      # Video composition logic
│   │   ├── ports/             
│   │   │   └── interfaces.go   # VideoComposer, EffectApplier
│   │   └── adapters/          
│   │       ├── ffmpeg_adapter.go   # ffmpeg integration
│   │       └── validator.go        # Video validation
│   │
│   ├── youtube/                # YouTube upload domain
│   │   ├── core/              
│   │   │   └── service.go      # Upload orchestration
│   │   ├── ports/             
│   │   │   └── interfaces.go   # Uploader, MetadataGenerator
│   │   └── adapters/          
│   │       ├── youtube_adapter.go  # YouTube API v3
│   │       ├── oauth_service.go    # OAuth2 authentication
│   │       └── metadata_generator.go # SEO metadata
│   │
│   ├── config/                 # Configuration management
│   ├── container/              # Dependency injection
│   └── db/                     # Database utilities
│
├── pkg/                        # Public packages
│   ├── models/                 # Shared domain models
│   ├── errors/                 # Custom error types
│   └── logger/                 # Structured logging
│
└── configs/                    # Configuration files
    ├── channels/               # Channel-specific configs
    └── *.yaml                  # Environment configs
```

## Layer Responsibilities

### 1. Core Layer (Business Logic)

The core contains pure business logic with no external dependencies. It defines the essential business rules and operations.

```go
// internal/story/core/service.go
type StoryService struct {
    validator StoryValidator
}

func (s *StoryService) GenerateStory(prompt string, channelType string) (*Story, error) {
    // Pure business logic for story generation
    story := &Story{
        Content: processPrompt(prompt),
        Type:    channelType,
    }
    
    if err := s.validator.Validate(story); err != nil {
        return nil, err
    }
    
    return story, nil
}
```

**Characteristics:**
- No imports from external packages (except standard library)
- Pure functions and business entities
- 100% unit testable
- Contains domain models and business rules

### 2. Ports Layer (Interfaces)

Ports define the contracts between core and external world. They act as the API for the core domain.

```go
// internal/story/ports/interfaces.go
type StoryGenerator interface {
    Generate(ctx context.Context, req GenerateRequest) (*GenerateResponse, error)
}

type StoryValidator interface {
    Validate(story *models.Story) error
}

type StoryRepository interface {
    Save(ctx context.Context, story *models.Story) error
    FindByID(ctx context.Context, id string) (*models.Story, error)
}
```

**Characteristics:**
- Interface definitions only
- No implementation details
- Defines input/output contracts
- Enables dependency inversion

### 3. Adapters Layer (External Integration)

Adapters implement the port interfaces and handle communication with external systems.

```go
// internal/story/adapters/openai_client.go
type OpenAIAdapter struct {
    client     *openai.Client
    config     *config.OpenAIConfig
    rateLimit  *rateLimiter
}

func (a *OpenAIAdapter) Generate(ctx context.Context, req GenerateRequest) (*GenerateResponse, error) {
    // Convert domain request to OpenAI API format
    completion, err := a.client.CreateChatCompletion(ctx, openai.ChatCompletionRequest{
        Model:       a.config.Model,
        Messages:    buildMessages(req),
        Temperature: a.config.Temperature,
    })
    
    // Convert OpenAI response to domain response
    return toDomainResponse(completion), nil
}
```

**Characteristics:**
- Implements port interfaces
- Handles external protocols (HTTP, gRPC, etc.)
- Manages external dependencies
- Converts between external and domain formats

## Dependency Flow

```go
// cmd/cli/main.go - Dependency injection at application root
func main() {
    // Load configuration
    cfg := config.Load()
    
    // Create core services
    storyValidator := storyCore.NewValidator()
    storyService := storyCore.NewService(storyValidator)
    
    // Create adapters with configuration
    var storyGenerator ports.StoryGenerator
    if cfg.API.UseMock {
        storyGenerator = storyAdapters.NewMockGenerator()
    } else {
        storyGenerator = storyAdapters.NewOpenAIAdapter(cfg.API.OpenAI)
    }
    
    // Wire everything together
    pipeline := NewPipeline(storyService, storyGenerator)
    
    // Run application
    pipeline.Execute()
}
```

## Domain Interactions

### Example: Generating a YouTube Short

```
1. CLI Command → Story Domain
   - User requests video generation
   - Story core validates channel type
   - OpenAI adapter generates story

2. Story → Image Domain
   - Scene splitter divides story
   - Image generator creates visuals
   - Validator ensures correct format

3. Story → TTS Domain
   - TTS generator creates narration
   - Audio validator checks quality

4. Image + Audio → Video Domain
   - Video composer combines assets
   - ffmpeg adapter applies effects
   - Validator checks output

5. Video → YouTube Domain
   - Metadata generator creates SEO data
   - YouTube adapter uploads video
   - OAuth service handles authentication
```

## Testing Strategy

### 1. Core Layer Tests

Test pure business logic without any external dependencies:

```go
func TestStoryValidator_Validate(t *testing.T) {
    validator := NewValidator()
    
    tests := []struct {
        name    string
        story   *models.Story
        wantErr bool
    }{
        {
            name: "valid story",
            story: &models.Story{
                Content: "Valid story content with proper length...",
                Type:    "fairy_tale",
            },
            wantErr: false,
        },
        {
            name: "story too short",
            story: &models.Story{
                Content: "Too short",
                Type:    "fairy_tale",
            },
            wantErr: true,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := validator.Validate(tt.story)
            assert.Equal(t, tt.wantErr, err != nil)
        })
    }
}
```

### 2. Adapter Tests

Test external integrations with mocks:

```go
func TestOpenAIAdapter_Generate(t *testing.T) {
    mockClient := &MockOpenAIClient{}
    adapter := NewOpenAIAdapter(mockClient, testConfig)
    
    mockClient.On("CreateChatCompletion", mock.Anything, mock.Anything).
        Return(mockResponse, nil)
    
    resp, err := adapter.Generate(context.Background(), testRequest)
    
    assert.NoError(t, err)
    assert.NotNil(t, resp)
    mockClient.AssertExpectations(t)
}
```

### 3. Integration Tests

Test complete workflows:

```go
func TestFullPipeline_Integration(t *testing.T) {
    if testing.Short() {
        t.Skip("Skipping integration test")
    }
    
    // Setup real services
    pipeline := setupTestPipeline()
    
    // Execute full workflow
    result, err := pipeline.GenerateVideo(testChannel)
    
    assert.NoError(t, err)
    assert.FileExists(t, result.VideoPath)
}
```

### 4. Architecture Tests

Automated tests to enforce architectural rules:

```go
func TestArchitecture(t *testing.T) {
    // Core packages cannot depend on adapters
    corePkgs := Package("ssulmeta-go/internal/*/core/...")
    adapterPkgs := Package("ssulmeta-go/internal/*/adapters/...")
    
    corePkgs.ShouldNot().DependDirectlyOn(adapterPkgs).
        Because("core should not depend on adapters")
    
    // Only adapters can import external libraries
    allPkgs := Package("ssulmeta-go/...")
    externalPkgs := Package("github.com/...", "google.golang.org/...", "golang.org/x/...")
    
    allPkgs.That().Are().Not(adapterPkgs).
        ShouldNot().DependDirectlyOn(externalPkgs).
        Because("only adapters should use external dependencies")
}
```

## Configuration Management

### Environment-Based Configuration

```yaml
# configs/local.yaml
app:
  name: ssulmeta-go
  env: local
  debug: true

api:
  use_mock: false
  openai:
    model: gpt-4
    temperature: 0.7
    rate_limit: 10

storage:
  base_path: ./storage
  temp_path: ./temp
```

### Secrets Management

```go
// Secrets loaded from environment or vault
type Secrets struct {
    OpenAIKey    string `env:"OPENAI_API_KEY"`
    GoogleCreds  string `env:"GOOGLE_APPLICATION_CREDENTIALS"`
    YouTubeOAuth OAuth2Config
}
```

## Best Practices

### 1. Domain Modeling

- Keep domain models in `pkg/models` for sharing
- Use value objects for business concepts
- Implement domain-specific validation

### 2. Error Handling

```go
// Define domain-specific errors
var (
    ErrStoryTooShort = errors.New("story must be at least 270 characters")
    ErrInvalidChannel = errors.New("invalid channel type")
)

// Wrap errors with context
return fmt.Errorf("failed to generate story: %w", err)
```

### 3. Dependency Injection

- Wire dependencies in `main.go` or container package
- Use interfaces for all dependencies
- Prefer constructor injection

### 4. Testing

- Aim for >80% coverage in core packages
- Use table-driven tests
- Mock external dependencies
- Test error scenarios

## Adding New Features

### Step-by-Step Guide

1. **Define the Domain**
   ```bash
   mkdir -p internal/newfeature/{core,ports,adapters}
   ```

2. **Create Port Interfaces**
   ```go
   // internal/newfeature/ports/interfaces.go
   type FeatureService interface {
       Process(ctx context.Context, input Input) (*Output, error)
   }
   ```

3. **Implement Core Logic**
   ```go
   // internal/newfeature/core/service.go
   type Service struct {
       validator Validator
   }
   
   func (s *Service) Process(input Input) (*Output, error) {
       // Business logic here
   }
   ```

4. **Create Adapters**
   ```go
   // internal/newfeature/adapters/http.go
   type HTTPAdapter struct {
       service ports.FeatureService
   }
   ```

5. **Write Tests**
   - Core logic unit tests
   - Adapter integration tests
   - End-to-end tests

6. **Wire Dependencies**
   ```go
   // In main.go
   featureService := featureCore.NewService()
   featureAdapter := featureAdapters.NewHTTPAdapter(featureService)
   ```

## Performance Considerations

### Caching Strategy

- Redis for channel configurations
- In-memory cache for frequently accessed data
- Cache invalidation on updates

### Concurrency

- Use context for cancellation
- Implement timeouts for external calls
- Use worker pools for parallel processing

### Resource Management

- Clean up temporary files
- Implement connection pooling
- Monitor memory usage

## Security

### API Security

- OAuth2 for YouTube authentication
- API key validation for external services
- Rate limiting per client

### Data Protection

- Encrypt sensitive configuration
- Sanitize user inputs
- Audit logging for sensitive operations

## Monitoring and Observability

### Structured Logging

```go
logger.Info("story generated",
    slog.String("channel", channelType),
    slog.Int("length", len(story.Content)),
    slog.Duration("duration", time.Since(start)),
)
```

### Metrics

- Request duration histograms
- Error rate counters
- Business metrics (videos generated, etc.)

### Health Checks

- Database connectivity
- External API availability
- Disk space for video processing

## Conclusion

This architecture provides:

- **Maintainability**: Clear separation of concerns
- **Testability**: Each layer independently testable
- **Flexibility**: Easy to swap implementations
- **Scalability**: Domain-driven design supports growth
- **Reliability**: Comprehensive error handling and monitoring

The hexagonal architecture ensures that business logic remains pure and testable while keeping external concerns at the boundaries of the system.