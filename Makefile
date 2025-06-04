.DEFAULT_GOAL := help

ARCH := $(shell uname -m)
OS := $(shell uname -s | tr A-Z a-z)

help:
	@echo "Available targets:"
	@echo "  lint   - Run pre-commit lint"
	@echo "  smoke  - Run nix flake checks for all systems"
	@echo "  build  - Build all Darwin and NixOS configurations"
	@echo "  switch - Apply configuration on the current machine (HOST=<system> optional)"

lint:
	pre-commit run --all-files

ifdef SYSTEM
smoke:
	nix flake check --system $(SYSTEM) --no-build
else
smoke:
	nix flake check --system x86_64-linux --no-build
	nix flake check --system aarch64-linux --no-build
	nix flake check --system x86_64-darwin --no-build
	nix flake check --system aarch64-darwin --no-build
endif

build-linux:
	nix build --no-link ".#nixosConfigurations.x86_64-linux.config.system.build.toplevel"
	nix build --no-link ".#nixosConfigurations.aarch64-linux.config.system.build.toplevel"

build-darwin:
	nix build --no-link ".#darwinConfigurations.x86_64-darwin.system"
	nix build --no-link ".#darwinConfigurations.aarch64-darwin.system"

build: build-linux build-darwin

switch:
	@OS=$$(uname -s); \
	ARCH=$$(uname -m); \
	if [ "$${OS}" = "Darwin" ]; then \
	  DEFAULT_SYSTEM="$${ARCH}-darwin"; \
	else \
	  DEFAULT_SYSTEM="$${ARCH}-linux"; \
	fi; \
	TARGET=${HOST-$${DEFAULT_SYSTEM}}; \
	if [ "$${OS}" = "Darwin" ]; then \
	  nix --extra-experimental-features 'nix-command flakes' build .#darwinConfigurations.$${TARGET}.system; \
	  sudo ./result/sw/bin/darwin-rebuild switch --flake .#$${TARGET}; \
	  unlink ./result; \
	else \
	  sudo SSH_AUTH_SOCK=$$SSH_AUTH_SOCK /run/current-system/sw/bin/nixos-rebuild switch --flake .#$${TARGET}; \
	fi

.PHONY: help lint smoke build build-linux build-darwin switch
