#!/usr/bin/env bash
# Validates flake outputs for naming conflicts
# Prevents collisions between apps, packages, and checks using helper function pattern

set -euo pipefail

echo "🔍 Checking flake outputs for naming conflicts..."

# Get all output names
apps=$(nix flake show --json 2>/dev/null | jq -r '.apps.[] | keys[]' 2>/dev/null | sort -u || true)
packages=$(nix flake show --json 2>/dev/null | jq -r '.packages.[] | keys[]' 2>/dev/null | sort -u || true)
checks=$(nix flake show --json 2>/dev/null | jq -r '.checks.[] | keys[]' 2>/dev/null | sort -u || true)

# Check for conflicts
conflicts=0

# Helper function to check for conflicts
check_conflict() {
  local name=$1
  local source=$2
  local target_list=$3
  local target_type=$4

  if echo "$target_list" | grep -q "^${name}$"; then
    echo "❌ Conflict: '$name' exists in both $source and $target_type"
    return 1
  fi
  return 0
}

# Compare apps vs packages and checks
for app in $apps; do
  check_conflict "$app" "apps" "$packages" "packages" || conflicts=$((conflicts + 1))
  check_conflict "$app" "apps" "$checks" "checks" || conflicts=$((conflicts + 1))
done

if [ $conflicts -eq 0 ]; then
  echo "✅ No naming conflicts found"
  exit 0
else
  echo "❌ Found $conflicts naming conflict(s)"
  echo ""
  echo "💡 Tip: Use suffixes like -e2e, -test, -app to avoid conflicts"
  exit 1
fi
