# Unit Tests for Build Script Sudo Management Module
# Tests privilege management functions extracted from build-switch-common.sh

{ pkgs, ... }:

let
  # Test that sudo management functions exist and work correctly
  testSudoManagementModule = pkgs.runCommand "test-sudo-management-module" {
    buildInputs = [ pkgs.bash ];
  } ''
    # Test that we can source the sudo management module
    if [ -f ${../../scripts/lib/sudo-management.sh} ]; then
      echo "✅ Sudo management module exists"

      # Source the module
      source ${../../scripts/lib/sudo-management.sh}

      # Test that all expected functions exist
      if declare -f check_current_privileges > /dev/null; then
        echo "✅ check_current_privileges function exists"
      else
        echo "❌ check_current_privileges function missing"
        exit 1
      fi

      if declare -f acquire_sudo_early > /dev/null; then
        echo "✅ acquire_sudo_early function exists"
      else
        echo "❌ acquire_sudo_early function missing"
        exit 1
      fi

      if declare -f explain_sudo_requirement > /dev/null; then
        echo "✅ explain_sudo_requirement function exists"
      else
        echo "❌ explain_sudo_requirement function missing"
        exit 1
      fi

      if declare -f check_sudo_requirement > /dev/null; then
        echo "✅ check_sudo_requirement function exists"
      else
        echo "❌ check_sudo_requirement function missing"
        exit 1
      fi

      if declare -f get_sudo_prefix > /dev/null; then
        echo "✅ get_sudo_prefix function exists"
      else
        echo "❌ get_sudo_prefix function missing"
        exit 1
      fi

      if declare -f register_cleanup > /dev/null; then
        echo "✅ register_cleanup function exists"
      else
        echo "❌ register_cleanup function missing"
        exit 1
      fi

      if declare -f cleanup_sudo_session > /dev/null; then
        echo "✅ cleanup_sudo_session function exists"
      else
        echo "❌ cleanup_sudo_session function missing"
        exit 1
      fi

      # Test that sudo variables are defined
      if [ -n "$SUDO_REQUIRED" ] || [ "$SUDO_REQUIRED" = "false" ]; then
        echo "✅ SUDO_REQUIRED variable defined"
      else
        echo "❌ SUDO_REQUIRED variable missing"
        exit 1
      fi

      # Test sudo functions work
      echo "Testing sudo management functions..."
      check_current_privileges > /dev/null 2>&1 || true  # May fail in test env, that's ok
      check_sudo_requirement > /dev/null 2>&1

      # Test get_sudo_prefix returns something reasonable
      PREFIX=$(get_sudo_prefix)
      if [ "$PREFIX" = "sudo" ] || [ "$PREFIX" = "" ]; then
        echo "✅ get_sudo_prefix returns valid value: '$PREFIX'"
      else
        echo "❌ get_sudo_prefix returned unexpected value: '$PREFIX'"
        exit 1
      fi

      echo "✅ All sudo management tests passed"
    else
      echo "❌ Sudo management module does not exist yet - this test should fail initially"
      exit 1
    fi

    touch $out
  '';

in testSudoManagementModule
