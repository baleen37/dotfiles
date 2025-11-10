# Makefile for baleen's dotfiles - mitchellh style

# Connectivity info for Linux VM
NIXADDR ?= unset
NIXPORT ?= 22
NIXUSER ?= root

# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE LIST)))))

# The name of the nixosConfiguration in the flake
NIXNAME ?= $(shell hostname -s 2>/dev/null || hostname | cut -d. -f1)

# SSH options that are used. These aren't meant to be overridden but are
# reused a lot so we just store them up here.
SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

# OS detection (mitchellh exact pattern)
UNAME := $(shell uname)

.DEFAULT_GOAL := help

help:
	@echo "Available targets:"
	@echo "  build     - Build configuration"
	@echo "  switch    - Build and switch configuration"
	@echo "  test      - Test configuration"
	@echo "  cache     - Build and push to cache"
	@echo "  format    - Format all files"
	@echo "  check     - Run flake check"
	@echo ""
	@echo "VM targets:"
	@echo "  vm/bootstrap0  - Initialize VM"
	@echo "  vm/bootstrap   - Complete VM setup"
	@echo "  vm/copy        - Copy configs to VM"
	@echo "  vm/switch      - Apply configs on VM"

build:
ifeq ($(UNAME), Darwin)
	NIXPKGS_ALLOW_UNFREE=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.macbook-pro.system"
else
	NIXPKGS_ALLOW_UNFREE=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#nixosConfigurations.${NIXNAME}.config.system.build.toplevel"
endif

switch:
ifeq ($(UNAME), Darwin)
	NIXPKGS_ALLOW_UNFREE=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.macbook-pro.system"
	sudo NIXPKGS_ALLOW_UNFREE=1 ./result/sw/bin/darwin-rebuild switch --impure --flake "$$(pwd)#macbook-pro"
else
	sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild switch --impure --flake ".#${NIXNAME}"
endif

test: build
ifeq ($(UNAME), Darwin)
	# On Darwin, just test the build
else
	sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nixos-rebuild test --impure --flake ".#${NIXNAME}"
endif

# VM targets (mitchellh exact patterns)
vm/bootstrap0:
	@echo "Bootstrapping NixOS on new VM..."
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

vm/bootstrap: vm/copy vm/switch
	@echo "VM bootstrap completed, rebooting..."
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) "sudo reboot"

vm/copy:
	@echo "Copying configurations to VM..."
	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
		--exclude='vendor/' \
		--exclude='.git/' \
		--exclude='.git-crypt/' \
		--exclude='.jj/' \
		--exclude='iso/' \
		--rsync-path="sudo rsync" \
		. $(NIXUSER)@$(NIXADDR):/nix-config

vm/switch:
	@echo "Applying configuration on VM..."
	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
		sudo nixos-rebuild switch --flake \"/nix-config#$(NIXNAME)\" \
	"

cache:
ifeq ($(UNAME), Darwin)
	NIXPKGS_ALLOW_UNFREE=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.macbook-pro.system"
	cachix push baleen-nix ./result
else
	NIXPKGS_ALLOW_UNFREE=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#nixosConfigurations.${NIXNAME}.config.system.build.toplevel"
	cachix push baleen-nix ./result
endif

format:
	@echo "Formatting all files..."
	@find . -name "*.nix" -not -path "*/.*" -not -path "*/result/*" -type f -exec nix fmt --extra-experimental-features 'nix-command flakes' {} +

check:
	@echo "Running flake check..."
	nix flake check --no-build --extra-experimental-features 'nix-command flakes'

lint: format

.PHONY: help build switch test cache format check lint vm/bootstrap0 vm/bootstrap vm/copy vm/switch
