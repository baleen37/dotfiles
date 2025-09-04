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
	@echo "  smoke       - Run nix flake checks for all systems"
	@echo "  platform-info - Show detailed platform information"
	@echo ""
	@echo "🧪 Testing (Unified Interface):"
	@echo "  test [CATEGORY] [OPTIONS] - 🚀 NEW: Unified test interface"
	@echo "    Categories: all, quick, unit, integration, e2e, performance, smoke"
	@echo "    Options: --format, --parallel, --verbose, --dry-run, etc."
	@echo "    Examples:"
	@echo "      make test                 # Default all tests"
	@echo "      make test-with ARGS='quick --parallel'"
	@echo "      make test-with ARGS='unit --verbose'"
	@echo "      make test-with ARGS='--changed --format json'"
	@echo ""
	@echo "🧪 Testing (Legacy - Deprecated):"
	@echo "  test-quick  - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"quick --parallel\"'"
	@echo "  test-enhanced - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"integration --verbose\"'"
	@echo "  test-enhanced-verbose - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"integration --verbose\"'"
	@echo "  test-monitor - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"performance\"'"
	@echo "  test-monitor-full - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"performance --timeout 600\"'"
	@echo "  test-core   - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"unit\"'"
	@echo "  test-macos-services - 🧪 TDD-verified macOS Services tests (Darwin only)"
	@echo "  test-workflow - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"e2e\"'"
	@echo "  test-perf   - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"performance\"'"
	@echo "  test-list   - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"--help\"'"
	@echo ""
	@echo "🔬 Unit Testing (Legacy - Deprecated):"
	@echo "  test-unit-extended - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"unit --tag extended\"'"
	@echo "  test-lib-user-resolution - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"unit --tag user-resolution\"'"
	@echo "  test-lib-platform-system - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"unit --tag platform-system\"'"
	@echo "  test-lib-error-system - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"unit --tag error-system\"'"
	@echo ""
	@echo "🧪 BATS Testing Framework (Legacy - Deprecated):"
	@echo "  test-bats - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"integration --tag bats\"'"
	@echo "  test-bats-lib - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"integration --tag bats-lib\"'"
	@echo "  test-bats-system - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"integration --tag bats-system\"'"
	@echo "  test-bats-integration - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"integration --tag bats-integration\"'"
	@echo "  test-bats-claude - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"integration --tag claude\"'"
	@echo "  test-bats-user-resolution - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"integration --tag user-resolution\"'"
	@echo "  test-bats-error-system - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"integration --tag error-system\"'"
	@echo "  test-bats-report - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"integration --format tap\"'"
	@echo "  test-bats-report-ci - ⚠️  DEPRECATED: Use 'make test-with ARGS=\"integration --format junit\"'"
	@echo ""
	@echo "🤖 Claude Code MCP:"
	@echo "  setup-mcp   - Install MCP servers for Claude Code"
	@echo ""
	@echo "🔨 Building & Deployment:"
	@echo "  build       - Build all Darwin and NixOS configurations"
	@echo "  build-current - Build only current platform (faster)"
	@echo "  build-fast  - Fast build with optimizations"
	@echo "  build-switch - Build current platform and switch in one step"
	@echo "  apply       - Apply already built configuration"
	@echo "  switch      - Build + apply in one step (requires sudo)"
	@echo "  deploy      - Build+switch (works on any computer)"
	@echo ""
	@echo "💡 Tips:"
	@echo "  - USER is automatically detected, but you can override: USER=myuser make build"
	@echo "  - Use ARGS for additional nix flags: make build ARGS='--verbose'"
	@echo "  - Specify target system: make switch HOST=aarch64-darwin"
	@echo "  - ⚠️  Legacy test commands show deprecation warnings and redirect to new interface"

lint:
	pre-commit run --all-files

ifdef SYSTEM
smoke:
	$(NIX) flake check --impure --system $(SYSTEM) --no-build $(ARGS)
else
smoke:
	$(NIX) flake check --impure --all-systems --no-build $(ARGS)
endif

# === NEW UNIFIED TEST INTERFACE ===
# Primary test target using unified CLI (default: all tests)
test:
	@./tests/lib/unified/test-cli.sh all

# Test with arguments - use ARGS variable
test-with:
	@./tests/lib/unified/test-cli.sh $(ARGS)

# === LEGACY TEST COMMANDS WITH DEPRECATION WARNINGS ===

test-core:
	@echo "⚠️  DEPRECATED: 'test-core' is deprecated. Use 'make test-with ARGS=\"unit\"' instead."
	@echo "ℹ️  Running equivalent command: test unit"
	@./tests/lib/unified/test-cli.sh unit

# macOS Services 관리 및 테스트 (Darwin 전용) - 특별한 케이스로 유지
test-macos-services:
ifeq ($(PLATFORM),aarch64-darwin)
	@echo "🧪 Running TDD-verified macOS Services tests..."
	@./tests/integration/test-macos-services-disabled.sh
else ifeq ($(PLATFORM),x86_64-darwin)
	@echo "🧪 Running TDD-verified macOS Services tests..."
	@./tests/integration/test-macos-services-disabled.sh
else
	@echo "⏭️ Skipping macOS Services tests (not on Darwin platform)"
endif

test-workflow:
	@echo "⚠️  DEPRECATED: 'test-workflow' is deprecated. Use 'make test-with ARGS=\"e2e\"' instead."
	@echo "ℹ️  Running equivalent command: test e2e"
	@./tests/lib/unified/test-cli.sh e2e

test-perf:
	@echo "⚠️  DEPRECATED: 'test-perf' is deprecated. Use 'make test-with ARGS=\"performance\"' instead."
	@echo "ℹ️  Running equivalent command: test performance"
	@./tests/lib/unified/test-cli.sh performance

test-list:
	@echo "⚠️  DEPRECATED: 'test-list' is deprecated. Use 'make test-with ARGS=\"--help\"' instead."
	@echo "ℹ️  Running equivalent command: test --help"
	@./tests/lib/unified/test-cli.sh --help

# New comprehensive unit tests
test-unit-extended:
	@echo "⚠️  DEPRECATED: 'test-unit-extended' is deprecated. Use 'make test-with ARGS=\"unit --tag extended\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Running extended unit tests for lib modules..."
	@$(NIX) build --impure .#checks.$(shell $(NIX) eval --impure --expr 'builtins.currentSystem' | tr -d '"').lib-user-resolution-test -L
	@$(NIX) build --impure .#checks.$(shell $(NIX) eval --impure --expr 'builtins.currentSystem' | tr -d '"').lib-platform-system-test -L
	@$(NIX) build --impure .#checks.$(shell $(NIX) eval --impure --expr 'builtins.currentSystem' | tr -d '"').lib-error-system-test -L
	@echo "✅ All extended unit tests completed successfully!"

# Individual lib tests
test-lib-user-resolution:
	@echo "⚠️  DEPRECATED: 'test-lib-user-resolution' is deprecated. Use 'make test-with ARGS=\"unit --tag user-resolution\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Testing lib/user-resolution.nix..."
	@$(NIX) build --impure .#checks.$(shell $(NIX) eval --impure --expr 'builtins.currentSystem' | tr -d '"').lib-user-resolution-test -L

test-lib-platform-system:
	@echo "⚠️  DEPRECATED: 'test-lib-platform-system' is deprecated. Use 'make test-with ARGS=\"unit --tag platform-system\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Testing lib/platform-system.nix..."
	@$(NIX) build --impure .#checks.$(shell $(NIX) eval --impure --expr 'builtins.currentSystem' | tr -d '"').lib-platform-system-test -L

test-lib-error-system:
	@echo "⚠️  DEPRECATED: 'test-lib-error-system' is deprecated. Use 'make test-with ARGS=\"unit --tag error-system\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Testing lib/error-system.nix..."
	@$(NIX) build --impure .#checks.$(shell $(NIX) eval --impure --expr 'builtins.currentSystem' | tr -d '"').lib-error-system-test -L

# BATS testing framework integration
test-bats:
	@echo "⚠️  DEPRECATED: 'test-bats' is deprecated. Use 'make test-with ARGS=\"integration --tag bats\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Running all BATS shell script tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/; \
	else \
		echo "❌ BATS not found. Installing via Nix..."; \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/; \
	fi

test-bats-platform:
	@echo "⚠️  DEPRECATED: 'test-bats-platform' is deprecated. Use 'make test-with ARGS=\"integration --tag bats-platform\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Running BATS platform detection tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/test_platform_detection.bats; \
	else \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/test_platform_detection.bats; \
	fi

test-bats-build:
	@echo "⚠️  DEPRECATED: 'test-bats-build' is deprecated. Use 'make test-with ARGS=\"integration --tag bats-build\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Running BATS build system tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/test_build_system.bats; \
	else \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/test_build_system.bats; \
	fi

test-bats-claude:
	@echo "⚠️  DEPRECATED: 'test-bats-claude' is deprecated. Use 'make test-with ARGS=\"integration --tag claude\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Running BATS Claude activation tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/test_claude_activation.bats; \
	else \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/test_claude_activation.bats; \
	fi

test-bats-user-resolution:
	@echo "⚠️  DEPRECATED: 'test-bats-user-resolution' is deprecated. Use 'make test-with ARGS=\"integration --tag user-resolution\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Running BATS user resolution tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/test_lib_user_resolution.bats; \
	else \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/test_lib_user_resolution.bats; \
	fi

test-bats-error-system:
	@echo "⚠️  DEPRECATED: 'test-bats-error-system' is deprecated. Use 'make test-with ARGS=\"integration --tag error-system\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Running BATS error system tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/bats/test_lib_error_system.bats; \
	else \
		$(NIX) shell nixpkgs#bats -c bats tests/bats/test_lib_error_system.bats; \
	fi

# BATS test categories
test-bats-lib:
	@echo "⚠️  DEPRECATED: 'test-bats-lib' is deprecated. Use 'make test-with ARGS=\"integration --tag bats-lib\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Running all BATS library tests..."
	@$(MAKE) test-bats-user-resolution
	@$(MAKE) test-bats-error-system

test-bats-system:
	@echo "⚠️  DEPRECATED: 'test-bats-system' is deprecated. Use 'make test-with ARGS=\"integration --tag bats-system\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Running all BATS system tests..."
	@$(MAKE) test-bats-platform
	@$(MAKE) test-bats-build

test-bats-integration:
	@echo "⚠️  DEPRECATED: 'test-bats-integration' is deprecated. Use 'make test-with ARGS=\"integration --tag bats-integration\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🧪 Running BATS integration tests..."
	@$(MAKE) test-bats-claude

# BATS with TAP reporting
test-bats-report:
	@echo "⚠️  DEPRECATED: 'test-bats-report' is deprecated. Use 'make test-with ARGS=\"integration --format tap\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "📊 Running BATS tests with TAP reporting..."
	@./scripts/bats-tap-reporter.sh ./test-reports

test-bats-report-ci:
	@echo "⚠️  DEPRECATED: 'test-bats-report-ci' is deprecated. Use 'make test-with ARGS=\"integration --format junit\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🤖 Running BATS tests for CI with TAP output..."
	@./scripts/bats-tap-reporter.sh ./test-reports/ci

# Comprehensive test suite
test-comprehensive:
	@echo "⚠️  DEPRECATED: 'test-comprehensive' is deprecated. Use 'make test' instead."
	@echo "ℹ️  Running equivalent command: test all"
	@./tests/lib/unified/test-cli.sh all

# Fast parallel testing (2-3 seconds total)
test-quick:
	@echo "⚠️  DEPRECATED: 'test-quick' is deprecated. Use 'make test-with ARGS=\"quick --parallel\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🚀 Running parallel quick tests..."
	@./scripts/quick-test.sh

# Enhanced testing with detailed reporting
test-enhanced:
	@echo "⚠️  DEPRECATED: 'test-enhanced' is deprecated. Use 'make test-with ARGS=\"integration --verbose\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🚀 Running enhanced tests with detailed reporting..."
	@./scripts/enhanced-test.sh --quiet --parallel

test-enhanced-verbose:
	@echo "⚠️  DEPRECATED: 'test-enhanced-verbose' is deprecated. Use 'make test-with ARGS=\"integration --verbose\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "🚀 Running enhanced tests with verbose output..."
	@./scripts/enhanced-test.sh --verbose

# Performance monitoring and regression detection
test-monitor:
	@echo "⚠️  DEPRECATED: 'test-monitor' is deprecated. Use 'make test-with ARGS=\"performance\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "📊 Running performance monitoring..."
	@./tests/performance/test-performance-monitor.sh

test-monitor-full:
	@echo "⚠️  DEPRECATED: 'test-monitor-full' is deprecated. Use 'make test-with ARGS=\"performance --timeout 600\"' instead."
	@echo "ℹ️  For now, running legacy implementation..."
	@echo "📊 Running full performance monitoring (including heavy tests)..."
	@./tests/performance/test-performance-monitor.sh --full


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
		sudo -E env USER=$(USER) ./result/sw/bin/darwin-rebuild switch --impure --flake .#$${TARGET} $(ARGS) || { echo "❌ Switch failed!"; exit 1; }; \
		unlink ./result; \
	else \
		echo "🔨 Building and switching NixOS configuration..."; \
		sudo -E USER=$(USER) SSH_AUTH_SOCK=$$SSH_AUTH_SOCK /run/current-system/sw/bin/nixos-rebuild switch --impure --flake .#$${TARGET} $(ARGS); \
	fi; \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	echo "✅ Build and switch completed in $${duration}s with USER=$(USER)"

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

.PHONY: help check-user lint smoke test test-with test-quick test-core test-workflow test-perf test-list test-unit-extended test-lib-user-resolution test-lib-platform-system test-lib-error-system test-bats test-bats-lib test-bats-system test-bats-integration test-bats-platform test-bats-build test-bats-claude test-bats-user-resolution test-bats-error-system test-bats-report test-bats-report-ci build build-linux build-darwin build-current build-fast build-switch switch apply deploy platform-info setup-mcp
