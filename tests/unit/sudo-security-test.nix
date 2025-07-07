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

    # Check if common script and its modules have proper sudo patterns
    COMMON_SCRIPT="${src}/scripts/build-switch-common.sh"
    BUILD_LOGIC_MODULE="${src}/scripts/lib/build-logic.sh"
    SUDO_MODULE="${src}/scripts/lib/sudo-management.sh"
    if [[ -f "$COMMON_SCRIPT" ]] && [[ -f "$BUILD_LOGIC_MODULE" ]] && [[ -f "$SUDO_MODULE" ]]; then
      # Check for modular sudo management pattern
      if grep -q "sudo-management.sh" "$COMMON_SCRIPT" && \
         grep -q "build-logic.sh" "$COMMON_SCRIPT" && \
         (grep -q "SUDO_PREFIX.*darwin-rebuild\|SUDO_PREFIX.*nixos-rebuild" "$BUILD_LOGIC_MODULE" || \
          (grep -q "get_sudo_prefix()" "$SUDO_MODULE" && grep -q "SUDO_PREFIX=\$(get_sudo_prefix)" "$BUILD_LOGIC_MODULE")); then
        echo "✅ PASS: Common script uses modular sudo management pattern"

        # Mark all build-switch scripts as passing since they use the common script
        for script in ${src}/apps/*/build-switch; do
          if [[ -f "$script" ]]; then
            script_name=$(basename $(dirname "$script"))/$(basename "$script")
            if grep -q "build-switch-common.sh" "$script"; then
              echo "✅ PASS: $script_name sources common script with proper sudo management"
            else
              echo "❌ FAIL: $script_name doesn't source common script"
              FAILED_SCRIPTS+=("$script_name")
            fi
          fi
        done
      else
        echo "❌ FAIL: Common script doesn't use modular sudo management pattern"
        FAILED_SCRIPTS+=("build-switch-common.sh")
      fi
    else
      # Fall back to checking individual scripts
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
    fi

    # Test 3: Check for informative messages before sudo usage
    echo ""
    echo "🔍 Testing for user-friendly sudo messages..."

    # Check the common script and its modules for sudo management functions
    COMMON_SCRIPT="${src}/scripts/build-switch-common.sh"
    SUDO_MODULE="${src}/scripts/lib/sudo-management.sh"
    if [[ -f "$COMMON_SCRIPT" ]] && [[ -f "$SUDO_MODULE" ]]; then
      # Check if common script sources the sudo management module
      if grep -q "sudo-management.sh" "$COMMON_SCRIPT" && \
         grep -q "explain_sudo_requirement\|Administrator Privileges Required" "$SUDO_MODULE"; then
        echo "✅ PASS: Common script sources sudo module with explain_sudo_requirement function"

        # Verify that the function is called in the sudo module
        if grep -q "check_sudo_requirement" "$SUDO_MODULE" && grep -A20 "check_sudo_requirement" "$SUDO_MODULE" | grep -q "explain_sudo_requirement"; then
          echo "✅ PASS: explain_sudo_requirement is called in check_sudo_requirement"

          # Mark all build-switch scripts as passing since they use the common script
          for script in ${src}/apps/*/build-switch; do
            if [[ -f "$script" ]]; then
              script_name=$(basename $(dirname "$script"))/$(basename "$script")
              if grep -q "build-switch-common.sh" "$script"; then
                echo "✅ PASS: $script_name sources common script with sudo messages"
              else
                echo "⚠️  WARN: $script_name doesn't source common script"
              fi
            fi
          done
        else
          echo "❌ FAIL: explain_sudo_requirement is not called properly in sudo module"
          FAILED_SCRIPTS+=("sudo-management.sh")
        fi
      else
        echo "❌ FAIL: Common script doesn't source sudo module or module lacks explanation messages"
        FAILED_SCRIPTS+=("build-switch-common.sh")
      fi
    else
      # Fall back to checking individual scripts
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
    fi

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
