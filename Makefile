.DEFAULT_GOAL := help

# Auto-detect USER if not set
USER ?= $(shell whoami)
ARCH := $(shell uname -m)
OS := $(shell uname -s | tr A-Z a-z)
NIX := nix --extra-experimental-features 'nix-command flakes'

# Platform detection using our platform-detector
PLATFORM_DETECTOR_BASE := $(NIX) eval --impure --expr 'import ./lib/platform-detector.nix {}'
CURRENT_PLATFORM := $(shell $(NIX) eval --impure --expr '(import ./lib/platform-detector.nix {}).getCurrentPlatform' | tr -d '"')
CURRENT_ARCH := $(shell $(NIX) eval --impure --expr '(import ./lib/platform-detector.nix {}).getCurrentArch' | tr -d '"')
CURRENT_SYSTEM := $(shell $(NIX) eval --impure --expr '(import ./lib/platform-detector.nix {}).getCurrentSystem' | tr -d '"')

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
	@echo "🧪 Testing:"
	@echo "  test        - Run all tests (unit, integration, e2e)"
	@echo "  test-unit   - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-e2e    - Run end-to-end tests only"
	@echo "  test-perf   - Run performance tests only"
	@echo "  test-status - Show test framework status"
	@echo ""
	@echo "🔨 Building & Deployment:"
	@echo "  build       - Build all Darwin and NixOS configurations (8-12min)"
	@echo "  build-current - Build only current platform (1-2min) ⚡"
	@echo "  build-fast  - Fast build with optimizations ⚡⚡"
	@echo "  build-time  - Compare build times"
	@echo "  switch      - Apply configuration to current machine (HOST=<system> optional)"
	@echo ""
	@echo "💡 Tips:"
	@echo "  - USER is automatically detected, but you can override: USER=myuser make build"
	@echo "  - Use ARGS for additional nix flags: make build ARGS='--verbose'"
	@echo "  - Specify target system: make switch HOST=aarch64-darwin"
	@echo "  - Use build-current for faster development iteration ⚡"

lint:
	pre-commit run --all-files

ifdef SYSTEM
smoke:
	$(NIX) flake check --impure --system $(SYSTEM) --no-build $(ARGS)
else
smoke:
	$(NIX) flake check --impure --all-systems --no-build $(ARGS)
endif

test:
	@$(NIX) run --impure .#test $(ARGS)

test-unit:
	@$(NIX) run --impure .#test-unit $(ARGS)

test-integration:
	@$(NIX) run --impure .#test-integration $(ARGS)

test-e2e:
	@$(NIX) run --impure .#test-e2e $(ARGS)

test-perf:
	@$(NIX) run --impure .#test-perf $(ARGS)

test-status:
	@echo "Checking test framework status..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.framework_status" $(ARGS)

build-linux: check-user
	@echo "🔨 Building Linux configurations with USER=$(USER)..."
	@export USER=$(USER); $(NIX) build --impure --no-link ".#nixosConfigurations.x86_64-linux.config.system.build.toplevel" $(ARGS)
	@export USER=$(USER); $(NIX) build --impure --no-link ".#nixosConfigurations.aarch64-linux.config.system.build.toplevel" $(ARGS)

build-darwin: check-user
	@echo "🔨 Building Darwin configurations with USER=$(USER)..."
	@export USER=$(USER); $(NIX) build --impure --no-link ".#darwinConfigurations.x86_64-darwin.system" $(ARGS)
	@export USER=$(USER); $(NIX) build --impure --no-link ".#darwinConfigurations.aarch64-darwin.system" $(ARGS)

build: check-user build-linux build-darwin
	@echo "✅ All builds completed successfully with USER=$(USER)"

# 🚀 New optimized build targets
platform-info:
	@echo "🖥️  Platform Information:"
	@echo "  Current System: $(CURRENT_SYSTEM)"
	@echo "  Platform: $(CURRENT_PLATFORM)"
	@echo "  Architecture: $(CURRENT_ARCH)"
	@echo "  Nix System: $$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')"
	@echo ""
	@echo "🎯 Supported Systems:"
	@$(NIX) eval --impure --expr '(import ./lib/platform-detector.nix {}).getSupportedSystems' | tr -d '[]"' | tr ' ' '\n' | sed 's/^/  /'
	@echo ""
	@echo "🔧 Current Optimizations:"
	@$(NIX) eval --impure --expr 'builtins.toJSON (import ./lib/platform-detector.nix {}).getOptimizations' | tr -d '"'

build-current: check-user
	@echo "⚡ Building current platform only: $(CURRENT_SYSTEM) with USER=$(USER)..."
	@start_time=$$(date +%s); \
	export USER=$(USER); \
	if [ "$(CURRENT_PLATFORM)" = "darwin" ]; then \
		$(NIX) build --impure --no-link ".#darwinConfigurations.$(CURRENT_SYSTEM).system" $(ARGS); \
	else \
		$(NIX) build --impure --no-link ".#nixosConfigurations.$(CURRENT_SYSTEM).config.system.build.toplevel" $(ARGS); \
	fi; \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	echo "✅ Current platform build completed in $${duration}s with USER=$(USER)"

build-fast: check-user
	@echo "⚡⚡ Fast build with optimizations for $(CURRENT_SYSTEM)..."
	@start_time=$$(date +%s); \
	export USER=$(USER); \
	OPTS=$$($(NIX) eval --impure --expr '(import ./lib/platform-detector.nix {}).getOptimizations.extraArgs' | tr -d '[]"' | tr ',' ' '); \
	if [ "$(CURRENT_PLATFORM)" = "darwin" ]; then \
		$(NIX) build --impure --no-link $$OPTS ".#darwinConfigurations.$(CURRENT_SYSTEM).system" $(ARGS); \
	else \
		$(NIX) build --impure --no-link $$OPTS ".#nixosConfigurations.$(CURRENT_SYSTEM).config.system.build.toplevel" $(ARGS); \
	fi; \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	echo "✅ Fast build completed in $${duration}s with optimizations"

build-time: check-user
	@echo "⏱️  Build Time Comparison for $(CURRENT_SYSTEM):"
	@echo ""
	@echo "🐌 Full build (all platforms):"
	@start_time=$$(date +%s); \
	$(MAKE) build >/dev/null 2>&1; \
	end_time=$$(date +%s); \
	full_duration=$$((end_time - start_time)); \
	echo "  Time: $${full_duration}s"
	@echo ""
	@echo "⚡ Current platform build:"
	@start_time=$$(date +%s); \
	$(MAKE) build-current >/dev/null 2>&1; \
	end_time=$$(date +%s); \
	current_duration=$$((end_time - start_time)); \
	echo "  Time: $${current_duration}s"
	@echo ""
	@echo "📊 Performance Summary:"
	@full_time=$$($(MAKE) build 2>&1 | grep "completed in" | tail -1 | grep -o "[0-9]*s" | tr -d 's' || echo "300"); \
	current_time=$$($(MAKE) build-current 2>&1 | grep "completed in" | tail -1 | grep -o "[0-9]*s" | tr -d 's' || echo "60"); \
	if [ "$$current_time" -gt 0 ]; then \
		improvement=$$((100 - (current_time * 100 / full_time))); \
		echo "  Improvement: ~$${improvement}% faster"; \
		echo "  Time saved: ~$$((full_time - current_time))s"; \
	fi

switch: check-user
	@echo "🔄 Switching system configuration with USER=$(USER)..."
	@OS=$$(uname -s); \
	ARCH=$$(uname -m); \
	if [ "$${OS}" = "Darwin" ]; then \
	DEFAULT_SYSTEM="$${ARCH}-darwin"; \
	else \
	DEFAULT_SYSTEM="$${ARCH}-linux"; \
	fi; \
	TARGET=${HOST-$${DEFAULT_SYSTEM}}; \
	echo "🎯 Target system: $${TARGET}"; \
	if [ "$${OS}" = "Darwin" ]; then \
	export USER=$(USER); nix --extra-experimental-features 'nix-command flakes' build --impure .#darwinConfigurations.$${TARGET}.system $(ARGS); \
	sudo -E USER=$(USER) ./result/sw/bin/darwin-rebuild switch --flake .#$${TARGET} $(ARGS); \
	unlink ./result; \
	else \
	sudo -E USER=$(USER) SSH_AUTH_SOCK=$$SSH_AUTH_SOCK /run/current-system/sw/bin/nixos-rebuild switch --impure --flake .#$${TARGET} $(ARGS); \
	fi; \
	echo "✅ System switch completed successfully!"

.PHONY: help check-user lint smoke test test-unit test-integration test-e2e test-perf test-status build build-linux build-darwin switch
