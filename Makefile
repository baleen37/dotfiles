.DEFAULT_GOAL := help

# Auto-detect USER if not set
USER ?= $(shell whoami)
NIX := nix --extra-experimental-features 'nix-command flakes'
CURRENT_SYSTEM := $(shell $(NIX) eval --impure --expr 'builtins.currentSystem' | tr -d '"')
HOSTNAME := $(shell hostname -s 2>/dev/null || hostname | cut -d. -f1)

check-user:
	@if [ -z "$$USER" ]; then \
		echo "⚠️  WARNING: USER was auto-detected as $(USER). For best results, run: export USER=\$$(whoami)"; \
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
	@echo "  build-switch - Build system (same as switch)"
	@echo "  switch      - Build + apply system config"
	@echo ""
	@echo "💡 Common Workflows:"
	@echo "  make lint-quick && make test-quick  # Before commit"
	@echo "  make format && make test            # Before PR"
	@echo "  make switch                         # Update system"

# Code Quality
format:
	@echo "🎨 Auto-formatting all files..."
	@find . -name "*.nix" -not -path "*/.*" -not -path "*/result/*" -type f -exec nix fmt -- {} +

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
	@$(NIX) build --impure --quiet .#checks.$(CURRENT_SYSTEM).smoke $(ARGS)

test-quick:
	@echo "⚡ Quick validation (2-3s)..."
	@$(NIX) flake check --impure --all-systems --no-build --quiet

test-all:
	@echo "🔬 Running comprehensive test suite..."
	@$(NIX) build --impure --quiet .#checks.$(CURRENT_SYSTEM).smoke $(ARGS)
	@$(NIX) build --impure --quiet .#checks.$(CURRENT_SYSTEM).unit-mksystem $(ARGS)
	@$(NIX) build --impure --quiet .#checks.$(CURRENT_SYSTEM).unit-git $(ARGS)
	@$(NIX) build --impure --quiet .#checks.$(CURRENT_SYSTEM).unit-claude $(ARGS)
	@echo "✅ All tests passed"


# Build & Deploy
build: check-user
	@echo "🔨 Building $(CURRENT_SYSTEM)..."
	@OS=$$(uname -s); \
	TARGET=$${HOST:-macbook-pro}; \
	if [ "$${OS}" = "Darwin" ]; then \
		export USER=$(USER); $(NIX) build --impure --fallback --keep-going --no-link --quiet .#darwinConfigurations.$${TARGET}.system $(ARGS) || exit 1; \
	else \
		echo "❌ ERROR: Only Darwin (macOS) is supported. NixOS configurations not defined."; \
		exit 1; \
	fi

build-switch: check-user
	@echo "🚀 Building system configuration..."
	@OS=$$(uname -s); \
	TARGET=$${HOST:-macbook-pro}; \
	if [ "$${OS}" = "Darwin" ]; then \
		export USER=$(USER); $(NIX) build --impure --quiet .#darwinConfigurations.$${TARGET}.system $(ARGS) || exit 1; \
	else \
		echo "❌ ERROR: Only Darwin (macOS) is supported. NixOS configurations not defined."; \
		exit 1; \
	fi

switch: check-user
	@echo "🚀 Switching system configuration..."
	@OS=$$(uname -s); \
	TARGET=$${HOST:-macbook-pro}; \
	if [ "$${OS}" = "Darwin" ]; then \
		export USER=$(USER); $(NIX) build --impure --quiet .#darwinConfigurations.$${TARGET}.system $(ARGS) || exit 1; \
		sudo -E env USER=$(USER) ./result/sw/bin/darwin-rebuild switch --impure --flake .#$${TARGET} $(ARGS) || exit 1; \
		rm -f ./result; \
	else \
		echo "❌ ERROR: Only Darwin (macOS) is supported. NixOS configurations not defined."; \
		exit 1; \
	fi

.PHONY: help check-user format lint lint-quick test test-quick test-all build build-switch switch
