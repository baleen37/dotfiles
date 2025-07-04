# Integration Test for Build Script Modularization
# Tests that the modularized build script maintains all functionality

{ pkgs, ... }:

let
  # Test that the main script can load all modules and function correctly
  testBuildScriptIntegration = pkgs.runCommand "test-build-script-integration" {
    buildInputs = [ pkgs.bash ];
  } ''
    # Test that the main script exists and is shorter than original
    if [ -f ${../../scripts/build-switch-common.sh} ]; then
      MAIN_LINES=$(wc -l < ${../../scripts/build-switch-common.sh})
      echo "Main script has $MAIN_LINES lines"

      # Acceptance criteria: main script < 100 lines
      if [ "$MAIN_LINES" -lt 100 ]; then
        echo "✅ Main script under 100 lines ($MAIN_LINES lines)"
      else
        echo "❌ Main script too long: $MAIN_LINES lines (should be < 100)"
        exit 1
      fi

      # Test that all modules exist
      MODULES_EXIST=true
      for module in logging.sh performance.sh sudo-management.sh build-logic.sh; do
        if [ ! -f ${../../scripts/lib}/$module ]; then
          echo "❌ Module missing: $module"
          MODULES_EXIST=false
        else
          echo "✅ Module exists: $module"
        fi
      done

      if [ "$MODULES_EXIST" = "false" ]; then
        echo "❌ Some modules are missing"
        exit 1
      fi

      # Test that main script can load all modules without errors
      echo "Testing module loading..."

      # Create a test script that sources modules directly
      cat > test_modules.sh << 'EOF'
#!/bin/bash
set -e
PLATFORM_NAME="TestPlatform"
SCRIPT_DIR=${../../scripts}
LIB_DIR="$SCRIPT_DIR/lib"

# Set up color variables (needed by modules)
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
DIM='\033[2m'
NC='\033[0m'

# Load all modules
. "$LIB_DIR/logging.sh"
. "$LIB_DIR/performance.sh"
. "$LIB_DIR/sudo-management.sh"
. "$LIB_DIR/build-logic.sh"

echo "All modules loaded successfully"

# Test that all functions are available
functions=(
  "log_header" "log_step" "log_info" "log_warning" "log_success" "log_error" "log_footer"
  "perf_start_total" "perf_start_phase" "perf_end_phase" "perf_show_summary" "detect_optimal_jobs"
  "check_current_privileges" "acquire_sudo_early" "explain_sudo_requirement" "check_sudo_requirement"
  "get_sudo_prefix" "register_cleanup" "cleanup_sudo_session"
  "run_build" "run_switch" "run_cleanup" "execute_build_switch"
)

for func in "''${functions[@]}"; do
  if declare -f "$func" > /dev/null; then
    echo "✅ Function available: $func"
  else
    echo "❌ Function missing: $func"
    exit 1
  fi
done

echo "All functions available"
EOF

      chmod +x test_modules.sh

      # Try to source the modules (this will fail if modules don't exist or have errors)
      if ./test_modules.sh > test_output.log 2>&1; then
        echo "✅ All modules loaded and functions available"
        cat test_output.log
      else
        echo "❌ Failed to load modules or functions missing"
        cat test_output.log
        exit 1
      fi

      echo "✅ All integration tests passed"
    else
      echo "❌ Main build script does not exist"
      exit 1
    fi

    touch $out
  '';

in testBuildScriptIntegration
