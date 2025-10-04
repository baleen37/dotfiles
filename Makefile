.DEFAULT_GOAL := help

# Auto-detect USER if not set
USER ?= $(shell whoami)
ARCH := $(shell uname -m)
OS := $(shell uname -s | tr A-Z a-z)
NIX := nix --extra-experimental-features 'nix-command flakes'

# Platform detection using our platform-system
PLATFORM_SYSTEM_BASE := $(NIX) eval --impure --expr 'import ./lib/platform-system.nix { system = builtins.currentSystem; }'
CURRENT_PLATFORM := $(shell $(NIX) eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).platform' | tr -d '"')
CURRENT_ARCH := $(shell $(NIX) eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).arch' | tr -d '"')
CURRENT_SYSTEM := $(shell $(NIX) eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).system' | tr -d '"')

# Check if USER is properly set
check-user:
	@if [ -z "$(USER)" ]; then \
		echo "❌ ERROR: USER variable is not set. Please run: export USER=\$$(whoami)"; \
		exit 1; \
	fi
	@echo "✅ USER is set to: $(USER)"

help:
	@echo "📋 Available targets (USER auto-detected as: $(USER)):"
	@echo "🖥️  Current platform: $(CURRENT_PLATFORM) ($(CURRENT_ARCH)) → $(CURRENT_SYSTEM)"
	@echo ""
	@echo "🔧 Development:"
	@echo "  lint        - Run pre-commit lint checks"
	@echo "  lint-format - Run format + lint workflow (recommended)"
	@echo "  smoke       - Run nix flake checks for all systems"
	@echo "  platform-info - Show detailed platform information"
	@echo ""
	@echo "🎨 Auto-formatting:"
	@echo "  format      - Auto-format all files (Nix, shell, YAML, JSON, Markdown)"
	@echo "  format-check - Check if files need formatting (CI mode)"
	@echo "  format-dry-run - Show what would be formatted without changes"
	@echo "  format-setup - Setup auto-formatting environment (install hooks + format)"
	@echo "  format-quick - Quick format for common files (Nix + shell)"
	@echo "  format-all  - Full workflow: format + lint + quick tests"
	@echo "  format-nix  - Format only Nix files"
	@echo "  format-shell - Format only shell scripts"
	@echo "  format-yaml - Format only YAML files"
	@echo "  format-json - Format only JSON files"
	@echo "  format-markdown - Format only Markdown files"
	@echo "  lint-format - Run format + lint workflow (recommended before commits)"
	@echo "  lint-autofix - Run linting with auto-fix enabled"
	@echo "  lint-install-autofix - Install pre-commit hooks with auto-fix"
	@echo ""
	@echo "🧪 Testing Framework (comprehensive):"
	@echo "  test        - Run essential tests (uses test-core)"
	@echo "  test-format - Run tests with format validation"
	@echo "  test-core   - Run core unit tests (no duplicates)"
	@echo "  test-unit   - Run Nix unit tests (nix-unit framework)"
	@echo "  test-contract - Run contract tests (interface validation)"
	@echo "  test-coverage - Run tests with coverage measurement"
	@echo "  test-quick  - Fast parallel validation tests"
	@echo "  test-monitor - Performance monitoring tests"
	@echo "  test-monitor-full - Full performance monitoring"
	@echo "  test-macos-services - 🧪 TDD-verified macOS Services tests (Darwin only)"
	@echo "  test-workflow - Run workflow tests (end-to-end)"
	@echo "  test-perf   - Run performance tests"
	@echo "  test-benchmark - Run comprehensive performance benchmarks"
	@echo "  test-memory-profile - Run memory usage analysis"
	@echo "  test-optimize - Run performance optimization controller"
	@echo "  test-report - Generate comprehensive performance report"
	@echo "  test-list   - List available test categories"
	@echo ""
	@echo "🔬 Unit Testing (중복 제거됨):"
	@echo "  test-unit-extended - Run remaining unit tests (no duplicates)"
	@echo "  (Note: Claude, Platform, User tests moved to BATS and Integration)"
	@echo ""
	@echo "🧪 BATS Testing Framework (단위 테스트):"
	@echo "  test-bats - Run all BATS shell script tests"
	@echo "  test-bats-lib - Run BATS library tests"
	@echo "  test-bats-system - Run BATS system tests"
	@echo "  test-bats-integration - Run BATS integration tests"
	@echo "  test-bats-claude - Test Claude activation (BATS 단위 테스트)"
	@echo "  test-bats-user-resolution - BATS user resolution tests (단위 테스트)"
	@echo "  test-bats-error-system - BATS error system tests"
	@echo "  test-bats-report - Generate TAP report for BATS tests"
	@echo "  test-bats-report-ci - Generate CI-compatible TAP report"
	@echo ""
	@echo "🤖 Claude Code MCP:"
	@echo "  setup-mcp   - Install MCP servers for Claude Code"
	@echo ""
	@echo "🔨 Building & Deployment:"
	@echo "  build       - Build all Darwin and NixOS configurations"
	@echo "  build-current - Build only current platform (faster)"
	@echo "  build-fast  - Fast build with optimizations"
	@echo "  build-switch - Build current platform and switch in one step"
	@echo "  dev-server  - Install dev-server with VSCode Tunnels"
	@echo "  apply       - Apply already built configuration"
	@echo "  switch      - Build + apply in one step (requires sudo)"
	@echo "  deploy      - Build+switch (works on any computer)"
	@echo ""
	@echo "💡 Tips:"
	@echo "  - Run 'make format' before committing to fix formatting issues"
	@echo "  - Use 'make lint-format' for the recommended pre-commit workflow"
	@echo "  - Use 'make format-setup' to initialize auto-formatting environment"
	@echo "  - USER is automatically detected, but you can override: USER=myuser make build"
	@echo "  - Use ARGS for additional nix flags: make build ARGS='--verbose'"
	@echo "  - Specify target system: make switch HOST=aarch64-darwin"

lint:
	@echo "🔍 Running pre-commit lint checks..."
	@pre-commit run --all-files

# Auto-formatting targets
format:
	@echo "🎨 Auto-formatting all files..."
	@./scripts/auto-format.sh

format-check:
	@echo "🔍 Checking if files need formatting..."
	@./scripts/auto-format.sh --check

format-dry-run:
	@echo "🔍 Showing what would be formatted (dry run)..."
	@./scripts/auto-format.sh --dry-run

format-nix:
	@echo "🎨 Formatting Nix files..."
	@./scripts/auto-format.sh nix

format-shell:
	@echo "🎨 Formatting shell scripts..."
	@./scripts/auto-format.sh shell

format-yaml:
	@echo "🎨 Formatting YAML files..."
	@./scripts/auto-format.sh yaml

format-json:
	@echo "🎨 Formatting JSON files..."
	@./scripts/auto-format.sh json

format-markdown:
	@echo "🎨 Formatting Markdown files..."
	@./scripts/auto-format.sh markdown

# Format all files and install auto-fix hooks
format-setup:
	@echo "🚀 Setting up auto-formatting environment..."
	@$(MAKE) lint-install-autofix
	@$(MAKE) format
	@echo "✅ Auto-formatting environment ready. Use 'make format' before commits."

# Quick format for common file types (fastest option)
format-quick:
	@echo "⚡ Quick format for common files (Nix + shell)..."
	@./scripts/auto-format.sh nix shell

# Full format workflow (format + lint + basic tests)
format-all:
	@echo "🔄 Running comprehensive format workflow..."
	@$(MAKE) format
	@$(MAKE) lint
	@$(MAKE) test-quick
	@echo "✅ Format workflow completed successfully"

# Enhanced linting with auto-fix
lint-autofix:
	@echo "🔧 Running linting with auto-fix enabled..."
	@pre-commit run --config .pre-commit-config-autofix.yaml --all-files

lint-install-autofix:
	@echo "🔧 Installing pre-commit hooks with auto-fix configuration..."
	@pre-commit install --config .pre-commit-config-autofix.yaml

# Comprehensive lint with formatting
lint-format:
	@echo "🎨 Running format + lint workflow..."
	@$(MAKE) format
	@$(MAKE) lint

ifdef SYSTEM
smoke:
	$(NIX) flake check --impure --system $(SYSTEM) --no-build $(ARGS)
else
smoke:
	$(NIX) flake check --impure --all-systems --no-build $(ARGS)
endif

# Simplified test targets - use existing test-core implementation
test:
	@echo "🧪 Running essential test suite..."
	@$(MAKE) test-core

# Test with formatting check
test-format:
	@echo "🧪 Running tests with format validation..."
	@$(MAKE) format-check
	@$(MAKE) test-core

test-core:
	@$(NIX) build --impure .#tests.$(shell nix eval --impure --expr builtins.currentSystem).all $(ARGS)

# New comprehensive test targets
test-unit:
	@echo "🧪 Running Nix unit tests (nix-unit framework)..."
	@$(NIX) build --impure .#packages.$(shell nix eval --impure --expr builtins.currentSystem).lib-functions $(ARGS)
	@$(NIX) build --impure .#packages.$(shell nix eval --impure --expr builtins.currentSystem).platform-detection $(ARGS)
	@echo "✅ Unit tests completed successfully!"

test-contract:
	@echo "🔍 Running contract tests (interface validation)..."
	@$(NIX) build --impure .#packages.$(shell nix eval --impure --expr builtins.currentSystem).module-interaction $(ARGS)
	@$(NIX) build --impure .#packages.$(shell nix eval --impure --expr builtins.currentSystem).cross-platform $(ARGS)
	@$(NIX) build --impure .#packages.$(shell nix eval --impure --expr builtins.currentSystem).system-configuration $(ARGS)
	@echo "✅ Contract tests completed successfully!"

test-coverage:
	@echo "📊 Running tests with coverage measurement..."
	@echo "Note: Coverage collection integrated into test framework"
	@$(MAKE) test-unit ARGS="--verbose"
	@$(MAKE) test-core ARGS="--verbose"

test-unit-coverage:
	@echo "📊 Running unit tests with coverage..."
	@if $(NIX) run --impure .#test-unit-coverage >/dev/null 2>&1; then \
		$(NIX) run --impure .#test-unit-coverage $(ARGS); \
	else \
		echo "⚠️ Coverage not yet implemented, running standard unit tests"; \
		$(MAKE) test-unit $(ARGS); \
	fi

test-contract-coverage:
	@echo "📊 Running contract tests with coverage..."
	@if $(NIX) run --impure .#test-contract-coverage >/dev/null 2>&1; then \
		$(NIX) run --impure .#test-contract-coverage $(ARGS); \
	else \
		echo "⚠️ Coverage not yet implemented, running standard contract tests"; \
		$(MAKE) test-contract $(ARGS); \
	fi

# macOS Services 관리 및 테스트 (Darwin 전용)
test-macos-services:
ifeq ($(PLATFORM),aarch64-darwin)
	@echo "🧪 Running macOS Services tests via system-configuration tests..."
	@$(NIX) build --impure .#packages.$(PLATFORM).system-configuration $(ARGS)
	@echo "✅ macOS Services tests completed successfully!"
else ifeq ($(PLATFORM),x86_64-darwin)
	@echo "🧪 Running macOS Services tests via system-configuration tests..."
	@$(NIX) build --impure .#packages.$(PLATFORM).system-configuration $(ARGS)
	@echo "✅ macOS Services tests completed successfully!"
else
	@echo "⏭️ Skipping macOS Services tests (not on Darwin platform)"
endif


test-workflow:
	@$(NIX) run --impure .#test-workflow $(ARGS)

test-perf:
	@$(NIX) run --impure .#test-perf $(ARGS)

test-list:
	@$(NIX) run --impure .#test-list $(ARGS)

# New comprehensive unit tests
test-unit-extended:
	@echo "🧪 Running extended unit tests for lib modules..."
	@echo "📝 Note: Individual lib tests have been consolidated into core testing"
	@$(MAKE) test-core
	@echo "✅ All extended unit tests completed successfully!"

# BATS testing framework integration
test-bats:
	@echo "🧪 Running all BATS shell script tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/; \
	else \
		echo "❌ BATS not found. Installing via Nix..."; \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/; \
	fi

test-bats-platform:
	@echo "🧪 Running BATS platform detection tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/test_platform_detection.bats; \
	else \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/test_platform_detection.bats; \
	fi

test-bats-build:
	@echo "🧪 Running BATS build system tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/test_build_system.bats; \
	else \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/test_build_system.bats; \
	fi

test-bats-claude:
	@echo "🧪 Running BATS Claude activation tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/test_claude_activation.bats; \
	else \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/test_claude_activation.bats; \
	fi

test-bats-user-resolution:
	@echo "🧪 Running BATS user resolution tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/test_lib_user_resolution.bats; \
	else \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/test_lib_user_resolution.bats; \
	fi

test-bats-error-system:
	@echo "🧪 Running BATS error system tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/test_lib_error_system.bats; \
	else \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/test_lib_error_system.bats; \
	fi

# BATS test categories
test-bats-lib:
	@echo "🧪 Running all BATS library tests..."
	@$(MAKE) test-bats-user-resolution
	@$(MAKE) test-bats-error-system

test-bats-system:
	@echo "🧪 Running all BATS system tests..."
	@$(MAKE) test-bats-platform
	@$(MAKE) test-bats-build

test-bats-integration:
	@echo "🧪 Running BATS integration tests..."
	@$(MAKE) test-bats-claude

# BATS with TAP reporting
test-bats-report:
	@echo "📊 Running BATS tests with TAP reporting..."
	@./scripts/bats-tap-reporter.sh ./test-reports

test-bats-report-ci:
	@echo "🤖 Running BATS tests for CI with TAP output..."
	@./scripts/bats-tap-reporter.sh ./test-reports/ci

# Comprehensive test suite
test-comprehensive:
	@echo "🔬 Running comprehensive test suite..."
	@$(MAKE) test-core
	@$(MAKE) test-bats-all
	@echo "✅ All tests completed successfully"

# Fast parallel testing (2-3 seconds total)
test-quick:
	@echo "🚀 Running parallel quick tests..."
	@./scripts/quick-test.sh

# Performance monitoring and regression detection
test-monitor:
	@echo "📊 Running performance monitoring..."
	@./tests/performance/test-performance-monitor.sh

test-monitor-full:
	@echo "📊 Running full performance monitoring (including heavy tests)..."
	@./tests/performance/test-performance-monitor.sh --full

# Advanced performance testing and optimization
test-benchmark:
	@echo "🏁 Running comprehensive performance benchmarks..."
	@$(NIX) run .#test-benchmark

test-memory-profile:
	@echo "🔬 Running memory usage analysis..."
	@$(NIX) run .#memory-profiler

test-optimize:
	@echo "⚡ Running performance optimization controller..."
	@$(NIX) run .#optimization-controller

test-report:
	@echo "📊 Generating comprehensive performance report..."
	@$(NIX) run .#performance-reporter


# Build function
define build-systems
	@echo "🔨 Building $(1) with USER=$(USER)..."
	@for system in $(3); do \
		if [ "$(2)" = "darwin" ]; then \
			export USER=$(USER); $(NIX) build --impure --no-link $(4) ".#darwinConfigurations.$$system.system" $(ARGS) || exit 1; \
		elif [ "$(2)" = "nixos" ]; then \
			export USER=$(USER); $(NIX) build --impure --no-link $(4) ".#nixosConfigurations.$$system.config.system.build.toplevel" $(ARGS) || exit 1; \
		fi; \
	done
endef

build-linux: check-user
	$(call build-systems,Linux configurations,nixos,x86_64-linux aarch64-linux,)

build-darwin: check-user
	$(call build-systems,Darwin configurations,darwin,x86_64-darwin aarch64-darwin,)

build: check-user
	@if [ "$(CURRENT_PLATFORM)" = "darwin" ]; then \
		$(MAKE) build-darwin; \
	elif [ "$(CURRENT_PLATFORM)" = "nixos" ]; then \
		$(MAKE) build-linux; \
	else \
		echo "❌ Unsupported platform: $(CURRENT_PLATFORM)"; \
		exit 1; \
	fi
	@echo "✅ Platform-specific build completed successfully with USER=$(USER)"

platform-info:
	@echo "🖥️  Platform Information:"
	@echo "  Current System: $(CURRENT_SYSTEM)"
	@echo "  Platform: $(CURRENT_PLATFORM)"
	@echo "  Architecture: $(CURRENT_ARCH)"
	@echo "  Nix System: $$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')"
	@echo ""
	@echo "🎯 Supported Systems:"
	@$(NIX) eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).supportedSystems' | tr -d '[]"' | tr ' ' '\n' | sed 's/^/  /'

build-current: check-user
	@echo "⚡ Building current platform only: $(CURRENT_SYSTEM) with USER=$(USER)..."
	@start_time=$$(date +%s)
	$(call build-systems,current platform,$(CURRENT_PLATFORM),$(CURRENT_SYSTEM),)
	@end_time=$$(date +%s)
	@duration=$$((end_time - start_time))
	@echo "✅ Current platform build completed in $${duration}s with USER=$(USER)"

build-fast: check-user
	@echo "⚡⚡ Fast build with optimizations for $(CURRENT_SYSTEM)..."
	@start_time=$$(date +%s)
	$(call build-systems,optimized current platform,$(CURRENT_PLATFORM),$(CURRENT_SYSTEM),--max-jobs auto)
	@end_time=$$(date +%s)
	@duration=$$((end_time - start_time))
	@echo "✅ Fast build completed in $${duration}s with optimizations"

build-switch: check-user
	@echo "🚀 Building and switching current platform: $(CURRENT_SYSTEM) with USER=$(USER)..."
	@start_time=$$(date +%s); \
	OS=$$(uname -s); \
	TARGET=$${HOST:-$(CURRENT_SYSTEM)}; \
	echo "🎯 Target system: $${TARGET}"; \
	if [ "$${OS}" = "Darwin" ]; then \
		echo "🔨 Building Darwin configuration..."; \
		export USER=$(USER); $(NIX) build --impure .#darwinConfigurations.$${TARGET}.system $(ARGS) || { echo "❌ Build failed!"; exit 1; }; \
		if [ ! -L "./result" ]; then echo "❌ Build result not found!"; exit 1; fi; \
		echo "🔄 Switching to new configuration..."; \
		sudo -E env USER=$(USER) ./result/sw/bin/darwin-rebuild switch --impure --flake .#$${TARGET} $(ARGS) 2>/dev/null || \
		{ echo "⚠️  Backup conflicts detected, retrying with backup override..."; \
		  export USER=$(USER); nix run home-manager/release-24.05 -- switch --flake . -b backup --impure; }; \
		unlink ./result; \
	else \
		echo "🔨 Building and switching NixOS configuration..."; \
		sudo -E USER=$(USER) SSH_AUTH_SOCK=$$SSH_AUTH_SOCK /run/current-system/sw/bin/nixos-rebuild switch --impure --flake .#$${TARGET} $(ARGS); \
	fi; \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	echo "✅ Build and switch completed in $${duration}s with USER=$(USER)"

# Build-switch dry-run for CI testing (no actual switch)
build-switch-dry: check-user
	@echo "🧪 Testing build-switch (dry-run for CI): $(CURRENT_SYSTEM) with USER=$(USER)..."
	@start_time=$$(date +%s); \
	OS=$$(uname -s); \
	TARGET=$${HOST:-$(CURRENT_SYSTEM)}; \
	echo "🎯 Target system: $${TARGET}"; \
	if [ "$${OS}" = "Darwin" ]; then \
		echo "🔨 Building Darwin configuration..."; \
		export USER=$(USER); $(NIX) build --impure .#darwinConfigurations.$${TARGET}.system $(ARGS) || { echo "❌ Build failed!"; exit 1; }; \
		if [ ! -L "./result" ]; then echo "❌ Build result not found!"; exit 1; fi; \
		echo "✅ Build successful (skipping switch in dry-run mode)"; \
		unlink ./result; \
	else \
		echo "🔨 Building NixOS configuration..."; \
		export USER=$(USER); $(NIX) build --impure .#nixosConfigurations.$${TARGET}.config.system.build.toplevel $(ARGS) || { echo "❌ Build failed!"; exit 1; }; \
		echo "✅ Build successful (skipping switch in dry-run mode)"; \
		if [ -L "./result" ]; then unlink ./result; fi; \
	fi; \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	echo "✅ Build-switch dry-run completed in $${duration}s with USER=$(USER)"

switch: check-user
	@echo "🔄 Switching system configuration with USER=$(USER)..."
	@OS=$$(uname -s); \
	TARGET=$${HOST:-$(CURRENT_SYSTEM)}; \
	echo "🎯 Target system: $${TARGET}"; \
	if [ "$${OS}" = "Darwin" ]; then \
		export USER=$(USER); nix --extra-experimental-features 'nix-command flakes' build --impure .#darwinConfigurations.$${TARGET}.system $(ARGS) || { echo "❌ Build failed!"; exit 1; }; \
		if [ ! -L "./result" ]; then echo "❌ Build result not found!"; exit 1; fi; \
		sudo -E env USER=$(USER) ./result/sw/bin/darwin-rebuild switch --impure --flake .#$${TARGET} $(ARGS) || { echo "❌ Switch failed!"; exit 1; }; \
		unlink ./result; \
	else \
		sudo -E USER=$(USER) SSH_AUTH_SOCK=$$SSH_AUTH_SOCK /run/current-system/sw/bin/nixos-rebuild switch --impure --flake .#$${TARGET} $(ARGS); \
	fi; \
	echo "✅ System switch completed successfully!"

# Simple apply for built configuration
apply:
	@if [ ! -L "./result" ]; then \
		echo "❌ No build found. Run 'make build' first."; \
		exit 1; \
	fi
	@echo "🔧 Applying built configuration..."
	@./apply.sh

# Build and switch (works on any computer)
deploy:
	@echo "🚀 Deploying configuration..."
	@./deploy.sh

# Claude Code MCP setup
setup-mcp: check-user
	@echo "🤖 Setting up Claude Code MCP servers..."
	@./scripts/setup-claude-mcp --main

.PHONY: help check-user lint lint-format lint-autofix lint-install-autofix smoke test test-format test-quick test-core test-unit test-contract test-coverage test-unit-coverage test-contract-coverage test-workflow test-perf test-list test-unit-extended test-bats test-bats-lib test-bats-system test-bats-integration test-bats-platform test-bats-build test-bats-claude test-bats-user-resolution test-bats-error-system test-bats-report test-bats-report-ci build build-linux build-darwin build-current build-fast build-switch switch apply deploy platform-info setup-mcp format format-check format-dry-run format-setup format-quick format-all format-nix format-shell format-yaml format-json format-markdown
