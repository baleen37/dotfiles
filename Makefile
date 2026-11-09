# Get the path to this Makefile and directory
MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# The name of the nixosConfiguration in the flake
NIXNAME ?= $(shell hostname -s 2>/dev/null || hostname | cut -d. -f1)
HM_USER ?= $(shell id -un 2>/dev/null || whoami)

# Nix command with experimental features
# For CI environments, use full path to nix binary when available
NIX_PATH := $(shell which nix 2>/dev/null || echo "nix")
NIX := $(NIX_PATH) --extra-experimental-features nix-command --extra-experimental-features flakes
# For sudo commands, we need the full path or preserved PATH
# Use -H flag to set HOME to target user's home directory and avoid warnings
SUDO_NIX := sudo -H env PATH="$$PATH" $(NIX_PATH) --extra-experimental-features nix-command --extra-experimental-features flakes

# We need to do some OS switching below.
UNAME := $(shell uname)
# /etc/NIXOS is the marker every NixOS system carries; /etc/nixos/configuration.nix
# is absent on hosts that were installed from a flake.
IS_NIXOS := $(shell [ -e /etc/NIXOS ] && echo true || echo false)

# Nix system double for flake attribute paths, e.g. aarch64-darwin.
NIX_ARCH := $(shell uname -m | sed 's/^arm64$$/aarch64/')
NIX_OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
NIX_SYSTEM := $(NIX_ARCH)-$(NIX_OS)

build-switch: switch

switch:
	./switch.sh "$(NIXNAME)"

switch-home:
	HM_USER="$(HM_USER)" ./switch.sh --home

test:
	@echo "Running dual-mode tests..."
	@if [ "$(UNAME)" = "Darwin" ] || [ ! -e /dev/kvm ]; then \
		if [ "$(UNAME)" = "Darwin" ]; then \
			echo "macOS detected: Running validation mode (container tests require Linux + KVM)"; \
		else \
			echo "Linux without KVM detected: Running validation mode (NixOS VM tests require /dev/kvm)"; \
		fi; \
		echo "Validating all test configurations without execution..."; \
		$(NIX) flake check --no-build --accept-flake-config --show-trace; \
		echo "Validation completed - Full container tests run only where KVM is available"; \
	else \
		echo "Linux with KVM detected: Running full container test execution..."; \
		$(NIX) flake check --accept-flake-config --show-trace \
			|| { $(MAKE) --no-print-directory fmt-diff; exit 1; }; \
	fi

# `nix flake check` truncates a failing check's log to its last 25 lines. treefmt
# emits one diff covering every unformatted file, so that truncation hides all but
# the last file's hunks — which makes a formatting failure very hard to act on.
# Build the treefmt check alone with --print-build-logs to get the whole diff.
fmt-diff:
	@echo "--- full treefmt diff (nix flake check only shows its last 25 lines) ---"
	$(NIX) build ".#checks.$(NIX_SYSTEM).treefmt" \
		--accept-flake-config --print-build-logs --no-link 2>&1 || true

# Build every unit and integration assertion. `make test` falls back to
# --no-build wherever container tests cannot run, and --no-build only evaluates
# checks, so a false assertion goes unnoticed there. The all-assertions
# aggregate excludes the container VMs and therefore builds on any platform.
test-build:
	@echo "Building all unit and integration assertions..."
	$(NIX) build ".#checks.$(NIX_SYSTEM).all-assertions" \
		--accept-flake-config --print-build-logs --no-link

# Kept as the name the pre-push hook calls. CI runs `make test-build` as its
# own step, so this stays evaluation-only off Linux+KVM to keep pushes fast.
test-all: test
	@echo "All tests completed successfully"

format:
	$(NIX) fmt

# NixOS VM tests. These need a Linux builder with /dev/kvm; on macOS they only
# work through a linux-builder, which Determinate Nix disables, so this is
# expected to fail there.
test-containers:
	@if [ "$(UNAME)" = "Darwin" ] || [ ! -e /dev/kvm ]; then \
		echo "Container tests need Linux + /dev/kvm; run them in CI or a Linux VM."; \
		exit 1; \
	fi; \
	$(NIX) build \
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
	HOST="$(NIXNAME)" bash -euo pipefail -c '\
		source scripts/lib/setup.sh; HOME_ONLY=false; setup_context; \
		nix_cmd build "$$FLAKE_REF#darwinConfigurations.\"$$HOST\".system" --json \
		| jq -r ".[].outputs | to_entries[].value" \
		| cachix push baleen-nix'
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

# Build the NixOS-WSL tarball (nixos.wsl in the current directory)
.PHONY: wsl
wsl:
	$(SUDO_NIX) run ".#nixosConfigurations.wsl.config.system.build.tarballBuilder"

# Phony targets
.PHONY: build-switch switch switch-home test test-build test-all test-containers fmt-diff format cache secrets/backup secrets/restore install-hooks lint update

install-hooks:
	pre-commit install --hook-type pre-commit --hook-type pre-push

lint:
	pre-commit run --all-files

update:
	nix flake update
