.DEFAULT_GOAL := help

# Auto-detect USER if not set
USER ?= $(shell whoami)
NIX := nix --extra-experimental-features 'nix-command flakes'
CURRENT_SYSTEM := $(shell $(NIX) eval --impure --expr 'builtins.currentSystem' | tr -d '"')
HOSTNAME := $(shell hostname -s 2>/dev/null || hostname | cut -d. -f1)

# Platform-specific build targets (auto-selected)
ifeq ($(CURRENT_SYSTEM),aarch64-darwin)
  BUILD_TARGET := darwinConfigurations.macbook-pro.system
else ifeq ($(CURRENT_SYSTEM),x86_64-linux)
  # Linux: use checks instead of full VM build (VM tests run separately via make test-vm)
  BUILD_TARGET := checks.x86_64-linux.smoke
else ifeq ($(CURRENT_SYSTEM),aarch64-linux)
  # Linux: use checks instead of full VM build (VM tests run separately via make test-vm)
  BUILD_TARGET := checks.aarch64-linux.smoke
else
  BUILD_TARGET :=
endif

# Connectivity info for Linux VM
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= root

# SSH options that are used. These aren't meant to be overridden but are
# reused a lot so we just store them up here.
SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

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
	@echo ""
	@echo "🧪 Testing:"
	@echo "  test             - Run core tests (unit + integration)"
	@echo "  test-e2e         - Run E2E tests (fast VM test, Linux only)"
	@echo "  test-integration - Run integration tests"
	@echo "  test-all         - Comprehensive test suite"
	@echo "  test-vm          - Full VM test (build + boot + E2E validation)"
	@echo ""
	@echo "🔨 Build & Deploy:"
	@echo "  build       - Build current platform"
	@echo "  build-switch - Build system (same as switch)"
	@echo "  switch      - Build + apply system config"
	@echo "  switch-user - Apply user config only (no sudo)"
	@echo ""
	@echo "🖥️  VM Management:"
	@echo "  vm/bootstrap0 - Bootstrap new NixOS VM (initial install)"
	@echo "  vm/bootstrap  - Complete VM setup with dotfiles"
	@echo "  vm/copy      - Copy configurations to VM"
	@echo "  vm/switch    - Apply configuration changes on VM"
	@echo ""
	@echo "💡 Common Workflows:"
	@echo "  make format && make test            # Before commit (automated via pre-commit)"
	@echo "  make switch                         # Update system"
	@echo "  make vm/copy && make vm/switch      # Update VM configuration"

# Code Quality
format:
	@echo "🎨 Auto-formatting all files..."
	@find . -name "*.nix" -not -path "*/.*" -not -path "*/result/*" -type f -exec nix fmt -- {} +

lint:
	@echo "🔍 Linting ($(CURRENT_SYSTEM))..."
	@find . -name "*.nix" -not -path "*/.*" -not -path "*/result/*" -type f -exec nix fmt -- {} +
	@$(NIX) flake check --no-build --quiet

# Testing (simplified with auto-discovery)
test: check-user
	@echo "🧪 Testing $(CURRENT_SYSTEM)..."
	@export USER=$(USER) && $(NIX) flake check --impure $(ARGS)
	@echo "✅ Tests passed"

test-unit:
	@echo "🧪 Running unit tests (auto-discovered)..."
	@$(NIX) eval --impure .#checks.$(CURRENT_SYSTEM) --apply 'x: builtins.length (builtins.filter (n: builtins.match "unit-.*" n != null) (builtins.attrNames x))'
	@echo "unit tests discovered"
	@$(NIX) flake check --impure --no-build $(ARGS)

test-integration:
	@echo "🔗 Running integration tests (auto-discovered)..."
	@$(NIX) eval --impure .#checks.$(CURRENT_SYSTEM) --apply 'x: builtins.length (builtins.filter (n: builtins.match "integration-.*" n != null) (builtins.attrNames x))'
	@echo "integration tests discovered"
	@$(NIX) flake check --impure --no-build $(ARGS)

test-all:
	@echo "🔬 Running comprehensive test suite..."
	@$(MAKE) test
	@$(MAKE) test-integration
	@$(MAKE) test-e2e
	@$(MAKE) test-vm
	@echo "✅ All tests passed"

# Determine Linux target for VM testing based on current Darwin architecture
LINUX_TARGET = $(shell echo "$(CURRENT_SYSTEM)" | sed 's/darwin/linux/')

test-vm:
	@echo "🚀 Full VM test (build + boot + E2E validation)..."
	@echo "🎯 Target platform: x86_64-linux"
	nix build --impure .#checks.x86_64-linux.vm-test-suite --show-trace
	@echo "✅ VM test suite completed"
	@cat result 2>/dev/null || true

test-e2e:
	@echo "🚀 Running E2E tests (fast VM test)..."
	@if echo "$(CURRENT_SYSTEM)" | grep -q "linux"; then \
		$(NIX) build --impure .#checks.$(CURRENT_SYSTEM).fast-vm-e2e --show-trace; \
		echo "✅ E2E tests passed"; \
	else \
		echo "⏭️  E2E tests skipped (Linux only, current: $(CURRENT_SYSTEM))"; \
	fi

# Linux Builder (macOS only)
test-linux-builder:
	@echo "🐧 Testing linux-builder..."
	@if ! sudo launchctl list org.nixos.linux-builder >/dev/null 2>&1; then \
		echo "❌ linux-builder not running"; \
		echo "   Activate with: make switch"; \
		exit 1; \
	fi
	@echo "✅ linux-builder is running"
	@echo "🔨 Testing Linux build..."
	@$(NIX) build --impure '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel' && \
		echo "✅ Linux build successful"

# Build & Deploy
build: check-user
	@echo "🏗️ Building $(CURRENT_SYSTEM)..."
	@if [ -z "$(BUILD_TARGET)" ]; then \
		echo "❌ Unsupported platform: $(CURRENT_SYSTEM)"; \
		exit 1; \
	fi
	@export USER=$(USER) && $(NIX) build --impure --fallback --keep-going .#$(BUILD_TARGET) $(ARGS)
	@echo "✅ Build complete: $(BUILD_TARGET)"

build-switch: switch

switch: check-user
	@echo "🚀 Switching system configuration..."
	@OS=$$(uname -s); \
	if [ "$${OS}" = "Darwin" ]; then \
		TARGET=$${HOST:-macbook-pro}; \
		case "$$TARGET" in \
			*-darwin) TARGET=macbook-pro;; \
		esac; \
		export USER=$(USER); $(NIX) build --impure --quiet .#darwinConfigurations.$${TARGET}.system $(ARGS) || exit 1; \
		sudo -E env USER=$(USER) ./result/sw/bin/darwin-rebuild switch --impure --flake .#$${TARGET} $(ARGS) || exit 1; \
		rm -f ./result; \
	else \
		echo "❌ ERROR: Only Darwin (macOS) is supported. NixOS configurations not defined."; \
		exit 1; \
	fi

switch-user: check-user
	@echo "🔧 Applying user configuration only (no sudo required)..."
	@OS=$$(uname -s); \
	if [ "$${OS}" = "Darwin" ]; then \
		TARGET=$${HOST:-macbook-pro}; \
		case "$$TARGET" in \
			*-darwin) TARGET=macbook-pro;; \
		esac; \
		echo "🔨 Activating home-manager configuration for $(USER)..."; \
		export USER=$(USER); home-manager switch --impure --flake .#$(USER)@$${TARGET} $(ARGS) || exit 1; \
		echo "✅ User configuration applied successfully"; \
	else \
		echo "❌ ERROR: Only Darwin (macOS) is supported. NixOS configurations not defined."; \
		exit 1; \
	fi

# VM Management
vm/bootstrap0:
	@echo "🚀 Bootstrapping NixOS on new VM..."
	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
		parted /dev/sda -- mklabel gpt; \
		parted /dev/sda -- mkpart primary 512MB -8GB; \
		parted /dev/sda -- mkpart primary linux-swap -8GB 100\%; \
		parted /dev/sda -- mkpart ESP fat32 1MB 512MB; \
		parted /dev/sda -- set 3 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos /dev/sda1; \
		mkswap -L swap /dev/sda2; \
		mkfs.fat -F 32 -n boot /dev/sda3; \
		sleep 1; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		sed --in-place '/system\.stateVersion = .*/a \
			nix.package = pkgs.nixVersions.latest;\n \
			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
			services.openssh.enable = true;\n \
			services.openssh.settings.PasswordAuthentication = true;\n \
			services.openssh.settings.PermitRootLogin = \"yes\";\n \
			users.users.root.initialPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd && reboot; \
	"

vm/bootstrap:
	@echo "🔧 Completing VM bootstrap..."
	$(MAKE) vm/copy
	$(MAKE) vm/switch
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo reboot; \
	"

vm/copy:
	@echo "📤 Copying configurations to VM..."
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='vendor/' \
		--exclude='.git/' \
		--exclude='.git-crypt/' \
		--exclude='.jj/' \
		--exclude='iso/' \
		--rsync-path="sudo rsync" \
		. $(NIXUSER)@$(NIXADDR):/nix-config

vm/switch:
	@echo "🔄 Applying configuration on VM..."
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo nixos-rebuild switch --flake \"/nix-config#vm-aarch64-utm\" \
	"

.PHONY: help check-user format lint test test-unit test-integration test-all test-e2e test-vm test-linux-builder build build-switch switch switch-user vm/bootstrap0 vm/bootstrap vm/copy vm/switch
