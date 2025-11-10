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
	NIXPKGS_ALLOW_UNFREE=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#darwinConfigurations.${NIXNAME}.system"
else
	NIXPKGS_ALLOW_UNFREE=1 nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes ".#nixosConfigurations.${NIXNAME}.config.system.build.toplevel"
endif
