# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Environment

This project uses Nix flakes for development environment management. The development shell includes:
- Go compiler and tools
- gopls (Go language server)
- go-tools (goimports, gofmt, etc.)
- delve (Go debugger)

### Setup Commands

```bash
# Enter development environment (requires direnv and nix)
direnv allow

# Or manually activate the nix shell
nix develop
```

### Common Go Commands

Since this is a Go project without a go.mod file yet, you'll likely need to:

```bash
# Initialize Go module (when ready to start coding)
go mod init [module-name]

# Build the project
go build ./...

# Run tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run a specific test
go test -run TestName ./path/to/package

# Format code
gofmt -w .

# Import organization
goimports -w .

# Lint (requires golangci-lint to be added to flake.nix)
golangci-lint run
```

## Project Structure

This is a fresh Go project with Nix-based development environment. The actual Go code structure will be established as development progresses.

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