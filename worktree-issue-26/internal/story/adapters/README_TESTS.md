# Story Adapters Unit Tests

This directory contains comprehensive unit tests for the story generation adapters.

## Test Coverage

- **Overall Coverage**: 93.8%
- **MockGenerator**: 100% coverage
- **OpenAIGenerator**: 93.8% coverage
  - `GenerateStory`: 84.4% (some error handling paths not covered)
  - All other methods: 100%

## Test Files

### mock_generator_test.go

Tests for the mock story generator implementation:
- Generator creation
- Story generation with valid content length (270-300 characters)
- Consistent output across multiple runs
- Scene division functionality
- Edge cases (nil channel, empty content, trailing spaces)

### openai_client_test.go

Tests for the OpenAI API integration:
- Generator initialization with configuration
- API request/response handling with mock HTTP transport
- Story parsing from various response formats
- Error handling (API errors, network errors, malformed responses)
- Scene division algorithms
- Context cancellation support

## Running Tests

```bash
# Run all tests
go test -v ./internal/story/adapters/...

# Run with coverage
go test -cover ./internal/story/adapters/...

# Generate coverage report
go test -coverprofile=coverage.out ./internal/story/adapters/...
go tool cover -html=coverage.out -o coverage.html

# Run benchmarks
go test -bench=. -benchmem ./internal/story/adapters/...
```

## Key Testing Patterns

1. **HTTP Mocking**: Uses a custom `mockHTTPTransport` that implements `http.RoundTripper` for testing HTTP interactions without making real API calls.

2. **Table-Driven Tests**: Extensive use of table-driven tests for comprehensive coverage of edge cases.

3. **Subtests**: Uses `t.Run()` for organized test output and better test isolation.

4. **Benchmarks**: Performance benchmarks for critical operations like story parsing and scene division.

## Test Helpers

- `createMockResponse()`: Creates mock HTTP responses with proper structure
- `mockHTTPTransport`: Custom transport for intercepting and mocking HTTP requests
- Various verify functions for complex assertion logic