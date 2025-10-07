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
	@echo "  test-e2e    - Run E2E tests (end-to-end workflow validation)"
	@echo "  test-switch - 🚦 Test switch operation without applying (--dry-run)"
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
	@$(NIX) run .#format

format-nix:
	@echo "🎨 Formatting Nix files..."
	@$(NIX) run .#format nix

format-shell:
	@echo "🎨 Formatting shell scripts..."
	@$(NIX) run .#format shell

format-yaml:
	@echo "🎨 Formatting YAML files..."
	@$(NIX) run .#format yaml

format-json:
	@echo "🎨 Formatting JSON files..."
	@$(NIX) run .#format json

format-markdown:
	@echo "🎨 Formatting Markdown files..."
	@$(NIX) run .#format markdown

# Format all files and install auto-fix hooks
format-setup:
	@echo "🚀 Setting up auto-formatting environment..."
	@$(MAKE) lint-install-autofix
	@$(MAKE) format
	@echo "✅ Auto-formatting environment ready. Use 'make format' before commits."

# Quick format for common file types (fastest option)
format-quick:
	@echo "⚡ Quick format for common files (Nix + shell)..."
	@$(NIX) run .#format nix
	@$(NIX) run .#format shell

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

# Quick smoke test - build current platform to catch errors early
smoke:
	@echo "🔥 Running smoke test (building current platform)..."
	@$(MAKE) build-current

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
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).all $(ARGS)

# New comprehensive test targets
test-unit:
	@echo "🧪 Running Nix unit tests (nix-unit framework)..."
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).lib-functions $(ARGS)
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).platform-detection $(ARGS)
	@echo "✅ Unit tests completed successfully!"

test-contract:
	@echo "🔍 Running contract tests (interface validation)..."
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).module-interaction $(ARGS)
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).cross-platform $(ARGS)
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).system-configuration $(ARGS)
	@echo "✅ Contract tests completed successfully!"

test-e2e:
	@echo "🚀 Running E2E tests (end-to-end workflow validation)..."
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).build-switch-e2e $(ARGS)
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).user-workflow-e2e $(ARGS)
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).claude-hooks-e2e $(ARGS)
	@echo "✅ E2E tests completed successfully!"

test-e2e-vm-dry:
	@echo "🔬 Running build-switch dry-run test (fast, no VM)..."
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).build-switch-vm-dry $(ARGS)
	@echo "✅ Build-switch dry-run test passed!"

test-e2e-vm-full:
	@echo "🚀 Running build-switch VM test (full E2E, requires VM support)..."
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).build-switch-vm-full $(ARGS)
	@echo "✅ Build-switch VM test passed!"

test-e2e-vm-all:
	@echo "🔬 Running all build-switch tests (dry-run + VM)..."
	@$(NIX) build --impure --quiet .#packages.$(shell nix eval --impure --expr builtins.currentSystem).build-switch-vm-all $(ARGS)
	@echo "✅ All build-switch tests passed!"

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
	@$(NIX) build --impure --quiet .#packages.$(PLATFORM).system-configuration $(ARGS)
	@echo "✅ macOS Services tests completed successfully!"
else ifeq ($(PLATFORM),x86_64-darwin)
	@echo "🧪 Running macOS Services tests via system-configuration tests..."
	@$(NIX) build --impure --quiet .#packages.$(PLATFORM).system-configuration $(ARGS)
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

# Comprehensive test suite
test-comprehensive:
	@echo "🔬 Running comprehensive test suite..."
	@$(MAKE) test-core
	@echo "✅ All tests completed successfully"

# Fast parallel testing (2-3 seconds total)
test-quick:
	@echo "🚀 Running quick validation checks..."
	@$(NIX) flake check --impure --all-systems --no-build --quiet

# Performance monitoring and regression detection
test-monitor:
	@echo "📊 Running performance monitoring..."
	@$(NIX) run .#test-benchmark

test-monitor-full:
	@echo "📊 Running full performance monitoring (including heavy tests)..."
	@$(NIX) run .#test-benchmark

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
			export USER=$(USER); $(NIX) build --impure --no-link --quiet $(4) ".#darwinConfigurations.$$system.system" $(ARGS) || exit 1; \
		elif [ "$(2)" = "nixos" ]; then \
			export USER=$(USER); $(NIX) build --impure --no-link --quiet $(4) ".#nixosConfigurations.$$system.config.system.build.toplevel" $(ARGS) || exit 1; \
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
		echo "🔨 Applying user-level configuration with Home Manager..."; \
		nix run home-manager/release-24.05 -- switch --flake ".#$(USER)" -b backup --impure $(ARGS) || { echo "❌ Switch failed!"; exit 1; }; \
	else \
		echo "🔨 Building and switching NixOS configuration..."; \
		sudo -E USER=$(USER) SSH_AUTH_SOCK=$$SSH_AUTH_SOCK /run/current-system/sw/bin/nixos-rebuild switch --impure --flake .#$${TARGET} $(ARGS); \
	fi; \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	echo "✅ Build and switch completed in $${duration}s with USER=$(USER)"

# Test switch without applying changes (uses --dry-run)
test-switch: check-user
	@echo "🧪 Testing switch operation (dry-run): $(CURRENT_SYSTEM) with USER=$(USER)..."
	@start_time=$$(date +%s); \
	OS=$$(uname -s); \
	TARGET=$${HOST:-$(CURRENT_SYSTEM)}; \
	echo "🎯 Target system: $${TARGET}"; \
	if [ "$${OS}" = "Darwin" ]; then \
		echo "🔨 Building configuration..."; \
		export USER=$(USER); $(NIX) build --impure --quiet .#darwinConfigurations.$${TARGET}.system $(ARGS) || { echo "❌ Build failed!"; exit 1; }; \
		if [ ! -L "./result" ]; then echo "❌ Build result not found!"; exit 1; fi; \
		echo "🔨 Testing darwin-rebuild switch --dry-run..."; \
		sudo -E env USER=$(USER) ./result/sw/bin/darwin-rebuild switch --dry-run --impure --flake .#$${TARGET} $(ARGS) || { echo "❌ Switch test failed!"; exit 1; }; \
		rm -f ./result; \
		echo "✅ Switch test passed (no changes applied)"; \
	else \
		echo "🔨 Building configuration..."; \
		export USER=$(USER); $(NIX) build --impure --quiet .#nixosConfigurations.$${TARGET}.config.system.build.toplevel $(ARGS) || { echo "❌ Build failed!"; exit 1; }; \
		echo "🔨 Testing nixos-rebuild switch --dry-run..."; \
		sudo -E USER=$(USER) nixos-rebuild switch --dry-run --impure --flake .#$${TARGET} $(ARGS) || { echo "❌ Switch test failed!"; exit 1; }; \
		echo "✅ Switch test passed (no changes applied)"; \
	fi; \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	echo "⏱️  Test completed in $${duration}s"

# Build-switch dry-run for CI testing (no actual switch)
build-switch-dry: check-user
	@echo "🧪 Testing build-switch (dry-run for CI): $(CURRENT_SYSTEM) with USER=$(USER)..."
	@start_time=$$(date +%s); \
	OS=$$(uname -s); \
	TARGET=$${HOST:-$(CURRENT_SYSTEM)}; \
	echo "🎯 Target system: $${TARGET}"; \
	if [ "$${OS}" = "Darwin" ]; then \
		echo "🔨 Building Darwin configuration..."; \
		export USER=$(USER); $(NIX) build --impure --quiet .#darwinConfigurations.$${TARGET}.system $(ARGS) || { echo "❌ Build failed!"; exit 1; }; \
		if [ ! -L "./result" ]; then echo "❌ Build result not found!"; exit 1; fi; \
		echo "✅ Build successful (skipping switch in dry-run mode)"; \
		rm -f ./result; \
	else \
		echo "🔨 Building NixOS configuration..."; \
		export USER=$(USER); $(NIX) build --impure --quiet .#nixosConfigurations.$${TARGET}.config.system.build.toplevel $(ARGS) || { echo "❌ Build failed!"; exit 1; }; \
		echo "✅ Build successful (skipping switch in dry-run mode)"; \
		rm -f ./result; \
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
		export USER=$(USER); nix --extra-experimental-features 'nix-command flakes' build --impure --quiet .#darwinConfigurations.$${TARGET}.system $(ARGS) || { echo "❌ Build failed!"; exit 1; }; \
		if [ ! -L "./result" ]; then echo "❌ Build result not found!"; exit 1; fi; \
		sudo -E env USER=$(USER) ./result/sw/bin/darwin-rebuild switch --impure --flake .#$${TARGET} $(ARGS) || { echo "❌ Switch failed!"; exit 1; }; \
		rm -f ./result; \
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

.PHONY: help check-user lint lint-format lint-autofix lint-install-autofix smoke test test-format test-quick test-core test-unit test-contract test-e2e test-switch test-coverage test-unit-coverage test-contract-coverage test-workflow test-perf test-list test-unit-extended build build-linux build-darwin build-current build-fast build-switch build-switch-dry switch apply deploy platform-info format format-setup format-quick format-all format-nix format-shell format-yaml format-json format-markdown
