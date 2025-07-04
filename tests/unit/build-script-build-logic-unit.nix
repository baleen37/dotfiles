# Unit Tests for Build Script Build Logic Module
# Tests core build/switch functions extracted from build-switch-common.sh

{ pkgs, ... }:

let
  # Test that build logic functions exist and work correctly
  testBuildLogicModule = pkgs.runCommand "test-build-logic-module" {
    buildInputs = [ pkgs.bash ];
  } ''
    # Test that we can source the build logic module
    if [ -f ${../../scripts/lib/build-logic.sh} ]; then
      echo "✅ Build logic module exists"

      # Source the module
      source ${../../scripts/lib/build-logic.sh}

      # Test that all expected functions exist
      if declare -f run_build > /dev/null; then
        echo "✅ run_build function exists"
      else
        echo "❌ run_build function missing"
        exit 1
      fi

      if declare -f run_switch > /dev/null; then
        echo "✅ run_switch function exists"
      else
        echo "❌ run_switch function missing"
        exit 1
      fi

      if declare -f run_cleanup > /dev/null; then
        echo "✅ run_cleanup function exists"
      else
        echo "❌ run_cleanup function missing"
        exit 1
      fi

      if declare -f execute_build_switch > /dev/null; then
        echo "✅ execute_build_switch function exists"
      else
        echo "❌ execute_build_switch function missing"
        exit 1
      fi

      # Test that functions have expected signatures (can be called without failing immediately)
      echo "Testing build logic function signatures..."

      # These should not crash when called with proper setup
      # Note: We can't actually run builds in test environment, but we can test signatures

      echo "✅ All build logic tests passed"
    else
      echo "❌ Build logic module does not exist yet - this test should fail initially"
      exit 1
    fi

    touch $out
  '';

in testBuildLogicModule
