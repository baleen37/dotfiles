.DEFAULT_GOAL := help

# Auto-detect USER if not set
USER ?= $(shell whoami)
ARCH := $(shell uname -m)
OS := $(shell uname -s | tr A-Z a-z)
NIX := nix --extra-experimental-features 'nix-command flakes'

# Check if USER is properly set
check-user:
	@if [ -z "$(USER)" ]; then \
		echo "❌ ERROR: USER variable is not set. Please run: export USER=\$$(whoami)"; \
		exit 1; \
	fi
	@echo "✅ USER is set to: $(USER)"

help:
	@echo "📋 Available targets (USER auto-detected as: $(USER)):"
	@echo ""
	@echo "🔧 Development:"
	@echo "  lint        - Run pre-commit lint checks"
	@echo "  smoke       - Run nix flake checks for all systems"
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
	@echo "  build       - Build all Darwin and NixOS configurations (with USER=$(USER))"
	@echo "  switch      - Apply configuration to current machine (HOST=<system> optional)"
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

test:
	$(NIX) flake check --impure --no-build

test-unit:
	@echo "Running unit tests..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.basic_functionality_unit" $(ARGS) && echo "✓ Unit tests passed"

test-integration:
	@echo "Running integration tests..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.package_availability_integration" $(ARGS) && echo "✓ Integration tests passed"

test-e2e:
	@echo "Running end-to-end tests..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.system_build_e2e" $(ARGS) && echo "✓ E2E tests passed"

test-perf:
	@echo "Running performance tests..."
	@SYSTEM=$$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"'); \
	$(NIX) build --impure --no-link ".#checks.$$SYSTEM.build_time_perf" $(ARGS) && echo "✓ Performance tests completed"

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
