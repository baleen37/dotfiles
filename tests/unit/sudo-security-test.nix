{ pkgs, lib, src, flake ? null }:

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

        # Check for new sudo management pattern with SUDO_PREFIX
        if grep -q "SUDO_PREFIX.*darwin-rebuild\|SUDO_PREFIX.*nixos-rebuild" "$script" && \
           grep -q "get_sudo_prefix()" "$script"; then
          echo "✅ PASS: $script_name uses proper sudo management pattern"
        # Also accept direct sudo usage for backward compatibility
        elif grep -q "sudo.*darwin-rebuild\|sudo.*nixos-rebuild" "$script"; then
          echo "✅ PASS: $script_name uses sudo for rebuild commands"
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

        # Look for the explain_sudo_requirement function or similar informative messages
        if grep -q "explain_sudo_requirement\|Administrator Privileges Required\|Administrator privileges acquired" "$script"; then
          echo "✅ PASS: $script_name has informative message before sudo"
        # Also check for legacy patterns
        elif grep -B5 -A5 "sudo.*darwin-rebuild\|sudo.*nixos-rebuild" "$script" | grep -q "Admin access\|admin access\|root access\|sudo"; then
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
pkgs.runCommand "sudo-security-test"
{
  buildInputs = [ pkgs.bash pkgs.gnugrep ];
} ''
  echo "Running sudo security tests..."
  ${testScript}

  echo "Sudo security test completed"
  touch $out
''
