.DEFAULT_GOAL := help

# Auto-detect USER if not set
USER ?= $(shell whoami)
NIX := nix --extra-experimental-features 'nix-command flakes'

# Platform detection using our platform-system
CURRENT_PLATFORM := $(shell $(NIX) eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).platform' | tr -d '"')
CURRENT_SYSTEM := $(shell $(NIX) eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).system' | tr -d '"')

#
# SIMPLE ATOMIC OPERATIONS (Parallel by default)
#

.PHONY: format test build check lint clean dev help
.PHONY: switch deploy validate performance ci docs setup

# Quality Gates (Atomic operations)
format:
	@echo "🎨 Formatting all files..."
	@$(NIX) develop --command nixfmt .
	@./scripts/auto-format.sh

lint:
	@echo "🔍 Running lint checks..."
	@pre-commit run --all-files

test:
	@echo "🧪 Running test suite..."
	@$(NIX) flake check --all-systems

# Build Operations (Atomic operations)
build:
	@echo "🔨 Building current platform: $(CURRENT_SYSTEM)"
	@$(NIX) build --json | jq -r '.[].outputs.out' || echo "No outputs to display"

check:
	@echo "🔍 Comprehensive validation..."
	@$(NIX) flake check --impure --all-systems --no-build

# Development Workflow
dev:
	@echo "🚀 Entering development shell..."
	@$(NIX) develop

clean:
	@echo "🧹 Cleaning build artifacts..."
	@$(NIX) store gc --print-dead
	@rm -f result*

# Performance and Validation
validate: check test

performance:
	@echo "📊 Running performance tests..."
	@./tests/performance/test-performance-monitor.sh

# CI/CD Support
ci: format lint test check
	@echo "✅ CI pipeline completed successfully"

# Documentation
docs:
	@echo "📚 Generating documentation..."
	@echo "Documentation targets available via individual make targets"

#
# SEQUENTIAL OPERATIONS (When ordering required)
#

.NOTPARALLEL: deploy switch

# System Deployment (Sequential for safety)
switch: check
	@echo "🔄 Switching system configuration..."
	@USER=$(USER) $(NIX) run .#build-switch

deploy: test build
	@echo "🚀 Deploying configuration..."
	@USER=$(USER) $(NIX) run .#build-switch

#
# DEVELOPMENT SETUP
#

setup:
	@echo "🔧 Setting up development environment..."
	@pre-commit install
	@$(MAKE) format
	@echo "✅ Development environment ready"

setup-mcp:
	@echo "🤖 Setting up Claude Code MCP servers..."
	@./scripts/setup-claude-mcp --main

#
# UTILITIES AND INFORMATION
#

help:
	@echo "📋 Nix Dotfiles - Available Targets:"
	@echo ""
	@echo "🔧 Quality Gates (Atomic):"
	@echo "  format      - Format all files with nixfmt and auto-format"
	@echo "  lint        - Run pre-commit lint checks"
	@echo "  test        - Run comprehensive test suite"
	@echo "  check       - Validate flake without building"
	@echo ""
	@echo "🔨 Build Operations (Atomic):"
	@echo "  build       - Build current platform configuration"
	@echo "  validate    - Run check + test for validation"
	@echo ""
	@echo "🚀 Development:"
	@echo "  dev         - Enter development shell"
	@echo "  clean       - Clean build artifacts and nix store"
	@echo "  setup       - Initialize development environment"
	@echo ""
	@echo "📊 Performance & Monitoring:"
	@echo "  performance - Run performance tests"
	@echo "  ci          - Full CI pipeline (format + lint + test + check)"
	@echo ""
	@echo "🔄 System Management (Sequential):"
	@echo "  switch      - Build and switch system configuration"
	@echo "  deploy      - Full deployment with validation"
	@echo ""
	@echo "🤖 Tools:"
	@echo "  setup-mcp   - Install Claude Code MCP servers"
	@echo "  docs        - Documentation information"
	@echo ""
	@echo "💡 Platform Info:"
	@echo "  Current: $(CURRENT_PLATFORM) → $(CURRENT_SYSTEM)"
	@echo "  User: $(USER)"
	@echo ""
	@echo "🎯 Quick Start:"
	@echo "  make setup  # First time setup"
	@echo "  make ci     # Full validation pipeline"
	@echo "  make deploy # Apply configuration"

# Show platform information
platform-info:
	@echo "🖥️  Platform Information:"
	@echo "  Current System: $(CURRENT_SYSTEM)"
	@echo "  Platform: $(CURRENT_PLATFORM)"
	@echo "  User: $(USER)"
	@echo "  Nix Version: $$(nix --version)"

# Check prerequisites
check-user:
	@if [ -z "$(USER)" ]; then \
		echo "❌ ERROR: USER variable is not set"; \
		exit 1; \
	fi
	@echo "✅ USER is set to: $(USER)"

# Quick tests for development
test-quick:
	@echo "⚡ Running quick validation tests..."
	@./scripts/quick-test.sh

# Legacy compatibility targets (simplified)
smoke: check
test-core: test
build-current: build
lint-format: format lint