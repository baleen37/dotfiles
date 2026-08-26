# Connectivity info for Linux VM
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= root

# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# The name of the nixosConfiguration in the flake
NIXNAME ?= $(shell hostname -s 2>/dev/null || hostname | cut -d. -f1)
HM_USER ?= $(shell id -un 2>/dev/null || whoami)

# SSH options that are used. These aren't meant to be overridden but are
# reused a lot so we just store them up here.
SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# Nix command with experimental features
# For CI environments, use full path to nix binary when available
NIX_PATH := $(shell which nix 2>/dev/null || echo "nix")
NIX := $(NIX_PATH) --extra-experimental-features nix-command --extra-experimental-features flakes
DARWIN_REBUILD := /run/current-system/sw/bin/darwin-rebuild

# For sudo commands, we need the full path or preserved PATH
# Use -H flag to set HOME to target user's home directory and avoid warnings
SUDO_NIX := sudo -H env PATH=$$PATH $(NIX_PATH) --extra-experimental-features nix-command --extra-experimental-features flakes

# We need to do some OS switching below.
UNAME := $(shell uname)
IS_NIXOS := $(shell [ -f /etc/nixos/configuration.nix ] && echo true || echo false)

# Nix system double for flake attribute paths, e.g. aarch64-darwin.
NIX_ARCH := $(shell uname -m | sed 's/^arm64$$/aarch64/')
NIX_OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
NIX_SYSTEM := $(NIX_ARCH)-$(NIX_OS)

# Environment variables for Nix builds
NIX_ENV := NIXPKGS_ALLOW_UNFREE=1
NIX_ENV_FULL := NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1

build-switch: switch

switch:
ifeq ($(UNAME), Darwin)
	$(NIX_ENV) sudo -H $(DARWIN_REBUILD) switch --flake ".#$(NIXNAME)"
else ifeq ($(IS_NIXOS), true)
	$(NIX_ENV_FULL) $(SUDO_NIX) run "nixpkgs#nixos-rebuild" -- switch --flake ".#${NIXNAME}"
else
	$(NIX_ENV_FULL) $(NIX) run 'github:nix-community/home-manager' -- switch --flake ".#${NIXNAME}"
endif

# Rebuild only Home Manager configuration (faster for user config changes)
# This target does not install Homebrew casks; full `make switch` owns that path.
# Usage: make switch-home
switch-home:
	@echo "Rebuilding Home Manager configuration for $(HM_USER)..."
ifeq ($(UNAME), Darwin)
	$(NIX_ENV) $(NIX) run 'github:nix-community/home-manager' -- switch --flake ".#$(HM_USER)"
else
	$(NIX_ENV_FULL) $(NIX) run 'github:nix-community/home-manager' -- switch --flake ".#$(HM_USER)"
endif

test:
	@echo "Running dual-mode tests..."
	@if [ "$(UNAME)" = "Darwin" ] || [ ! -e /dev/kvm ]; then \
		if [ "$(UNAME)" = "Darwin" ]; then \
			echo "macOS detected: Running validation mode (container tests require Linux + KVM)"; \
		else \
			echo "Linux without KVM detected: Running validation mode (NixOS VM tests require /dev/kvm)"; \
		fi; \
		echo "Validating all test configurations without execution..."; \
		$(NIX_ENV) $(NIX) flake check --no-build --accept-flake-config --show-trace; \
		echo "Validation completed - Full container tests run only where KVM is available"; \
	else \
		echo "Linux with KVM detected: Running full container test execution..."; \
		$(NIX_ENV_FULL) $(NIX) flake check --accept-flake-config --show-trace \
			|| { $(MAKE) --no-print-directory fmt-diff; exit 1; }; \
	fi

# `nix flake check` truncates a failing check's log to its last 25 lines. treefmt
# emits one diff covering every unformatted file, so that truncation hides all but
# the last file's hunks — which makes a formatting failure very hard to act on.
# Build the treefmt check alone with --print-build-logs to get the whole diff.
fmt-diff:
	@echo "--- full treefmt diff (nix flake check only shows its last 25 lines) ---"
	$(NIX_ENV) $(NIX) build ".#checks.$(NIX_SYSTEM).treefmt" \
		--accept-flake-config --print-build-logs --no-link 2>&1 || true

# Build every unit and integration assertion. `make test` falls back to
# --no-build wherever container tests cannot run, and --no-build only evaluates
# checks, so a false assertion goes unnoticed there. The all-assertions
# aggregate excludes the container VMs and therefore builds on any platform.
test-build:
	@echo "Building all unit and integration assertions..."
	$(NIX_ENV_FULL) $(NIX) build ".#checks.$(NIX_SYSTEM).all-assertions" \
		--accept-flake-config --print-build-logs --no-link

# Kept as the name CI and the pre-push hook call. It deliberately does NOT
# depend on test-build: `make test-build` would build assertions that CI has
# never built before, so flipping it on is a separate, deliberate change.
test-all: test
	@echo "All tests completed successfully"

format:
	$(NIX) fmt

# NixOS VM tests. These need a Linux builder with /dev/kvm; on macOS they only
# work through a linux-builder, which Determinate Nix disables (see
# machines/darwin/common.nix), so this is expected to fail there.
test-containers:
	@if [ "$(UNAME)" = "Darwin" ] || [ ! -e /dev/kvm ]; then \
		echo "Container tests need Linux + /dev/kvm; run them in CI or a Linux VM."; \
		exit 1; \
	fi; \
	$(NIX_ENV_FULL) $(NIX) build \
		".#checks.$(NIX_SYSTEM).container-smoke" \
		".#checks.$(NIX_SYSTEM).container-basic" \
		".#checks.$(NIX_SYSTEM).container-services" \
		".#checks.$(NIX_SYSTEM).container-packages" \
		--accept-flake-config --print-build-logs --no-link

# This builds the given configuration and pushes the results to the
# cache. This does not alter the current running system. This requires
# cachix authentication to be configured out of band.
cache:
ifeq ($(UNAME), Darwin)
	nix build '.#darwinConfigurations.$(NIXNAME).system' --accept-flake-config --json \
		| jq -r '.[].outputs | to_entries[].value' \
		| cachix push baleen-nix
else
	nix build '.#nixosConfigurations.$(NIXNAME).config.system.build.toplevel' --accept-flake-config --json \
		| jq -r '.[].outputs | to_entries[].value' \
		| cachix push baleen-nix
endif

# Backup secrets so that we can transer them to new machines via
# sneakernet or other means.
.PHONY: secrets/backup
secrets/backup:
	tar -czvf $(MAKEFILE_DIR)/backup.tar.gz \
		-C $(HOME) \
		--exclude='.gnupg/.#*' \
		--exclude='.gnupg/S.*' \
		--exclude='.gnupg/*.conf' \
		--exclude='.ssh/environment' \
		.ssh/ \
		.gnupg

.PHONY: secrets/restore
secrets/restore:
	if [ ! -f $(MAKEFILE_DIR)/backup.tar.gz ]; then \
		echo "Error: backup.tar.gz not found in $(MAKEFILE_DIR)"; \
		exit 1; \
	fi
	echo "Restoring SSH keys and GPG keyring from backup..."
	mkdir -p $(HOME)/.ssh $(HOME)/.gnupg
	tar -xzvf $(MAKEFILE_DIR)/backup.tar.gz -C $(HOME)
	chmod 700 $(HOME)/.ssh $(HOME)/.gnupg
	chmod 600 $(HOME)/.ssh/* || true
	chmod 700 $(HOME)/.gnupg/* || true

# bootstrap a brand new VM. The VM should have NixOS ISO on the CD drive
# and just set the password of the root user to "root". This will install
# NixOS. After installing NixOS, you must reboot and set the root password
# for the next step.
#
# NOTE(mitchellh): I'm sure there is a way to do this and bootstrap all
# in one step but when I tried to merge them I got errors. One day.
vm/bootstrap0:
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
			nix.settings.substituters = [\"https://mitchellh-nixos-config.cachix.org\"];\n \
			nix.settings.trusted-public-keys = [\"mitchellh-nixos-config.cachix.org-1:bjEbXJyLrL1HZZHBbO4QALnI5faYZppzkU4D2s0G8RQ=\"];\n \
  			services.openssh.enable = true;\n \
			services.openssh.settings.PasswordAuthentication = true;\n \
			services.openssh.settings.PermitRootLogin = \"yes\";\n \
			users.users.root.initialPassword = \"root\";\n \
		' /mnt/etc/nixos/configuration.nix; \
		nixos-install --no-root-passwd && reboot; \
	"

# after bootstrap0, run this to finalize. After this, do everything else
# in the VM unless secrets change.
vm/bootstrap:
	NIXUSER=root $(MAKE) vm/copy
	NIXUSER=root $(MAKE) vm/switch
	$(MAKE) vm/secrets
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo reboot; \
	"

# copy our secrets into the VM
vm/secrets:
	# GPG keyring
	rsync -av -e 'ssh $(SSH_OPTIONS)' \
		--exclude='.#*' \
		--exclude='S.*' \
		--exclude='*.conf' \
		$(HOME)/.gnupg/ $(NIXUSER)@$(NIXADDR):~/.gnupg
	# SSH keys
	rsync -av -e 'ssh $(SSH_OPTIONS)' \
		--exclude='environment' \
		$(HOME)/.ssh/ $(NIXUSER)@$(NIXADDR):~/.ssh

# copy the Nix configurations into the VM.
vm/copy:
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='vendor/' \
		--exclude='.git/' \
		--exclude='.git-crypt/' \
		--exclude='.jj/' \
		--exclude='iso/' \
		--rsync-path="sudo rsync" \
		$(MAKEFILE_DIR)/ $(NIXUSER)@$(NIXADDR):/nix-config

# run the nixos-rebuild switch command. This does NOT copy files so you
# have to run vm/copy before.
vm/switch:
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo env PATH=$$PATH NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix --extra-experimental-features nix-command --extra-experimental-features flakes run \"nixpkgs#nixos-rebuild\" -- switch --flake \"/nix-config#${NIXNAME}\" \
	"

# Build a WSL installer
.PHONY: wsl
wsl:
	 nix build ".#nixosConfigurations.wsl.config.system.build.installer"

# Phony targets
.PHONY: build-switch switch switch-home test test-build test-all test-containers fmt-diff format cache vm/bootstrap0 vm/bootstrap vm/copy vm/switch vm/secrets secrets/backup secrets/restore install-hooks lint update

install-hooks:
	pre-commit install --hook-type pre-commit --hook-type pre-push

lint:
	pre-commit run --all-files

update:
	nix flake update
