.DEFAULT_GOAL := help

# Auto-detect USER if not set
USER ?= $(shell whoami)
NIX := nix --extra-experimental-features 'nix-command flakes'
CURRENT_SYSTEM := $(shell $(NIX) eval --impure --expr 'builtins.currentSystem' | tr -d '"')
HOSTNAME := $(shell hostname -s 2>/dev/null || hostname | cut -d. -f1)

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
	@echo "  lint-quick  - Fast format + basic validation"
	@echo ""
	@echo "🧪 Testing:"
	@echo "  test             - Run core tests"
	@echo "  test-quick       - Fast validation (2-3s)"
	@echo "  test-integration - Run integration tests"
	@echo "  test-all         - Comprehensive test suite"
	@echo "  test-vm          - VM test (use TARGET_PLATFORM=<platform> for specific)"
	@echo "  test-vm-quick    - Configuration validation only (30 seconds)"
	@echo ""
	@echo "🔨 Build & Deploy:"
	@echo "  build       - Build current platform"
	@echo "  build-switch - Build system (same as switch)"
	@echo "  switch      - Build + apply system config"
	@echo ""
	@echo "🖥️  VM Management:"
	@echo "  vm/bootstrap0 - Bootstrap new NixOS VM (initial install)"
	@echo "  vm/bootstrap  - Complete VM setup with dotfiles"
	@echo "  vm/copy      - Copy configurations to VM"
	@echo "  vm/switch    - Apply configuration changes on VM"
	@echo ""
	@echo "🔧 VM Testing Scripts:"
	@echo "  scripts/vm-test-runner.sh  - Advanced VM testing with build, boot, cleanup"
	@echo "  scripts/vm-e2e-tests.sh    - Comprehensive E2E test suite"
	@echo ""
	@echo "💡 Common Workflows:"
	@echo "  make lint-quick && make test-quick  # Before commit"
	@echo "  make format && make test            # Before PR"
	@echo "  make switch                         # Update system"
	@echo "  make vm/copy && make vm/switch      # Update VM configuration"

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

test-integration:
	@echo "🔗 Running integration tests..."
	@./tests/integration/test-claude-home-symlink.sh
	@./tests/integration/test-claude-symlink.sh

test-all:
	@echo "🔬 Running comprehensive test suite..."
	@$(NIX) build --impure --quiet .#checks.$(CURRENT_SYSTEM).smoke $(ARGS)
	@$(NIX) build --impure --quiet .#checks.$(CURRENT_SYSTEM).unit-mksystem $(ARGS)
	@$(NIX) build --impure --quiet .#checks.$(CURRENT_SYSTEM).unit-git $(ARGS)
	@$(NIX) build --impure --quiet .#checks.$(CURRENT_SYSTEM).unit-claude $(ARGS)
	@$(MAKE) test-integration
	@echo "✅ All tests passed"

# Determine Linux target for VM testing based on current Darwin architecture
LINUX_TARGET = $(shell echo "$(CURRENT_SYSTEM)" | sed 's/darwin/linux/')

test-vm:
	@PLATFORM=$${TARGET_PLATFORM:-$(CURRENT_SYSTEM)}; \
	echo "🚀 VM test suite for $$PLATFORM..."; \
	echo "ℹ️  Note: Set TARGET_PLATFORM env var to test different platform"; \
	echo ""; \
	nix build --impure .#checks.$$PLATFORM.unit-vm-analysis && cat result || true; \
	nix build --impure .#checks.$$PLATFORM.unit-vm-execution && cat result || true; \
	echo "✅ VM test suite completed"

test-vm-quick:
	@echo "⚡ Configuration validation only (30 seconds)..."
	nix build .#checks.$(CURRENT_SYSTEM).unit-vm-analysis && cat result

# Build & Deploy
build: check-user
	@echo "🔨 Building $(CURRENT_SYSTEM)..."
	@OS=$$(uname -s); \
	if [ "$${OS}" = "Darwin" ]; then \
		TARGET=$${HOST:-macbook-pro}; \
		case "$$TARGET" in \
			*-darwin) TARGET=macbook-pro;; \
		esac; \
		export USER=$(USER); $(NIX) build --impure --fallback --keep-going --no-link --quiet .#darwinConfigurations.$${TARGET}.system $(ARGS) || exit 1; \
	else \
		echo "❌ ERROR: Only Darwin (macOS) is supported. NixOS configurations not defined."; \
		exit 1; \
	fi

build-switch: check-user
	@echo "🚀 Building system configuration..."
	@OS=$$(uname -s); \
	if [ "$${OS}" = "Darwin" ]; then \
		TARGET=$${HOST:-macbook-pro}; \
		case "$$TARGET" in \
			*-darwin) TARGET=macbook-pro;; \
		esac; \
		export USER=$(USER); $(NIX) build --impure --quiet .#darwinConfigurations.$${TARGET}.system $(ARGS) || exit 1; \
	else \
		echo "❌ ERROR: Only Darwin (macOS) is supported. NixOS configurations not defined."; \
		exit 1; \
	fi

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

.PHONY: help check-user format lint lint-quick test test-quick test-integration test-all test-vm test-vm-quick build build-switch switch vm/bootstrap0 vm/bootstrap vm/copy vm/switch
