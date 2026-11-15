set shell := ["bash", "-euo", "pipefail", "-c"]

# List commands without changing the host.
default:
    @just --list

# Re-run preparation when just is available; fresh machines use bash ./bootstrap.sh.
bootstrap:
    ./bootstrap.sh

# Build the local configuration without activation or secret access.
build:
    ./switch.sh --build

# Apply the local configuration (changes the host).
switch:
    ./switch.sh

alias build-switch := switch

# Evaluate the full platform matrix without building checks.
check:
    bash scripts/check.sh evaluate

# Execute all unit and integration assertions, on every supported platform.
test:
    bash scripts/check.sh assertions

alias test-build := test

# Evaluate all platforms, then execute local assertions. VMs are explicit.
test-all: check test

# Boot the NixOS test VMs; requires usable Linux KVM.
test-containers:
    bash scripts/check.sh containers

# Show the complete formatter-check diff without modifying files.
fmt-diff:
    bash scripts/check.sh format-check

# Format the working tree with the pinned formatter.
format:
    bash scripts/check.sh format

install-hooks:
    pre-commit install --hook-type pre-commit --hook-type pre-push

lint:
    pre-commit run --all-files

update:
    nix --extra-experimental-features 'nix-command flakes' flake update

# Build the selected local closure and upload it; never activates the host.
cache:
    bash scripts/cache.sh

# Record this Mac's public Syncthing device ID in the host registry.
syncthing-id:
    #!/usr/bin/env bash
    set -euo pipefail
    source scripts/lib/setup.sh
    setup_context
    nix_cmd shell --inputs-from "$FLAKE_REF" nixpkgs#syncthing -c bash "$REPO_DIR/scripts/syncthing-register.sh" "$HOST"

# Legacy plaintext SSH/GPG backup. Keep the archive outside shared storage.
secrets-backup:
    #!/usr/bin/env bash
    set -euo pipefail
    umask 077
    tar -czf backup.tar.gz -C "$HOME" \
      --exclude='.gnupg/.#*' --exclude='.gnupg/S.*' --exclude='.gnupg/*.conf' \
      --exclude='.ssh/environment' .ssh/ .gnupg

# Restore the legacy archive into the current home (overwrites matching files).
secrets-restore:
    #!/usr/bin/env bash
    set -euo pipefail
    test -f backup.tar.gz || { echo 'backup.tar.gz not found' >&2; exit 1; }
    mkdir -p "$HOME/.ssh" "$HOME/.gnupg"
    tar -xzf backup.tar.gz -C "$HOME"
    chmod 700 "$HOME/.ssh" "$HOME/.gnupg"
    find "$HOME/.ssh" "$HOME/.gnupg" -type f -exec chmod 600 {} +
    find "$HOME/.ssh" "$HOME/.gnupg" -type d -exec chmod 700 {} +
