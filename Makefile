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

.PHONY: help check-user format lint lint-quick test test-quick test-all build build-switch switch vm/bootstrap0 vm/bootstrap vm/build vm/test vm/copy vm/switch

# VM Management
vm/bootstrap0:  ## Initial NixOS installation on VM
	@echo "Installing NixOS on VM at $(NIXADDR)..."
	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
		parted /dev/vda -- mklabel gpt; \
		parted /dev/vda -- mkpart primary 512MB 100%; \
		parted /dev/vda -- mkpart ESP fat32 1MB 512MB; \
		parted /dev/vda -- set 2 esp on; \
		sleep 1; \
		mkfs.ext4 -L nixos /dev/vda1; \
		mkfs.fat -F 32 -n boot /dev/vda2; \
		sleep 1; \
		mount /dev/disk/by-label/nixos /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		nixos-generate-config --root /mnt; \
		nixos-install --flake $(MAKEFILE_DIR)#$(NIXNAME); \
	"
	@echo "Bootstrap complete. Reboot the VM and run 'make vm/bootstrap'"

vm/bootstrap:  ## Apply full NixOS configuration to VM
	@echo "Applying NixOS configuration to VM..."
	NIXPKGS_ALLOW_UNFREE=1 ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo nixos-rebuild switch --flake $(MAKEFILE_DIR)#$(NIXNAME) \
	"
	@echo "Configuration applied successfully"

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

vm/build:  ## Build NixOS VM configuration locally
	@echo "Building NixOS VM configuration..."
	nix build .#nixosConfigurations.$(NIXNAME).config.system.build.toplevel
	@echo "Build successful"

vm/test:  ## Run NixOS VM integration tests
	@echo "Running NixOS VM tests..."
	nix-build tests/nixos/vm-boot-test.nix
	@echo "Tests passed"

vm/switch:
	@echo "🔄 Applying configuration on VM..."
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo nixos-rebuild switch --flake \"/nix-config#vm-aarch64-utm\" \
	"
