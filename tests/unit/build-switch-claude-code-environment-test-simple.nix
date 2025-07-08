# Simplified Unit Test for Build-Switch Claude Code Environment
# Tests that basic Claude Code environment compatibility is working

{ pkgs, lib, src, flake ? null }:

let
  # Simple test for Claude Code environment basics
  testScript = pkgs.writeShellScript "test-claude-code-simple" ''
    set -euo pipefail

    echo "=== Simple Claude Code Environment Test ==="

    FAILED_TESTS=()

    # Test 1: Check if sudo management module exists
    echo "🔍 Testing sudo management module existence..."
    if [ -f ${src}/scripts/lib/sudo-management.sh ]; then
      echo "✅ PASS: Sudo management module exists"
    else
      echo "❌ FAIL: Sudo management module missing"
      FAILED_TESTS+=("sudo-module-missing")
    fi

    # Test 2: Check if build-switch scripts exist
    echo ""
    echo "🔍 Testing build-switch scripts..."
    if [ -f ${src}/apps/aarch64-darwin/build-switch ]; then
      echo "✅ PASS: Darwin build-switch script exists"
    else
      echo "❌ FAIL: Darwin build-switch script missing"
      FAILED_TESTS+=("darwin-script-missing")
    fi

    # Test 3: Check if common script exists
    echo ""
    echo "🔍 Testing common build script..."
    if [ -f ${src}/scripts/build-switch-common.sh ]; then
      echo "✅ PASS: Common build script exists"
    else
      echo "❌ FAIL: Common build script missing"
      FAILED_TESTS+=("common-script-missing")
    fi

    # Test 4: Check if home-manager backup is configured
    echo ""
    echo "🔍 Testing home-manager backup configuration..."
    if grep -q "backupFileExtension" ${src}/modules/darwin/home-manager.nix 2>/dev/null; then
      echo "✅ PASS: Home-manager backup configuration exists"
    else
      echo "❌ FAIL: Home-manager backup configuration missing"
      FAILED_TESTS+=("backup-config-missing")
    fi

    # Test 5: Check if non-interactive handling exists
    echo ""
    echo "🔍 Testing non-interactive environment handling..."
    if grep -q "non-interactive.*environment\|! -t 0" ${src}/scripts/lib/sudo-management.sh 2>/dev/null; then
      echo "✅ PASS: Non-interactive environment handling exists"
    else
      echo "❌ FAIL: Non-interactive environment handling missing"
      FAILED_TESTS+=("non-interactive-missing")
    fi

    echo ""
    echo "=== Test Results ==="
    if [ ''${#FAILED_TESTS[@]} -eq 0 ]; then
      echo "🎉 All basic Claude Code environment tests passed!"
      echo "✅ System is ready for Claude Code usage"
      exit 0
    else
      echo "❌ Failed tests: ''${FAILED_TESTS[*]}"
      echo "Issues found: ''${#FAILED_TESTS[@]}"
      exit 1
    fi
  '';

in
pkgs.runCommand "build-switch-claude-code-environment-test-simple"
{
  buildInputs = [ pkgs.bash pkgs.gnugrep pkgs.coreutils ];
} ''
  echo "Running simplified Claude Code environment tests..."
  ${testScript}

  echo "Simplified Claude Code environment test completed"
  touch $out
''
