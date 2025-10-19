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
	@echo ""
	@echo "🔨 Build & Deploy:"
	@echo "  build       - Build current platform"
	@echo "  switch      - Build + apply system config"
	@echo "  switch-user - Apply user config only (faster)"
	@echo ""
	@echo "💡 Common Workflows:"
	@echo "  make lint-quick && make test-quick  # Before commit"
	@echo "  make format && make test            # Before PR"
	@echo "  make switch                         # Update system"

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
	@echo "✅ All tests passed"


# Build & Deploy
build: check-user
	@echo "🔨 Building $(CURRENT_SYSTEM)..."
	@OS=$$(uname -s); \
	if [ "$${OS}" = "Darwin" ]; then \
		export USER=$(USER); $(NIX) build --impure --fallback --keep-going --no-link --quiet .#darwinConfigurations.$(CURRENT_SYSTEM).system $(ARGS); \
	else \
		export USER=$(USER); $(NIX) build --impure --fallback --keep-going --no-link --quiet .#nixosConfigurations.$(CURRENT_SYSTEM).config.system.build.toplevel $(ARGS); \
	fi

switch: check-user
	@echo "🚀 Switching system configuration..."
	@OS=$$(uname -s); \
	TARGET=$${HOST:-$(CURRENT_SYSTEM)}; \
	if [ "$${OS}" = "Darwin" ]; then \
		export USER=$(USER); $(NIX) build --impure --quiet .#darwinConfigurations.$${TARGET}.system $(ARGS) || exit 1; \
		sudo -E env USER=$(USER) ./result/sw/bin/darwin-rebuild switch --impure --flake .#$${TARGET} $(ARGS) || exit 1; \
		rm -f ./result; \
	else \
		sudo -E USER=$(USER) SSH_AUTH_SOCK=$$SSH_AUTH_SOCK nixos-rebuild switch --impure --flake .#$${TARGET} $(ARGS); \
	fi

switch-user: check-user
	@echo "🏠 Switching user configuration (Home Manager)..."
	@home-manager switch --flake ".#$(USER)" -b backup --impure $(ARGS)

.PHONY: help check-user format lint lint-quick test test-quick test-all build switch switch-user
