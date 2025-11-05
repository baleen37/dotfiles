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
	@echo "  test                     - Run core tests (unit + integration)"
	@echo "  test-e2e                 - Run complete E2E test (cross-platform with fallback)"
	@echo "  test-integration         - Run integration tests"
	@echo "  test-all                 - Comprehensive test suite"
	@echo "  test-vm                  - Full VM test (build + boot + E2E validation)"
	@echo "  test-vm-quick            - Quick VM validation (build only, faster)"
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
	@echo "  make act-check && make act-linux    # Test CI locally before pushing"
	@echo ""
	@echo "ℹ️  Platform Info:"
	@echo "  platform-info                      - Show platform details and VM testing support"

platform-info:
	@echo "🔍 Platform Information & VM Testing Support"
	@echo "=========================================="
	@echo "Current system: $(CURRENT_SYSTEM)"
	@echo "Host architecture: $(shell uname -m)"
	@echo "VM target architecture: $(VM_TARGET_ARCH)"
	@echo ""
	@echo "🚀 VM Testing Capabilities:"
	@if echo "$(CURRENT_SYSTEM)" | grep -q "linux"; then \
		echo "✅ Native Linux VM testing available"; \
		echo "   - Fast builds with native execution"; \
		echo "   - Full QEMU VM support"; \
		echo "   - Commands: make test-vm, make test-vm-quick"; \
	elif echo "$(CURRENT_SYSTEM)" | grep -q "darwin"; then \
		if sudo launchctl list org.nixos.linux-builder >/dev/null 2>&1; then \
			echo "✅ Cross-platform VM testing with linux-builder"; \
			echo "   - QEMU emulation for fast builds"; \
			echo "   - Full Linux VM support on macOS"; \
			echo "   - Commands: make test-vm, make test-vm-quick"; \
		else \
			echo "⚠️  Limited cross-platform VM testing"; \
			echo "   - Cross-compilation available (slower)"; \
			echo "   - Enable linux-builder for better performance:"; \
			echo "     1. Set nix.enable = true in machines/macbook-pro.nix"; \
			echo "     2. Run: make switch"; \
			echo "   - Commands: make test-vm (slow), make test-vm-quick"; \
		fi; \
	else \
		echo "❌ Platform not supported for VM testing"; \
	fi
	@echo ""
	@echo "🔧 Linux Builder Status (macOS only):"
	@if echo "$(CURRENT_SYSTEM)" | grep -q "darwin"; then \
		if sudo launchctl list org.nixos.linux-builder >/dev/null 2>&1; then \
			echo "✅ linux-builder running - Fast cross-compilation available"; \
		else \
			echo "❌ linux-builder not running"; \
			echo "💡 Test with: make test-linux-builder"; \
		fi; \
	else \
		echo "ℹ️  Not applicable on Linux"; \
	fi

# Code Quality
format:
	@echo "🎨 Auto-formatting all files..."
	@find . -name "*.nix" -not -path "*/.*" -not -path "*/result/*" -type f -exec nix fmt -- {} +

lint:
	@echo "🔍 Linting ($(CURRENT_SYSTEM))..."
	@find . -name "*.nix" -not -path "*/.*" -not -path "*/result/*" -type f -exec nix fmt -- {} +
	@$(NIX) flake check --no-build --quiet --accept-flake-config

# Testing (simplified with auto-discovery)
test: check-user
	@echo "🧪 Testing $(CURRENT_SYSTEM)..."
	@export USER=$(USER) && $(NIX) flake check --impure --accept-flake-config $(ARGS)
	@echo "✅ Tests passed"

test-unit:
	@echo "🧪 Running unit tests (auto-discovered)..."
	@$(NIX) eval --impure .#checks.$(CURRENT_SYSTEM) --apply 'x: builtins.length (builtins.filter (n: builtins.match "unit-.*" n != null) (builtins.attrNames x))'
	@echo "unit tests discovered"
	@$(NIX) flake check --impure --no-build --accept-flake-config $(ARGS)

test-integration:
	@echo "🔗 Running integration tests (auto-discovered)..."
	@$(NIX) eval --impure .#checks.$(CURRENT_SYSTEM) --apply 'x: builtins.length (builtins.filter (n: builtins.match "integration-.*" n != null) (builtins.attrNames x))'
	@echo "integration tests discovered"
	@$(NIX) flake check --impure --no-build --accept-flake-config $(ARGS)

test-all:
	@echo "🔬 Running comprehensive test suite..."
	@$(MAKE) test
	@$(MAKE) test-integration
	@$(MAKE) test-e2e
	@$(MAKE) test-vm
	@echo "✅ All tests passed"

# Determine Linux target for VM testing based on current Darwin architecture
LINUX_TARGET = $(shell echo "$(CURRENT_SYSTEM)" | sed 's/darwin/linux/')

# Determine target Linux architecture based on current host architecture
ifeq ($(shell uname -m),arm64)
    VM_TARGET_ARCH = aarch64-linux
    VM_TEST_NAME = vm-test-suite
else
    VM_TARGET_ARCH = x86_64-linux
    VM_TEST_NAME = vm-test-suite
endif

test-vm:
	@echo "🚀 Full VM test (build + boot + E2E validation)..."
	@echo "🎯 Current platform: $(CURRENT_SYSTEM)"
	@echo "🎯 Target VM architecture: $(VM_TARGET_ARCH)"
	@echo "💡 See CLAUDE.md for VM testing requirements and platform support"
	@# Multi-platform VM testing - use native architecture when possible
	@if echo "$(CURRENT_SYSTEM)" | grep -q "linux"; then \
		echo "🐧 Running on native Linux - proceeding with VM test..."; \
		if echo "$(CURRENT_SYSTEM)" | grep -q "aarch64"; then \
			echo "🔧 Building aarch64-linux VM on ARM64 Linux..."; \
			if nix build --impure .#checks.$(VM_TARGET_ARCH).$(VM_TEST_NAME) --show-trace; then \
				echo "✅ aarch64-linux VM test completed successfully"; \
			else \
				echo "❌ aarch64-linux VM test failed"; \
				echo "💡 Check VM configuration in tests/e2e/optimized-vm-suite.nix"; \
				exit 1; \
			fi; \
		else \
			echo "🔧 Building x86_64-linux VM on x86_64 Linux..."; \
			if nix build --impure .#checks.$(VM_TARGET_ARCH).$(VM_TEST_NAME) --show-trace; then \
				echo "✅ x86_64-linux VM test completed successfully"; \
			else \
				echo "❌ x86_64-linux VM test failed"; \
				echo "💡 Check VM configuration in tests/e2e/optimized-vm-suite.nix"; \
				exit 1; \
			fi; \
		fi; \
	elif echo "$(CURRENT_SYSTEM)" | grep -q "darwin"; then \
		echo "🍎 Running on macOS - attempting cross-platform VM build..."; \
		if sudo launchctl list org.nixos.linux-builder >/dev/null 2>&1; then \
			echo "🔧 linux-builder available - proceeding with QEMU emulation for $(VM_TARGET_ARCH)..."; \
			if nix build --impure .#checks.$(VM_TARGET_ARCH).$(VM_TEST_NAME) --show-trace --system $(VM_TARGET_ARCH); then \
				echo "✅ Cross-platform VM test completed successfully with QEMU emulation"; \
			else \
				echo "❌ Cross-platform VM test failed with QEMU emulation"; \
				echo "💡 Check linux-builder status: make test-linux-builder"; \
				echo "💡 Verify VM configuration: tests/e2e/optimized-vm-suite.nix"; \
				exit 1; \
			fi; \
		else \
			echo "⚠️  linux-builder not available - attempting cross-compilation for $(VM_TARGET_ARCH)..."; \
			echo "💡 This may take longer but enables multi-platform VM testing"; \
			echo "💡 To speed up builds, consider enabling linux-builder in machines/macbook-pro.nix"; \
			echo "   - Set nix.enable = true in machines/macbook-pro.nix"; \
			echo "   - Run: make switch"; \
			if nix build --impure .#checks.$(VM_TARGET_ARCH).$(VM_TEST_NAME) --show-trace --system $(VM_TARGET_ARCH) --option system $(VM_TARGET_ARCH); then \
				echo "✅ Cross-platform VM test completed successfully with cross-compilation"; \
			else \
				echo "❌ Cross-platform VM test failed with cross-compilation"; \
				echo "💡 Enable linux-builder for better performance: make test-linux-builder"; \
				echo "💡 Or run on native Linux for faster builds"; \
				exit 1; \
			fi; \
		fi; \
	else \
		echo "❌ Unsupported platform: $(CURRENT_SYSTEM)"; \
		echo "💡 Supported platforms:"; \
		echo "   - Linux: x86_64-linux, aarch64-linux"; \
		echo "   - macOS: x86_64-darwin, aarch64-darwin"; \
		echo "💡 Please file an issue for platform support: https://github.com/your-repo/issues"; \
		exit 1; \
	fi
	@echo "✅ VM test suite completed for $(VM_TARGET_ARCH)"
	@cat result 2>/dev/null || true

test-vm-quick:
	@echo "⚡ Quick VM validation (build only, no boot)..."
	@echo "🎯 Current platform: $(CURRENT_SYSTEM) → Target: $(VM_TARGET_ARCH)"
	@if echo "$(CURRENT_SYSTEM)" | grep -q "linux"; then \
		echo "🐧 Native Linux build validation..."; \
		$(NIX) build --impure --no-link .#checks.$(VM_TARGET_ARCH).$(VM_TEST_NAME) --show-trace && \
			echo "✅ VM build validation passed" || { echo "❌ VM build validation failed"; exit 1; }; \
	elif echo "$(CURRENT_SYSTEM)" | grep -q "darwin"; then \
		if sudo launchctl list org.nixos.linux-builder >/dev/null 2>&1; then \
			echo "🍎 macOS with linux-builder - QEMU emulation..."; \
			$(NIX) build --impure --no-link .#checks.$(VM_TARGET_ARCH).$(VM_TEST_NAME) --show-trace --system $(VM_TARGET_ARCH) && \
				echo "✅ VM build validation passed" || { echo "❌ VM build validation failed"; exit 1; }; \
		else \
			echo "🍎 macOS cross-compilation..."; \
			$(NIX) build --impure --no-link .#checks.$(VM_TARGET_ARCH).$(VM_TEST_NAME) --show-trace --system $(VM_TARGET_ARCH) --option system $(VM_TARGET_ARCH) && \
				echo "✅ VM build validation passed" || { echo "❌ VM build validation failed"; exit 1; }; \
		fi; \
	else \
		echo "❌ Unsupported platform: $(CURRENT_SYSTEM)"; \
		exit 1; \
	fi

test-e2e:
	@echo "🚀 Running E2E test (validates dotfiles configuration)..."
	@echo "🎯 Current platform: $(CURRENT_SYSTEM)"
	@if echo "$(CURRENT_SYSTEM)" | grep -q "linux"; then \
		echo "🐧 Running on Linux - attempting full E2E test..."; \
		if $(NIX) flake show --impure --all-systems 2>&1 | grep -q "checks.$(CURRENT_SYSTEM).vm-e2e"; then \
			$(NIX) build --impure .#checks.$(CURRENT_SYSTEM).vm-e2e --show-trace && \
			echo "✅ E2E test passed" || { echo "❌ E2E test failed"; exit 1; }; \
		else \
			echo "⚠️  vm-e2e check not available for $(CURRENT_SYSTEM) - using configuration validation..."; \
			$(NIX) flake check --impure --accept-flake-config --no-build && \
			echo "✅ Configuration validation passed" || { echo "❌ Configuration validation failed"; exit 1; }; \
		fi; \
	elif echo "$(CURRENT_SYSTEM)" | grep -q "darwin"; then \
		echo "🍎 Running on macOS - attempting cross-platform E2E test..."; \
		if command -v linux-builder >/dev/null 2>&1 && sudo launchctl list org.nixos.linux-builder >/dev/null 2>&1; then \
			echo "🔧 linux-builder available - testing Linux E2E on macOS..."; \
			LINUX_TARGET=$$(echo "$(CURRENT_SYSTEM)" | sed 's/darwin/linux/'); \
			if $(NIX) flake show --impure --all-systems 2>&1 | grep -q "checks.$$LINUX_TARGET.vm-e2e"; then \
				$(NIX) build --impure .#checks.$$LINUX_TARGET.vm-e2e --show-trace && \
				echo "✅ Cross-platform E2E test passed" || { echo "❌ Cross-platform E2E test failed"; exit 1; }; \
			else \
				echo "⚠️  Linux E2E not available - using configuration validation..."; \
				$(NIX) flake check --impure --accept-flake-config --no-build && \
				echo "✅ Configuration validation passed" || { echo "❌ Configuration validation failed"; exit 1; }; \
			fi; \
		else \
			echo "⚠️  linux-builder not available - using configuration validation..."; \
			$(NIX) flake check --impure --accept-flake-config --no-build && \
			echo "✅ Configuration validation passed" || { echo "❌ Configuration validation failed"; exit 1; }; \
		fi; \
	else \
		echo "❌ Unsupported platform: $(CURRENT_SYSTEM)"; \
		echo "💡 Supported platforms: Linux (x86_64-linux, aarch64-linux), macOS (x86_64-darwin, aarch64-darwin)"; \
		exit 1; \
	fi


# Linux Builder (macOS only)
test-linux-builder:
	@echo "🐧 Testing linux-builder for cross-platform VM testing..."
	@if echo "$(CURRENT_SYSTEM)" | grep -q "linux"; then \
		echo "✅ Running on native Linux - linux-builder not needed"; \
		exit 0; \
	fi
	@echo "🔍 Checking linux-builder availability..."
	@if ! command -v linux-builder >/dev/null 2>&1; then \
		echo "❌ linux-builder command not found"; \
		echo "💡 Install with: brew install nix"; \
		exit 1; \
	fi
	@if ! sudo launchctl list org.nixos.linux-builder >/dev/null 2>&1; then \
		echo "❌ linux-builder service not running"; \
		echo "💡 Enable with: sudo launchctl load -w /Library/LaunchDaemons/org.nixos.linux-builder.plist"; \
		echo "💡 Or rebuild system with: make switch"; \
		exit 1; \
	fi
	@echo "✅ linux-builder is running"
	@echo "🔨 Testing Linux build capabilities..."
	@if echo "$(CURRENT_SYSTEM)" | grep -q "aarch64"; then \
		echo "🔧 Testing aarch64-linux build on Apple Silicon..."; \
		$(NIX) build --impure '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel' --system aarch64-linux && \
			echo "✅ aarch64-linux build successful"; \
	else \
		echo "🔧 Testing x86_64-linux build on Intel Mac..."; \
		$(NIX) build --impure '.#checks.x86_64-linux.vm-test-suite' --system x86_64-linux && \
			echo "✅ x86_64-linux build successful"; \
	fi
	@echo "🎉 linux-builder is fully operational for cross-platform VM testing"

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
		echo "🔨 Activating home-manager configuration for $(USER)..."; \
		export USER=$(USER); NIXPKGS_ALLOW_UNFREE=1 home-manager switch --impure --flake .#$(USER) $(ARGS) || exit 1; \
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

.PHONY: help platform-info check-user format lint test test-unit test-integration test-all test-e2e test-vm test-vm-quick test-linux-builder build build-switch switch switch-user vm/bootstrap0 vm/bootstrap vm/copy vm/switch
