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
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/nix-app-linker.sh"

# Test 1: First run should link apps (not show "No new apps")
output=$(link_nix_apps "$home_apps" "$nix_store" "$profile_dir" 2>&1)

if echo "$output" | grep -q "No new apps to link"; then
  echo "FAIL: First run should link apps, but got 'No new apps to link'"
  exit 1
else
  echo "PASS: First run correctly linked new apps"
fi

# Test 2: Second run should show "No new apps" (already linked)
output2=$(link_nix_apps "$home_apps" "$nix_store" "$profile_dir" 2>&1)

if echo "$output2" | grep -q "No new apps to link"; then
  echo "PASS: Second run correctly reports no new apps (idempotent)"
else
  echo "FAIL: Second run should show 'No new apps to link' but didn't"
  echo "Output was:"
  echo "$output2"
  exit 1
fi
