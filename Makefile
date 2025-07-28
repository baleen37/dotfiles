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
	@echo "🧪 Testing (Simplified):"
	@echo "  test        - Run all tests"
	@echo "  test-core   - Run core tests (fast, essential)"
	@echo "  test-workflow - Run workflow tests (end-to-end)"
	@echo "  test-perf   - Run performance tests"
	@echo "  test-list   - List available test categories"
	@echo ""
	@echo "🔨 Building & Deployment:"
	@echo "  build       - Build all Darwin and NixOS configurations"
	@echo "  build-current - Build only current platform (faster)"
	@echo "  build-fast  - Fast build with optimizations"
	@echo "  apply       - Apply already built configuration"
	@echo "  switch      - Build + apply in one step (requires sudo)"
	@echo "  deploy      - Build+switch (works on any computer)"
	@echo ""
	@echo "💡 Tips:"
	@echo "  - USER is automatically detected, but you can override: USER=myuser make build"
	@echo "  - Use ARGS for additional nix flags: make build ARGS='--verbose'"
	@echo "  - Specify target system: make switch HOST=aarch64-darwin"

lint:
	pre-commit run --all-files

ifdef SYSTEM
smoke:
	$(NIX) flake check --impure --system $(SYSTEM) --no-build $(ARGS)
else
smoke:
	$(NIX) flake check --impure --all-systems --no-build $(ARGS)
endif

# Simplified test targets
test:
	@$(NIX) run --impure .#test $(ARGS)

test-core:
	@$(NIX) run --impure .#test-core $(ARGS)

test-workflow:
	@$(NIX) run --impure .#test-workflow $(ARGS)

test-perf:
	@$(NIX) run --impure .#test-perf $(ARGS)

test-list:
	@$(NIX) run --impure .#test-list $(ARGS)

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

build: check-user build-linux build-darwin
	@echo "✅ All builds completed successfully with USER=$(USER)"

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
	@start_time=$$(date +%s); \
	OPTS=$$($(NIX) eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).utils.getOptimizedBuildConfig (import ./lib/platform-system.nix { system = builtins.currentSystem; }).platform).nixBuildOptions' | tr -d '[]"' | tr ',' ' '); \
	$(call build-systems,optimized current platform,$(CURRENT_PLATFORM),$(CURRENT_SYSTEM),$$OPTS); \
	end_time=$$(date +%s); \
	duration=$$((end_time - start_time)); \
	@echo "✅ Fast build completed in $${duration}s with optimizations"

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

.PHONY: help check-user lint smoke test test-core test-workflow test-perf test-list build build-linux build-darwin build-current build-fast switch apply deploy platform-info
