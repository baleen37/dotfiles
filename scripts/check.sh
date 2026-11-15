#!/usr/bin/env bash
# All check commands consume the same filtered source, including new modules.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/setup.sh"
mode=${1:-}
case "$mode" in
  evaluate | assertions | containers | format | format-check) ;;
  *) die 'Usage: scripts/check.sh evaluate | assertions | containers | format | format-check' ;;
esac
setup_context
# Matrix checks describe the versioned registry, not a personal local host.
rm -f "$SOURCE_DIR/source/flake-modules/hosts.local.nix"
case "$mode" in
  evaluate)
    nix_cmd flake check "$FLAKE_REF" --no-build --all-systems --show-trace
    ;;
  assertions)
    nix_cmd build "$FLAKE_REF#checks.$NIX_SYSTEM.all-assertions" --print-build-logs --no-link
    ;;
  containers)
    [ "$OS" = Linux ] && [ -r /dev/kvm ] && [ -w /dev/kvm ] \
      || die 'VM tests require Linux with readable and writable /dev/kvm'
    nix_cmd build \
      "$FLAKE_REF#checks.$NIX_SYSTEM.container-smoke" \
      "$FLAKE_REF#checks.$NIX_SYSTEM.container-basic" \
      "$FLAKE_REF#checks.$NIX_SYSTEM.container-services" \
      "$FLAKE_REF#checks.$NIX_SYSTEM.container-packages" \
      --print-build-logs --no-link
    ;;
  format-check)
    nix_cmd build "$FLAKE_REF#checks.$NIX_SYSTEM.treefmt" --print-build-logs --no-link
    ;;
  format)
    formatter=$(nix_cmd build "$FLAKE_REF#formatter.$NIX_SYSTEM" --no-link --print-out-paths)
    "$formatter/bin/treefmt" --working-dir "$REPO_DIR"
    ;;
esac
