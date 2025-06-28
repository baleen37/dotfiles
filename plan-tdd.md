# TDD Implementation Plan for YouTube Shorts Generator

## Project Overview

This plan provides detailed, step-by-step TDD prompts for completing the YouTube Shorts automatic generation system. The project follows Hexagonal Architecture (Ports and Adapters Pattern) and currently has completed phases 0-4, with phases 5-6 partially implemented.

## Current State Summary

### ✅ Completed
- Phase 0-2: Hexagonal Architecture foundation, Story/Channel domains
- Phase 3: Image generation (Stable Diffusion)
- Phase 4: TTS narration (Google Cloud TTS)
- Phase 5.1-5.3: Video domain basic structure and FFmpeg integration

### 🔄 In Progress
- Phase 5.4: Real media file integration testing
- Phase 6: YouTube domain (structure complete, needs API integration)

### ⏳ Not Started
- Phase 7: CLI commands (Cobra)
- Phase 8: Scheduler system
- Phase 9: Job queue system
- Phase 10: Integration and optimization

---

## Phase 5: Complete Video Domain Implementation

### Step 5.4: Real Media File Integration Testing

```text
Implement real media file integration tests for the Video domain.

Context:
- FFmpeg adapter basic structure is implemented and tests pass with mock files
- Need to verify actual video generation with real media files
- Must maintain backward compatibility with existing mock mode

Requirements:
1. Create integration tests that use real media files when SKIP_FFMPEG_EXECUTION is not set
2. Add sample test media files (small images, audio clips)
3. Verify Ken Burns effect and transitions work correctly
4. Validate output video meets YouTube Shorts specifications

TDD Process:
1. Write failing integration test in internal/video/integration_real_test.go
   - Test with actual image files (JPEG)
   - Test with actual audio files (WAV/MP3)
   - Test video composition with multiple scenes
   - Verify output video properties

2. Create test fixtures:
   - Add test images in testdata/images/
   - Add test audio in testdata/audio/
   - Keep files small for fast testing

3. Enhance FFmpeg adapter to handle:
   - Multiple image inputs with timing
   - Audio mixing (narration + background)
   - Basic Ken Burns effect
   - Output format optimization

4. Update validator to check:
   - Actual video duration
   - Resolution accuracy
   - Audio quality
   - File integrity

Implementation Notes:
- Use build tags to separate real vs mock tests
- Ensure tests skip gracefully when ffmpeg not available
- Add helper functions for test media generation
- Document required ffmpeg version and codecs

Expected Outcome:
- Integration tests pass with real media files
- Video output matches YouTube Shorts requirements
- Performance benchmarks established
- Clear documentation for production deployment
```

### Step 5.5: Advanced Video Effects Implementation

```text
Implement advanced video effects including Ken Burns and transitions.

Context:
- Basic video composition is working
- Need to add professional-looking effects for engaging content
- Must maintain performance while adding complexity

Requirements:
1. Implement Ken Burns effect (zoom and pan)
2. Add crossfade transitions between scenes
3. Implement subtitle overlay for accessibility
4. Add watermark/branding support

TDD Process:
1. Write tests for effect configurations:
   - Test Ken Burns parameter calculations
   - Test transition timing accuracy
   - Test subtitle positioning and timing
   - Test watermark placement

2. Create effect builder in internal/video/core/effects.go:
   - KenBurnsEffect struct with zoom/pan parameters
   - TransitionEffect for scene changes
   - SubtitleOverlay for text display
   - WatermarkOverlay for branding

3. Enhance FFmpeg adapter filter chains:
   - Build complex filter graphs
   - Chain multiple effects efficiently
   - Handle effect timing synchronization
   - Optimize for performance

4. Add configuration support:
   - Effect presets per channel type
   - Customizable effect parameters
   - Performance vs quality trade-offs

Testing Strategy:
- Unit tests for effect calculations
- Integration tests for filter generation
- Visual regression tests for output quality
- Performance benchmarks for effect processing

Expected Outcome:
- Professional-looking video effects
- Configurable per channel type
- Minimal performance impact
- Maintainable effect system
```

---

## Phase 6: Complete YouTube Integration

### Step 6.5: YouTube API Real Integration

```text
Implement actual YouTube API integration with OAuth2 authentication.

Context:
- YouTube domain structure is complete with mocks
- Need to implement real API calls
- Must handle OAuth2 flow for user authentication

Requirements:
1. Implement OAuth2 authentication flow
2. Create secure token storage
3. Implement video upload with progress tracking
4. Handle API quotas and rate limiting

TDD Process:
1. Write integration tests with YouTube API:
   - Test OAuth2 URL generation
   - Test token exchange (with test credentials)
   - Test video upload (to test channel)
   - Test metadata updates

2. Implement OAuth2 service enhancements:
   - Browser-based authentication flow
   - Token refresh logic
   - Secure token storage (encrypted file)
   - Multi-account support

3. Enhance YouTube adapter:
   - Chunked upload for large files
   - Progress callback implementation
   - Retry logic for failures
   - Quota tracking

4. Add CLI integration:
   - Interactive authentication command
   - Token management commands
   - Upload status monitoring

Security Considerations:
- Never log tokens or credentials
- Encrypt stored tokens
- Validate redirect URLs
- Implement token expiration handling

Expected Outcome:
- Working YouTube authentication
- Reliable video uploads
- Progress tracking
- Proper error handling
```

### Step 6.6: YouTube Channel Management

```text
Implement YouTube channel management features.

Context:
- Basic upload functionality exists
- Need channel-specific configurations
- Must support multiple YouTube accounts

Requirements:
1. Channel selection and verification
2. Channel-specific upload defaults
3. Playlist management
4. Upload scheduling

TDD Process:
1. Write tests for channel operations:
   - List available channels
   - Verify channel permissions
   - Create/update playlists
   - Schedule uploads

2. Extend YouTube service:
   - Channel listing API calls
   - Playlist CRUD operations
   - Scheduled upload support
   - Channel analytics retrieval

3. Add configuration mapping:
   - Map app channels to YouTube channels
   - Channel-specific metadata templates
   - Upload schedule preferences
   - Playlist organization rules

4. Implement channel commands:
   - youtube:channels:list
   - youtube:channels:link
   - youtube:playlists:create
   - youtube:schedule:set

Expected Outcome:
- Multi-channel support
- Automated playlist organization
- Scheduled uploads
- Channel performance tracking
```

---

## Phase 7: CLI Implementation

### Step 7.1: Cobra CLI Foundation

```text
Implement Cobra-based CLI foundation with proper architecture.

Context:
- Current CLI is basic with minimal functionality
- Need professional CLI with subcommands
- Must integrate with existing container/DI system

Requirements:
1. Migrate to Cobra command structure
2. Implement global flags and configuration
3. Add command hierarchy
4. Integrate with existing services

TDD Process:
1. Write CLI structure tests:
   - Test root command initialization
   - Test flag parsing
   - Test configuration loading
   - Test help generation

2. Implement root command:
   - Initialize Cobra application
   - Add persistent flags (--env, --config, --verbose)
   - Setup configuration loading
   - Initialize dependency container

3. Create command structure:
   ```
   ssulmeta
   ├── generate (video generation)
   ├── upload (YouTube upload)
   ├── list (resource listing)
   ├── config (configuration management)
   └── pipeline (full automation)
   ```

4. Add command factories:
   - Dependency injection setup
   - Service initialization
   - Error handling
   - Logging setup

Implementation Pattern:
- Each command in separate file
- Shared command utilities
- Consistent error handling
- Progress indicators

Expected Outcome:
- Professional CLI structure
- Consistent user experience
- Easy to extend
- Well-tested commands
```

### Step 7.2: Generate Command Implementation

```text
Implement the generate command for video creation.

Context:
- Need to orchestrate full pipeline
- Must provide progress feedback
- Should handle partial failures gracefully

Requirements:
1. Full pipeline orchestration
2. Progress tracking and display
3. Error recovery options
4. Output management

TDD Process:
1. Write generate command tests:
   - Test pipeline execution order
   - Test progress reporting
   - Test error scenarios
   - Test output file handling

2. Implement command logic:
   ```go
   type GenerateCommand struct {
       storyService  story.Service
       imageService  image.Service
       ttsService    tts.Service
       videoService  video.Service
   }
   ```

3. Add pipeline orchestration:
   - Sequential service calls
   - Progress aggregation
   - Intermediate file management
   - Error recovery points

4. Implement progress UI:
   - Spinner for active tasks
   - Progress bar for stages
   - ETA calculation
   - Detailed logging option

Error Handling:
- Save intermediate results
- Allow resume from failure
- Provide debug information
- Suggest solutions

Expected Outcome:
- Smooth generation experience
- Clear progress indication
- Robust error handling
- Professional output
```

### Step 7.3: Upload Command Implementation

```text
Implement the upload command for YouTube publishing.

Context:
- YouTube service exists but needs CLI integration
- Must handle authentication flow
- Should support batch uploads

Requirements:
1. OAuth2 authentication flow
2. Single and batch upload support
3. Progress tracking
4. Metadata customization

TDD Process:
1. Write upload command tests:
   - Test authentication flow
   - Test file validation
   - Test upload progress
   - Test metadata handling

2. Implement authentication:
   - Check existing tokens
   - Browser-based auth flow
   - Token persistence
   - Multi-account support

3. Add upload features:
   - File validation
   - Metadata generation
   - Progress display
   - Success confirmation

4. Implement batch mode:
   - Multiple file selection
   - Parallel uploads
   - Failure recovery
   - Summary reporting

User Experience:
- Clear authentication instructions
- Real-time progress updates
- Helpful error messages
- Success celebration

Expected Outcome:
- Seamless upload experience
- Reliable authentication
- Efficient batch processing
- Clear status reporting
```

### Step 7.4: Pipeline Command Implementation

```text
Implement the pipeline command for full automation.

Context:
- Combines generate and upload functionality
- Most important command for users
- Must be extremely reliable

Requirements:
1. Full end-to-end automation
2. Channel-based configuration
3. Scheduling support
4. Monitoring capabilities

TDD Process:
1. Write pipeline command tests:
   - Test full pipeline execution
   - Test configuration loading
   - Test scheduling logic
   - Test monitoring features

2. Implement pipeline orchestration:
   - Channel selection
   - Generation parameters
   - Upload configuration
   - Progress aggregation

3. Add scheduling support:
   - One-time execution
   - Cron-based scheduling
   - Schedule validation
   - Next run display

4. Implement monitoring:
   - Pipeline status tracking
   - Performance metrics
   - Success/failure rates
   - Resource usage

Advanced Features:
- Dry run mode
- Parallel channel processing
- Notification support
- Performance optimization

Expected Outcome:
- One-command automation
- Reliable execution
- Comprehensive monitoring
- Production-ready pipeline
```

---

## Phase 8: Scheduler System

### Step 8.1: Scheduler Foundation

```text
Implement the scheduler system foundation.

Context:
- Need automated content generation
- Must support multiple schedules
- Should be resilient and observable

Requirements:
1. Cron-based scheduling
2. Job persistence
3. Distributed locking
4. Monitoring capabilities

TDD Process:
1. Write scheduler tests:
   - Test cron parsing
   - Test job execution
   - Test locking mechanism
   - Test persistence

2. Implement core scheduler:
   ```go
   type Scheduler struct {
       cron     *cron.Cron
       jobRepo  JobRepository
       locker   DistributedLocker
       executor JobExecutor
   }
   ```

3. Add job management:
   - Job registration
   - Schedule updates
   - Job history
   - Failure tracking

4. Implement distributed locking:
   - Redis-based locks
   - Lock expiration
   - Deadlock prevention
   - Lock monitoring

Database Schema:
```sql
CREATE TABLE scheduler_jobs (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    schedule VARCHAR(100),
    config JSONB,
    next_run TIMESTAMP,
    last_run TIMESTAMP,
    status VARCHAR(50)
);
```

Expected Outcome:
- Reliable scheduling system
- Distributed execution support
- Comprehensive monitoring
- Easy job management
```

### Step 8.2: Scheduled Jobs Implementation

```text
Implement specific scheduled jobs for content generation.

Context:
- Scheduler foundation exists
- Need specific job implementations
- Must integrate with existing services

Requirements:
1. Channel-specific generation jobs
2. Cleanup jobs
3. Upload jobs
4. Monitoring jobs

TDD Process:
1. Write job implementation tests:
   - Test job execution
   - Test configuration handling
   - Test error scenarios
   - Test job dependencies

2. Implement generation jobs:
   ```go
   type GenerateVideoJob struct {
       channelType string
       pipeline    PipelineService
       notifier    Notifier
   }
   ```

3. Add job lifecycle:
   - Pre-execution checks
   - Execution monitoring
   - Post-execution cleanup
   - Failure notifications

4. Implement job configurations:
   - Channel-specific settings
   - Retry policies
   - Timeout configurations
   - Dependency management

Job Types:
- DailyVideoGeneration
- WeeklyCompilation  
- StorageCleanup
- QuotaMonitoring

Expected Outcome:
- Automated content pipeline
- Self-maintaining system
- Proactive monitoring
- Flexible scheduling
```

---

## Phase 9: Job Queue System

### Step 9.1: Queue Foundation

```text
Implement asynchronous job queue system.

Context:
- Need background processing capabilities
- Must handle long-running tasks
- Should provide visibility into job status

Requirements:
1. Redis-based queue (Asynq)
2. Priority queues
3. Job persistence
4. Monitoring dashboard

TDD Process:
1. Write queue tests:
   - Test job enqueuing
   - Test job processing
   - Test priority handling
   - Test failure recovery

2. Implement queue service:
   ```go
   type QueueService struct {
       client    *asynq.Client
       inspector *asynq.Inspector
       config    QueueConfig
   }
   ```

3. Add job definitions:
   - Job types enum
   - Payload structures
   - Priority levels
   - Retry policies

4. Implement workers:
   - Worker pool management
   - Concurrency control
   - Graceful shutdown
   - Health checks

Queue Features:
- Job scheduling
- Batch processing
- Dead letter queue
- Performance metrics

Expected Outcome:
- Scalable job processing
- Reliable task execution
- Comprehensive monitoring
- Easy job management
```

### Step 9.2: Queue Integration

```text
Integrate queue system with existing services.

Context:
- Queue foundation exists
- Need to integrate with CLI and scheduler
- Must maintain system coherence

Requirements:
1. CLI queue integration
2. Scheduler queue integration
3. Service layer integration
4. Monitoring integration

TDD Process:
1. Write integration tests:
   - Test CLI job submission
   - Test scheduler integration
   - Test service callbacks
   - Test monitoring flow

2. Enhance CLI commands:
   - Add --async flag
   - Job status command
   - Queue stats command
   - Job retry command

3. Integrate with scheduler:
   - Queue jobs from schedule
   - Handle job dependencies
   - Manage job chains
   - Track job lineage

4. Add service integration:
   - Async service methods
   - Progress callbacks
   - Result notifications
   - Error propagation

Integration Points:
- CLI → Queue
- Scheduler → Queue
- Queue → Services
- Queue → Monitoring

Expected Outcome:
- Seamless async processing
- Unified job management
- Complete observability
- Scalable architecture
```

---

## Phase 10: Testing and Optimization

### Step 10.1: Comprehensive Testing

```text
Implement comprehensive testing strategy.

Context:
- Individual components are tested
- Need end-to-end validation
- Must ensure production readiness

Requirements:
1. E2E test suite
2. Performance testing
3. Chaos testing
4. Security testing

TDD Process:
1. Write E2E tests:
   - Full pipeline tests
   - Multi-channel tests
   - Failure recovery tests
   - Load tests

2. Implement test scenarios:
   ```go
   type E2ETestSuite struct {
       services ServiceContainer
       cleanup  CleanupFunc
   }
   ```

3. Add performance tests:
   - Throughput testing
   - Latency measurement
   - Resource usage
   - Bottleneck identification

4. Implement chaos tests:
   - Service failures
   - Network issues
   - Resource exhaustion
   - Data corruption

Test Categories:
- Functional E2E
- Performance
- Reliability
- Security

Expected Outcome:
- Validated system behavior
- Performance baselines
- Reliability metrics
- Security compliance
```

### Step 10.2: Production Optimization

```text
Optimize system for production deployment.

Context:
- System is functionally complete
- Need production-grade performance
- Must be operationally excellent

Requirements:
1. Performance optimization
2. Resource optimization
3. Operational tooling
4. Documentation

TDD Process:
1. Write optimization benchmarks:
   - Service benchmarks
   - Database benchmarks
   - API benchmarks
   - Queue benchmarks

2. Implement optimizations:
   - Connection pooling
   - Caching strategies
   - Batch processing
   - Parallel execution

3. Add operational tools:
   - Health checks
   - Metrics export
   - Log aggregation
   - Debugging tools

4. Create documentation:
   - Architecture docs
   - Operation guides
   - Troubleshooting
   - Performance tuning

Optimization Areas:
- Database queries
- API calls
- File I/O
- Memory usage

Expected Outcome:
- Production-ready performance
- Operational excellence
- Complete documentation
- Monitoring readiness
```

---

## Implementation Guidelines

### TDD Cycle
1. **Red**: Write failing test first
2. **Green**: Implement minimum code to pass
3. **Refactor**: Improve code quality
4. **Document**: Add clear documentation
5. **Integrate**: Wire into existing system

### Best Practices
- Small, focused commits
- Comprehensive test coverage
- Clear error messages
- Performance considerations
- Security by design

### Architecture Principles
- Maintain hexagonal architecture
- Use dependency injection
- Keep domains isolated
- Test at appropriate levels
- Document decisions

### Progress Tracking
- Update plan.md after each step
- Mark completed items in todo.md
- Create issues for bugs
- Document learnings
- Celebrate milestones