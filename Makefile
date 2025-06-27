.PHONY: build test run clean lint fmt coverage install-tools check-env ci-check ci-fmt

# Variables
BINARY_NAME=youtube-shorts-generator
MAIN_PATH=./cmd/cli
GO=go
GOFLAGS=-v

# Tool versions (matching CI environment)
GOLANGCI_LINT_VERSION := v1.61.0
GOIMPORTS_VERSION := latest

# Build the application
build:
	$(GO) build $(GOFLAGS) -o $(BINARY_NAME) $(MAIN_PATH)

# Run tests
test:
	$(GO) test $(GOFLAGS) ./...

# Run architecture tests
arch-test:
	$(GO) test $(GOFLAGS) ./architecture_test.go

# Run tests with coverage
coverage:
	$(GO) test -v -cover -coverprofile=coverage.out ./...

# Generate HTML coverage report
coverage-html: coverage
	$(GO) tool cover -html=coverage.out -o coverage.html

# Run the application
run: build
	./$(BINARY_NAME)

# Clean build artifacts
clean:
	rm -f $(BINARY_NAME)
	rm -f coverage.out coverage.html
	rm -rf assets/temp/*

# Install development tools (matching CI versions)
install-tools:
	@echo "📦 Installing development tools..."
	@echo "Installing goimports@$(GOIMPORTS_VERSION)..."
	$(GO) install golang.org/x/tools/cmd/goimports@$(GOIMPORTS_VERSION)
	@echo "Installing golangci-lint@$(GOLANGCI_LINT_VERSION)..."
	$(GO) install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)
	@echo "✅ Tools installed successfully"

# Check development environment
check-env:
	@echo "📋 Development environment check:"
	@echo "Go version: $$(go version)"
	@echo "golangci-lint version: $$(golangci-lint version 2>/dev/null || echo '❌ Not installed - run make install-tools')"
	@echo "goimports version: $$(goimports -help 2>&1 | head -1 || echo '❌ Not installed - run make install-tools')"

# Format code (CI-compatible with graceful degradation)
fmt:
	$(GO) fmt ./...
	@if command -v goimports >/dev/null 2>&1; then \
		goimports -w .; \
	else \
		echo "Warning: goimports not found, skipping import formatting"; \
	fi

# Strict format code (requires all tools)
fmt-strict:
	$(GO) fmt ./...
	@if command -v goimports >/dev/null 2>&1; then \
		goimports -w .; \
	else \
		echo "❌ goimports not found. Run 'make install-tools' first"; \
		exit 1; \
	fi

# CI-compatible format check (same logic as CI)
ci-fmt:
	@echo "🔍 Running CI-compatible format check..."
	make fmt
	@if [[ -n $$(git status --porcelain) ]]; then \
		echo "❌ Code formatting issues found"; \
		git diff; \
		exit 1; \
	fi
	@echo "✅ Code formatting is correct"

# Run linter (ensure tool is available)
lint:
	@if ! command -v golangci-lint >/dev/null 2>&1; then \
		echo "❌ golangci-lint not found. Run 'make install-tools' first"; \
		exit 1; \
	fi
	golangci-lint run

# Run all CI checks locally (matching CI pipeline)
ci-check: ci-fmt lint test arch-test
	@echo "✅ All CI checks passed locally"

# Run all checks with strict formatting (for local development)
check-strict: fmt-strict lint test arch-test
	@echo "✅ All checks passed locally with strict formatting"

# Install dependencies
deps:
	$(GO) mod download
	$(GO) mod tidy

# Database migrations
migrate-up:
	@echo "Running database migrations..."
	# Add migration command here

migrate-down:
	@echo "Rolling back database migrations..."
	# Add rollback command here

# Development mode with hot reload
dev:
	@echo "Starting in development mode..."
	APP_ENV=local $(GO) run $(MAIN_PATH)

# Custom git hooks setup
setup-hooks:
	@echo "Setting up custom git hooks..."
	@chmod +x scripts/setup-hooks.sh
	@./scripts/setup-hooks.sh

# Help
help:
	@echo "Available commands:"
	@echo "  make build         - Build the application"
	@echo "  make test          - Run tests"
	@echo "  make arch-test     - Run architecture tests"
	@echo "  make coverage      - Run tests with coverage"
	@echo "  make run           - Build and run the application"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make fmt           - Format code (graceful if tools missing)"
	@echo "  make fmt-strict    - Format code (requires all tools)"
	@echo "  make ci-fmt        - CI-compatible format check"
	@echo "  make lint          - Run linter (requires tools)"
	@echo "  make ci-check      - Run all CI checks locally"
	@echo "  make check-strict  - Run all checks with strict formatting"
	@echo "  make install-tools - Install development tools (CI versions)"
	@echo "  make check-env     - Check development environment"
	@echo "  make deps          - Install dependencies"
	@echo "  make dev           - Run in development mode"
	@echo "  make setup-hooks   - Install custom git pre-commit hooks"
	@echo "  make help          - Show this help message"