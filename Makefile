.DEFAULT_GOAL := help

ARCH := $(shell uname -m)
OS := $(shell uname -s | tr A-Z a-z)
NIX := nix --extra-experimental-features 'nix-command flakes'

help:
	@echo "Available targets:"
	@echo "  lint   - Run pre-commit lint"
	@echo "  smoke  - Run nix flake checks for all systems"
	@echo "  test   - Run flake unit tests"
	@echo "  build  - Build all Darwin and NixOS configurations"
	@echo "  switch - Apply configuration on the current machine (HOST=<system> optional)"

lint:
	pre-commit run --all-files

ifdef SYSTEM
smoke:
	$(NIX) flake check --impure --system $(SYSTEM) --no-build $(ARGS)
else
smoke:
	$(NIX) flake check --impure --all-systems --no-build $(ARGS)
endif

test: export USER ?= codex
test:
	$(NIX) flake check --impure --no-build

build-linux:
	$(NIX) build --impure --no-link ".#nixosConfigurations.x86_64-linux.config.system.build.toplevel" $(ARGS)
	$(NIX) build --impure --no-link ".#nixosConfigurations.aarch64-linux.config.system.build.toplevel" $(ARGS)

build-darwin:
	$(NIX) build --impure --no-link ".#darwinConfigurations.x86_64-darwin.system" $(ARGS)
	$(NIX) build --impure --no-link ".#darwinConfigurations.aarch64-darwin.system" $(ARGS)

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
	nix --extra-experimental-features 'nix-command flakes' build --impure .#darwinConfigurations.$${TARGET}.system $(ARGS); \
	sudo ./result/sw/bin/darwin-rebuild switch --flake .#$${TARGET} $(ARGS); \
	unlink ./result; \
	else \
	sudo SSH_AUTH_SOCK=$$SSH_AUTH_SOCK /run/current-system/sw/bin/nixos-rebuild switch --impure --flake .#$${TARGET} $(ARGS); \
	fi

.PHONY: help lint smoke test build build-linux build-darwin switch
