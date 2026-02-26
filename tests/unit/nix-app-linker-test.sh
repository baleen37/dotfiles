#!/usr/bin/env bash
# Test: nix-app-linker profile app linking counter tracks new apps correctly
#
# The find | while read pattern runs the while loop in a subshell,
# so counter modifications are invisible to the parent shell.
# This test verifies that new_apps counter works when apps ARE linked.
set -euo pipefail

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

profile_dir="$test_dir/profile"
home_apps="$test_dir/Applications"
nix_store="$test_dir/nix-store"

# Create fake profile with .app directories that will be found by the linker
mkdir -p "$profile_dir/share/Applications/TestApp1.app"
mkdir -p "$profile_dir/share/Applications/TestApp2.app"
mkdir -p "$home_apps"
mkdir -p "$nix_store"

# Source the function
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../lib/nix-app-linker.sh"

# Run and capture output
output=$(link_nix_apps "$home_apps" "$nix_store" "$profile_dir" 2>&1)

# The bug: "No new apps to link" is printed even when apps ARE linked
if echo "$output" | grep -q "No new apps to link"; then
  echo "FAIL: Bug reproduced - counter not tracking new apps"
  exit 1
else
  echo "PASS: Counter correctly tracks new apps"
fi
