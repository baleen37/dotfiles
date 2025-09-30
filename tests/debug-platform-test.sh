#!/usr/bin/env bash
# Debug platform test

set -x  # Enable debug output
set -euo pipefail

echo "=== Starting debug test ==="
echo "PWD: $(pwd)"
echo "Script location: $(dirname "${BASH_SOURCE[0]}")"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
echo "PROJECT_ROOT: $PROJECT_ROOT"

# Change to project root
cd "$PROJECT_ROOT"
echo "Changed to: $(pwd)"

# Test 1: Basic nix command
echo "=== Test 1: Basic nix command ==="
nix --version

# Test 2: Basic eval
echo "=== Test 2: Basic eval ==="
nix eval --impure --expr 'builtins.currentSystem' --raw

# Test 3: Import platform-system
echo "=== Test 3: Import platform-system ==="
nix eval --impure --expr 'builtins.trace "Starting platform-system import" (import ./lib/platform-system.nix { system = builtins.currentSystem; })' --apply 'x: "imported"'

# Test 4: Get system value
echo "=== Test 4: Get system value ==="
nix eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).system' --raw

echo "=== All tests completed ==="
