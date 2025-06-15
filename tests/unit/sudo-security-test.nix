{ pkgs, lib, src }:

let
  # Test for sudo security issues in build-switch scripts
  testScript = pkgs.writeShellScript "test-sudo-security" ''
    set -euo pipefail

    echo "=== Testing sudo security in build-switch scripts ==="

    # Test 1: Check that scripts don't use 'sudo -v' (pre-validation)
    echo "🔍 Testing for sudo -v usage..."

    FAILED_SCRIPTS=()

    for script in ${src}/apps/*/build-switch; do
      if [[ -f "$script" ]]; then
        script_name=$(basename $(dirname "$script"))/$(basename "$script")
        echo "Checking $script_name..."

        # This should FAIL initially - we expect to find 'sudo -v'
        if grep -q "sudo -v" "$script"; then
          echo "❌ FAIL: $script_name uses insecure 'sudo -v'"
          FAILED_SCRIPTS+=("$script_name")
        else
          echo "✅ PASS: $script_name doesn't use 'sudo -v'"
        fi
      fi
    done

    # Test 2: Check for proper sudo usage with specific commands only
    echo ""
    echo "🔍 Testing for proper sudo usage..."

    for script in ${src}/apps/*/build-switch; do
      if [[ -f "$script" ]]; then
        script_name=$(basename $(dirname "$script"))/$(basename "$script")

        # Should only use sudo with specific commands, not pre-validation
        if grep -q "sudo.*darwin-rebuild\|sudo.*nixos-rebuild" "$script"; then
          echo "✅ PASS: $script_name uses sudo only for specific rebuild commands"
        else
          echo "❌ FAIL: $script_name doesn't use sudo for rebuild commands"
          FAILED_SCRIPTS+=("$script_name")
        fi
      fi
    done

    # Test 3: Check for informative messages before sudo usage
    echo ""
    echo "🔍 Testing for user-friendly sudo messages..."

    for script in ${src}/apps/*/build-switch; do
      if [[ -f "$script" ]]; then
        script_name=$(basename $(dirname "$script"))/$(basename "$script")

        # Look for informative message before sudo usage
        if grep -B5 -A5 "sudo.*darwin-rebuild\|sudo.*nixos-rebuild" "$script" | grep -q "Admin access\|admin access\|root access\|sudo"; then
          echo "✅ PASS: $script_name has informative message before sudo"
        else
          echo "⚠️  WARN: $script_name should have informative message before sudo"
        fi
      fi
    done

    echo ""
    echo "=== Test Results ==="
    if [[ ''${#FAILED_SCRIPTS[@]} -gt 0 ]]; then
      echo "❌ FAILED SCRIPTS: ''${FAILED_SCRIPTS[*]}"
      echo "Security issues found in build-switch scripts!"
      exit 1
    else
      echo "✅ All sudo security tests passed!"
      exit 0
    fi
  '';

in
pkgs.runCommand "sudo-security-test" {
  buildInputs = [ pkgs.bash pkgs.gnugrep ];
} ''
  echo "Running sudo security tests..."
  ${testScript}

  echo "Sudo security test completed"
  touch $out
''
