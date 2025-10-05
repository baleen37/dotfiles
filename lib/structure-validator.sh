#!/usr/bin/env bash
# Validates project folder structure and enforces architectural boundaries
#
# Validation Rules:
# 1. Required directories must exist (modules, hosts, lib, tests)
# 2. Platform separation: darwin ↔ nixos code must not cross-contaminate
# 3. Shared modules must be platform-agnostic
# 4. lib/ contains only .nix files (pure Nix utilities)

set -euo pipefail

PROJECT_ROOT="${1:-.}"
ERRORS=0

echo "📁 Validating project folder structure..."
echo ""

# Validates required directory structure exists
check_required_dirs() {
  echo "Checking required directories..."
  local required_dirs=(
    "modules"
    "modules/darwin"
    "modules/nixos"
    "modules/shared"
    "hosts"
    "hosts/darwin"
    "hosts/nixos"
    "lib"
    "tests"
    "tests/unit"
    "tests/integration"
    "tests/e2e"
  )

  for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$PROJECT_ROOT/$dir" ]]; then
      echo "❌ Required directory missing: $dir"
      ((ERRORS++))
    fi
  done
}

# Validates platform separation (prevents cross-contamination)
check_platform_separation() {
  echo "Checking platform separation..."

  # Darwin modules should not reference NixOS-specific patterns
  local darwin_violations
  darwin_violations=$(grep -r --include="*.nix" \
    -E "systemd|nixos|boot\.loader|networking\.networkmanager" \
    "$PROJECT_ROOT/modules/darwin" 2>/dev/null || true)

  if [[ -n $darwin_violations ]]; then
    echo "❌ Darwin modules contain NixOS-specific code:"
    echo "$darwin_violations" | head -5
    ((ERRORS++))
  fi

  # NixOS modules should not reference Darwin-specific patterns
  local nixos_violations
  nixos_violations=$(grep -r --include="*.nix" \
    -E "darwin-rebuild|homebrew|system\.defaults|nix-darwin" \
    "$PROJECT_ROOT/modules/nixos" 2>/dev/null || true)

  if [[ -n $nixos_violations ]]; then
    echo "❌ NixOS modules contain Darwin-specific code:"
    echo "$nixos_violations" | head -5
    ((ERRORS++))
  fi

  # Shared modules should be platform-agnostic (exclude config/ directory and conditional code)
  local shared_violations
  shared_violations=$(grep -r --include="*.nix" \
    -E "darwin-rebuild|systemd|nix-darwin" \
    "$PROJECT_ROOT/modules/shared" 2>/dev/null |
    grep -v "config/" |
    grep -v "optionalString" |
    grep -v "^#" |
    grep -v "모두" || true)

  if [[ -n $shared_violations ]]; then
    echo "❌ Shared modules contain unconditional platform-specific code:"
    echo "$shared_violations" | head -5
    ((ERRORS++))
  fi
}

# Validates file naming conventions
check_naming_conventions() {
  echo "Checking naming conventions..."

  # lib/ should only contain .nix, .sh, and .md files
  local invalid_files
  invalid_files=$(find "$PROJECT_ROOT/lib" -type f \
    ! -name "*.nix" ! -name "*.sh" ! -name "*.md" 2>/dev/null || true)

  if [[ -n $invalid_files ]]; then
    echo "❌ lib/ contains invalid file types (only .nix/.sh/.md allowed):"
    echo "$invalid_files"
    ((ERRORS++))
  fi
}

# Execute all validation checks
check_required_dirs
check_platform_separation
check_naming_conventions

# Report results
echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo "✅ All folder structure checks passed!"
  exit 0
else
  echo "⚠️  Found $ERRORS violation(s)"
  exit 1
fi
