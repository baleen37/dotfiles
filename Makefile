# Makefile for ssulmeta-go
# Aligns with pre-commit configuration and CLAUDE.md documentation

# Default target
.DEFAULT_GOAL := help

# Non-file targets
.PHONY: help build run fmt lint test test-verbose coverage coverage-html bench pre-commit-install pre-commit-run pre-commit-check check clean

# Help target - shows available commands
help:
	@echo "Available targets:"
	@echo "  build            - Compile the project"
	@echo "  run              - Execute main program"
	@echo "  fmt              - Format code (gofmt)"
	@echo "  lint             - Run golangci-lint (matches pre-commit)"
	@echo "  test             - Run all tests"
	@echo "  test-verbose     - Run tests with verbose output"
	@echo "  coverage         - Generate test coverage report"
	@echo "  coverage-html    - Generate HTML coverage report"
	@echo "  bench            - Run benchmark tests"
	@echo "  pre-commit-install - Install pre-commit hooks"
	@echo "  pre-commit-run   - Run pre-commit on all files"
	@echo "  pre-commit-check - Run pre-commit on staged files"
	@echo "  check            - Complete validation (fmt + lint + test)"
	@echo "  clean            - Remove generated files"
	@echo "  help             - Show this help message"

# Build targets
build:
	go build ./...

run:
	go run main.go

# Code formatting
fmt:
	gofmt -w .

# Linting (matches pre-commit hook exactly)
lint:
	golangci-lint run

# Testing targets
test:
	go test ./...

test-verbose:
	go test -v ./...

coverage:
	go test -cover ./...

coverage-html:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

bench:
	go test -bench=. ./...

# Pre-commit integration
pre-commit-install:
	pre-commit install

pre-commit-run:
	pre-commit run --all-files

pre-commit-check:
	pre-commit run

# Compound targets
check: fmt lint test
	@echo "All checks passed!"

# Cleanup
clean:
	rm -f coverage.out coverage.html
	@echo "Cleaned generated files"