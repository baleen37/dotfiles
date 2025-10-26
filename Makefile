.DEFAULT_GOAL := help

# Auto-detect USER if not set
USER ?= $(shell whoami)
NIX := nix --extra-experimental-features 'nix-command flakes'
CURRENT_SYSTEM := $(shell $(NIX) eval --impure --expr 'builtins.currentSystem' | tr -d '"')

check-user:
	@if [ -z "$(USER)" ]; then \
		echo "❌ ERROR: USER variable is not set. Please run: export USER=\$$(whoami)"; \
		exit 1; \
	fi

help:
	@echo "📋 Dotfiles Management (USER: $(USER), System: $(CURRENT_SYSTEM))"
	@echo ""
	@echo "🎨 Code Quality:"
	@echo "  format      - Auto-format all files"
	@echo "  lint        - Run all lint checks"
	@echo "  lint-quick  - Fast format + basic validation"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  test        - Run core tests"
	@echo "  test-quick  - Fast validation (2-3s)"
	@echo "  test-all    - Comprehensive test suite"
	@echo "  smoke       - Quick smoke test (~30 seconds)"
	@echo ""
	@echo "💻 System Info:"
	@echo "  platform-info - Show platform and system information"
	@echo ""
	@echo "🔨 Build & Deploy:"
	@echo "  build       - Build current platform"
	@echo "  build-current - Build current platform (alias)"
	@echo "  build-switch - Build system (same as switch)"
	@echo "  build-switch-dry - Dry run build (no changes applied)"
	@echo "  switch      - Build + apply system config"
	@echo "  switch-user - Apply user config only (faster)"
	@echo ""
	@echo "💡 Common Workflows:"
	@echo "  make lint-quick && make test-quick  # Before commit"
	@echo "  make format && make test            # Before PR"
	@echo "  make smoke && make switch           # Update system safely"
	@echo "  make platform-info                  # Check system details"

# Code Quality
format:
	@echo "🎨 Auto-formatting all files..."
	@$(NIX) run .#format

lint:
	@echo "🔍 Running lint checks..."
	@statix check
	@deadnix --fail
	@pre-commit run --all-files

lint-quick:
	@echo "⚡ Quick lint (format + validation)..."
	@$(MAKE) format
	@$(NIX) flake check --no-build --quiet

# Testing
test:
	@echo "🧪 Running core tests..."
	@$(NIX) build --impure --quiet .#packages.$(CURRENT_SYSTEM).all $(ARGS)

test-quick:
	@echo "⚡ Quick validation (2-3s)..."
	@$(NIX) flake check --impure --all-systems --no-build --quiet

test-all:
	@echo "🔬 Running comprehensive test suite..."
	@$(NIX) build --impure --quiet .#packages.$(CURRENT_SYSTEM).lib-functions $(ARGS)
	@$(NIX) build --impure --quiet .#packages.$(CURRENT_SYSTEM).module-interaction $(ARGS)
	@$(NIX) build --impure --quiet .#packages.$(CURRENT_SYSTEM).build-switch-e2e $(ARGS)
	@$(NIX) build --impure --quiet .#packages.$(CURRENT_SYSTEM).switch-platform-execution-e2e $(ARGS)
	@echo "✅ All tests passed"

smoke:
	@echo "💨 Quick smoke test (~30 seconds)..."
	@$(MAKE) check-user
	@$(NIX) flake check --impure --no-build --quiet
	@echo "✅ Smoke test passed - system is ready"

platform-info:
	@echo "💻 Platform Information:"
	@echo "  User: $(USER)"
	@echo "  System: $(CURRENT_SYSTEM)"
	@echo "  OS: $$(uname -s)"
	@echo "  Architecture: $$(uname -m)"
	@echo "  Nix version: $$($(NIX) --version | head -n1)"
	@echo "  Flake location: $$(pwd)"

build-switch-dry: check-user
	@echo "🔍 Dry run: Building system configuration (no changes applied)..."
	@OS=$$(uname -s); \
	if [ "$${OS}" = "Darwin" ]; then \
		if [ "$(CURRENT_SYSTEM)" = "aarch64-darwin" ]; then \
			echo "🍎 macOS ARM64: Checking baleen-macbook-aarch64 configuration"; \
			export USER=$(USER); $(NIX) eval --impure .#darwinConfigurations.baleen-macbook-aarch64.system $(ARGS); \
		else \
			echo "🍎 macOS x86_64: Checking baleen-macbook-x86_64 configuration"; \
			export USER=$(USER); $(NIX) eval --impure .#darwinConfigurations.baleen-macbook-x86_64.system $(ARGS); \
		fi; \
	else \
		echo "🐧 NixOS: Checking nixos-vm-x86_64 configuration"; \
		export USER=$(USER); $(NIX) eval --impure .#nixosConfigurations.nixos-vm-x86_64.config.system.build.toplevel.outPath $(ARGS); \
	fi; \
	echo "✅ Dry run completed - no changes were applied"


# Build & Deploy
build: check-user
	@echo "🔨 Building $(CURRENT_SYSTEM)..."
	@OS=$$(uname -s); \
	if [ "$${OS}" = "Darwin" ]; then \
		if [ "$(CURRENT_SYSTEM)" = "aarch64-darwin" ]; then \
			export USER=$(USER); $(NIX) build --impure --fallback --keep-going --no-link --quiet .#darwinConfigurations.baleen-macbook-aarch64.system $(ARGS); \
		else \
			export USER=$(USER); $(NIX) build --impure --fallback --keep-going --no-link --quiet .#darwinConfigurations.baleen-macbook-x86_64.system $(ARGS); \
		fi; \
	else \
		echo "ℹ️  NixOS: Running configuration validation (CI-safe)..."; \
		export USER=$(USER); $(NIX) eval --impure .#nixosConfigurations.nixos-vm-x86_64.config.system.build.toplevel.outPath $(ARGS) > /dev/null; \
		echo "✅ NixOS configuration validated successfully"; \
	fi

build-current: build
	@echo "📝 build-current is an alias for build target"

build-switch: check-user
	@echo "🚀 Building system configuration..."
	@OS=$$(uname -s); \
	if [ "$${OS}" = "Darwin" ]; then \
		if [ "$(CURRENT_SYSTEM)" = "aarch64-darwin" ]; then \
			export USER=$(USER); $(NIX) build --impure --quiet .#darwinConfigurations.baleen-macbook-aarch64.system $(ARGS) || exit 1; \
		else \
			export USER=$(USER); $(NIX) build --impure --quiet .#darwinConfigurations.baleen-macbook-x86_64.system $(ARGS) || exit 1; \
		fi; \
	else \
		echo "ℹ️  NixOS: Running build for system configuration..."; \
		export USER=$(USER); $(NIX) build --impure --quiet .#nixosConfigurations.nixos-vm-x86_64.config.system.build.toplevel $(ARGS) || exit 1; \
	fi

switch: check-user
	@echo "🚀 Switching system configuration..."
	@OS=$$(uname -s); \
	if [ "$${OS}" = "Darwin" ]; then \
		if [ "$(CURRENT_SYSTEM)" = "aarch64-darwin" ]; then \
			export USER=$(USER); $(NIX) build --impure --quiet .#darwinConfigurations.baleen-macbook-aarch64.system $(ARGS) || exit 1; \
			sudo -E env USER=$(USER) ./result/sw/bin/darwin-rebuild switch --impure --flake .#baleen-macbook-aarch64 $(ARGS) || exit 1; \
		else \
			export USER=$(USER); $(NIX) build --impure --quiet .#darwinConfigurations.baleen-macbook-x86_64.system $(ARGS) || exit 1; \
			sudo -E env USER=$(USER) ./result/sw/bin/darwin-rebuild switch --impure --flake .#baleen-macbook-x86_64 $(ARGS) || exit 1; \
		fi; \
		rm -f ./result; \
	else \
		if [ -f /etc/nixos/configuration.nix ]; then \
			echo "🐧 NixOS detected: Applying full system configuration..."; \
			sudo -E USER=$(USER) SSH_AUTH_SOCK=$$SSH_AUTH_SOCK nixos-rebuild switch --impure --flake .#nixos-vm-x86_64 $(ARGS); \
		else \
			echo "ℹ️  Ubuntu detected: Applying user configuration only..."; \
			home-manager switch --flake ".#$(USER)" -b backup --impure $(ARGS); \
		fi \
	fi

switch-user: check-user
	@echo "🏠 Switching user configuration (Home Manager)..."
	@home-manager switch --flake ".#$(USER)" -b backup --impure $(ARGS)

.PHONY: help check-user format lint lint-quick test test-quick test-all smoke platform-info build-switch-dry build build-current build-switch switch switch-user
