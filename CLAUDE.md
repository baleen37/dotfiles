# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Environment

This project uses Nix flakes for development environment management. The development shell includes:
- Go compiler and tools
- gopls (Go language server)
- go-tools (goimports, gofmt, etc.)
- delve (Go debugger)
- golangci-lint (comprehensive Go linter)

### Setup Commands

```bash
# Enter development environment (requires direnv and nix)
direnv allow

# Or manually activate the nix shell
nix develop
```

### Common Go Commands

```bash
# Build the project
go build ./...

# Run the main program
go run main.go

# Format code
gofmt -w .

# Import organization
goimports -w .

# Lint with golangci-lint
golangci-lint run

# Lint specific directories
golangci-lint run ./utils ./handlers

# Lint with detailed output
golangci-lint run --verbose

# Show linter information
golangci-lint linters
```

### Linting Configuration

The project uses `golangci-lint` version 2.1.6 with default configuration.

#### Default Enabled Linters
- **errcheck**: Checks for unchecked errors (very important in Go!)
- **govet**: Go's built-in analyzer for common mistakes
- **ineffassign**: Detects ineffectual assignments
- **staticcheck**: Advanced static analysis
- **unused**: Finds unused code

#### Configuration Notes
- Uses default configuration (no custom .golangci.yml file)
- Version 2.1.6 is older but stable and sufficient for basic Go linting
- Focus on `errcheck` - Go's philosophy requires explicit error handling
- All production code should pass linting without issues
- Test files may occasionally ignore certain checks for demonstration purposes using `// nolint:` comments

#### Advanced Configuration
If you need custom linting rules, you can create a `.golangci.yml` file, but note that version 2.1.6 has limited configuration options compared to newer versions.

### Testing Commands

This project includes comprehensive test suite with unit tests, benchmarks, and example tests.

#### Basic Testing

```bash
# Run all tests
go test ./...

# Run tests with verbose output
go test -v ./...

# Run tests for specific package
go test ./utils
go test ./handlers

# Run specific test by name
go test -run TestAdd ./utils
go test -run TestHelloHandler ./handlers
```

#### Test Coverage

```bash
# Run tests with basic coverage report
go test -cover ./...

# Generate detailed coverage profile
go test -coverprofile=coverage.out ./...

# View coverage as HTML report
go tool cover -html=coverage.out -o coverage.html

# View function-level coverage in terminal
go tool cover -func=coverage.out

# Open HTML coverage report in browser (macOS)
open coverage.html
```

#### Benchmark Testing

```bash
# Run all benchmark tests
go test -bench=. ./...

# Run benchmarks for specific package
go test -bench=. ./utils
go test -bench=. ./handlers

# Run specific benchmark
go test -bench=BenchmarkAdd ./utils
go test -bench=BenchmarkReverseString ./utils

# Run benchmarks with memory allocation stats
go test -bench=. -benchmem ./...

# Run benchmarks multiple times for accuracy
go test -bench=. -count=5 ./utils
```

#### Example Testing

```bash
# Run example tests (also serves as documentation)
go test -run=Example ./...

# Run examples for specific package
go test -run=Example ./utils
go test -run=Example ./handlers

# View example output
go test -v -run=Example ./utils
```

#### Advanced Testing Options

```bash
# Run tests with race detection
go test -race ./...

# Run tests in parallel
go test -parallel 4 ./...

# Run tests with timeout
go test -timeout 30s ./...

# Run only short tests (skip long-running tests)
go test -short ./...

# Combine multiple options
go test -v -cover -race -bench=. ./...
```

#### Test File Organization

- `*_test.go`: Test files (automatically discovered by go test)
- `TestXxx(t *testing.T)`: Unit tests
- `BenchmarkXxx(b *testing.B)`: Benchmark tests  
- `ExampleXxx()`: Example tests (with Output: comments for verification)

#### Coverage Goals

- **Current Coverage**: utils (100%), handlers (100%), overall (72.7%)
- **Target**: Maintain 100% coverage for all business logic packages
- **Note**: main.go shows 0% because integration tests don't count toward coverage

## Project Structure

```
ssulmeta-go/
├── main.go                 # Entry point with demonstrations
├── main_test.go           # Integration tests for main package
├── go.mod                 # Go module definition
├── utils/                 # Utility functions package
│   ├── utils.go          # Math and string utility functions
│   └── utils_test.go     # Unit tests, benchmarks, and examples
├── handlers/              # Handler functions package
│   ├── handlers.go       # HTTP-like handler functions
│   └── handlers_test.go  # Unit tests, benchmarks, and examples
├── plan.md               # Development plan and progress tracking
├── CLAUDE.md             # This file - development guidelines
├── flake.nix             # Nix development environment
├── .envrc                # direnv configuration
└── .gitignore            # Git ignore rules
```

### Package Organization

- **main**: Entry point demonstrating all functionality
- **utils**: Pure utility functions (math, string operations)
- **handlers**: Application handlers with error handling and business logic
- Each package has comprehensive tests including unit tests, benchmarks, and examples

## Development Guidelines

**IMPORTANT**: The developer is new to Go and wants to learn step by step. Always ask for permission before:
- Introducing new libraries or dependencies
- Adding new Go concepts or patterns
- Making architectural decisions

Take time to explain Go concepts when implementing features.

## Nix Integration

- `flake.nix`: Defines the development environment with Go toolchain
- `.envrc`: Enables automatic environment activation with direnv
- Development shell automatically activates when entering the directory (with direnv)