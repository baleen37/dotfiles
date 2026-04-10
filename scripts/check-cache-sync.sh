#!/usr/bin/env bash
# Check that flake.nix nixConfig and lib/cache-config.nix are in sync.
# Used as a pre-commit hook.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
FLAKE="$REPO_ROOT/flake.nix"
CACHE_CONFIG="$REPO_ROOT/lib/cache-config.nix"

# Extract substituters from flake.nix (between nixConfig's substituters brackets)
flake_substituters=$(sed -n '/nixConfig/,/accept-flake-config/{/substituters/,/\]/p}' "$FLAKE" \
  | grep -o '"[^"]*"' | sort)

# Extract substituters from cache-config.nix
cache_substituters=$(sed -n '/substituters/,/\]/p' "$CACHE_CONFIG" \
  | grep -o '"[^"]*"' | sort)

# Extract trusted-public-keys from flake.nix
flake_keys=$(sed -n '/nixConfig/,/accept-flake-config/{/trusted-public-keys/,/\]/p}' "$FLAKE" \
  | grep -o '"[^"]*"' | sort)

# Extract trusted-public-keys from cache-config.nix
cache_keys=$(sed -n '/trusted-public-keys/,/\]/p' "$CACHE_CONFIG" \
  | grep -o '"[^"]*"' | sort)

errors=0

if [ "$flake_substituters" != "$cache_substituters" ]; then
  echo "ERROR: substituters mismatch between flake.nix and lib/cache-config.nix" >&2
  echo "" >&2
  echo "flake.nix:" >&2
  echo "$flake_substituters" >&2
  echo "" >&2
  echo "lib/cache-config.nix:" >&2
  echo "$cache_substituters" >&2
  errors=1
fi

if [ "$flake_keys" != "$cache_keys" ]; then
  echo "ERROR: trusted-public-keys mismatch between flake.nix and lib/cache-config.nix" >&2
  echo "" >&2
  echo "flake.nix:" >&2
  echo "$flake_keys" >&2
  echo "" >&2
  echo "lib/cache-config.nix:" >&2
  echo "$cache_keys" >&2
  errors=1
fi

if [ "$errors" -eq 0 ]; then
  echo "Cache config is in sync."
fi

exit $errors
