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
	@echo "📋 Dotfiles Management (USER: $(USER))"
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
	@echo "🔨 Build & Deploy (Nix Apps):"
	@echo "  build       - Build current platform"
	@echo "  build-switch-dry - Dry run build (no changes applied)"
	@echo "  build-switch - Build system configuration"
	@echo "  switch-user - Apply user configuration only (faster)"
	@echo "  switch      - Build + apply system config (requires sudo)"
	@echo ""
	@echo "💡 Common Workflows:"
	@echo "  make lint-quick && make test-quick  # Before commit"
	@echo "  make format && make test            # Before PR"
	@echo "  make smoke && make switch           # Update system safely"
	@echo "  make platform-info                  # Check system details"
	@echo ""
	@echo "🚀 Direct Nix Commands (Alternative):"
	@echo "  nix run .#format    # Auto-format"
	@echo "  nix run .#build     # Build configuration"
	@echo "  nix run .#test      # Run tests"
	@echo "  nix run .#smoke     # Quick validation"

# Code Quality (Nix Apps)
format:
	@echo "🎨 Auto-formatting all files..."
	@$(NIX) run .#format

lint:
	@echo "🔍 Running lint checks..."
	@$(NIX) run .#lint

lint-quick:
	@echo "⚡ Quick lint (format + validation)..."
	@$(NIX) run .#lint-quick

# Testing (Nix Apps)
test:
	@echo "🧪 Running core tests..."
	@$(NIX) run .#test

test-quick:
	@echo "⚡ Quick validation (2-3s)..."
	@$(NIX) run .#test-quick

test-all:
	@echo "🔬 Running comprehensive test suite..."
	@$(NIX) run .#test-all

smoke:
	@echo "💨 Quick smoke test (~30 seconds)..."
	@$(NIX) run .#smoke

# System Info (Nix Apps)
platform-info:
	@echo "💻 Platform Information:"
	@$(NIX) run .#platform-info

# Build & Deploy (Nix Apps)
build:
	@echo "🔨 Building current platform..."
	@$(NIX) run .#build

build-switch-dry:
	@echo "🔍 Dry run: Building system configuration..."
	@$(NIX) run .#build-switch-dry

build-switch:
	@echo "🚀 Building system configuration..."
	@$(NIX) run .#build-switch

build-current: build
	@echo "📝 build-current is an alias for build target"

switch-user:
	@echo "🏠 Switching user configuration (Home Manager)..."
	@$(NIX) run .#switch-user

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

.PHONY: help check-user format lint lint-quick test test-quick test-all smoke platform-info build-switch-dry build build-current build-switch switch switch-user
