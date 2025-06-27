.PHONY: build test run clean lint fmt coverage

# Variables
BINARY_NAME=youtube-shorts-generator
MAIN_PATH=./cmd/cli
GO=go
GOFLAGS=-v

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

# Format code
fmt:
	$(GO) fmt ./...
	@if command -v goimports >/dev/null 2>&1; then \
		goimports -w .; \
	else \
		echo "Warning: goimports not found, skipping import formatting"; \
	fi

# Run linter
lint:
	golangci-lint run

# Install dependencies
deps:
	$(GO) mod download
	$(GO) mod tidy
	@echo "Setting up pre-commit hooks..."
	@$(MAKE) setup-hooks

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
	@$(MAKE) ensure-hooks
	APP_ENV=local $(GO) run $(MAIN_PATH)

# Ensure git hooks are installed (skip if already exists)
ensure-hooks:
	@if [ ! -f ".git/hooks/pre-commit" ] && [ ! -f "$$(cat .git 2>/dev/null | sed 's/gitdir: //')/hooks/pre-commit" 2>/dev/null ]; then \
		echo "Installing pre-commit hooks..."; \
		$(MAKE) setup-hooks; \
	fi

# Custom git hooks setup
setup-hooks:
	@echo "Setting up custom git hooks..."
	@chmod +x scripts/setup-hooks.sh
	@./scripts/setup-hooks.sh

# Help
help:
	@echo "Available commands:"
	@echo "  make build       - Build the application"
	@echo "  make test        - Run tests"
	@echo "  make arch-test   - Run architecture tests"
	@echo "  make coverage    - Run tests with coverage"
	@echo "  make run         - Build and run the application"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make fmt         - Format code"
	@echo "  make lint        - Run linter"
	@echo "  make deps        - Install dependencies and pre-commit hooks"
	@echo "  make dev         - Run in development mode (auto-installs hooks)"
	@echo "  make setup-hooks - Install custom git pre-commit hooks"
	@echo "  make help        - Show this help message"