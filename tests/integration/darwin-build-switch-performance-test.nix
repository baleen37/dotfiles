{ pkgs ? import <nixpkgs> {} }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in
testHelpers.createTestScript {
  name = "darwin-build-switch-performance-test";
  script = ''
    ${testHelpers.testSection "Darwin Build-Switch Performance Integration Tests"}

    # Only run on Darwin systems
    ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Only applicable to Darwin systems" ''

      # Test environment setup
      export PROJECT_ROOT="${toString ../../.}"
      export SCRIPTS_DIR="$PROJECT_ROOT/scripts"

      ${testHelpers.testSubsection "Environment Variable Configuration Tests"}

      # Test default combined mode behavior
      unset DARWIN_USE_COMBINED_MODE
      export SYSTEM_TYPE="test-darwin"
      export PLATFORM_TYPE="darwin"
      export USER="testuser"
      export REBUILD_COMMAND_PATH="echo darwin-rebuild"
      export SUDO_REQUIRED="false"
      export VERBOSE="false"

      # Source required modules
      export LIB_DIR="$SCRIPTS_DIR/lib"
      . "$LIB_DIR/logging.sh"
      . "$LIB_DIR/performance.sh"
      . "$LIB_DIR/progress.sh"
      . "$LIB_DIR/optimization.sh"
      . "$LIB_DIR/sudo-management.sh"
      . "$LIB_DIR/cache-management.sh"
      . "$LIB_DIR/build-logic.sh"

      ${testHelpers.testSubsection "Combined Mode Execution Path Tests"}

      # Mock the performance and progress functions for testing
      perf_start_phase() { echo "perf_start_phase: $1"; }
      perf_end_phase() { echo "perf_end_phase: $1"; }
      log_step() { echo "log_step: $*"; }
      log_info() { echo "log_info: $*"; }
      log_success() { echo "log_success: $*"; }
      log_debug() { echo "log_debug: $*"; }
      log_error() { echo "log_error: $*"; }
      progress_start() { echo "progress_start: $*"; }
      progress_stop() { echo "progress_stop"; }
      progress_complete() { echo "progress_complete: $*"; }
      optimize_cache() { echo "optimize_cache: $1"; }
      get_sudo_prefix() { echo ""; }
      detect_optimal_jobs() { echo "4"; }
      progress_estimate_time() { echo "30s"; }
      update_post_build_stats() { echo "update_post_build_stats: $*"; }
      get_optimized_nix_command() { echo "$1"; }

      ${testHelpers.testSubsection "Combined Mode Function Execution Test"}

      # Test that combined mode function exists and can be called
      if declare -f run_darwin_combined_build_switch > /dev/null; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} run_darwin_combined_build_switch function is available"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} run_darwin_combined_build_switch function not found"
        exit 1
      fi

      ${testHelpers.testSubsection "Mode Selection Logic Test"}

      # Test default behavior (should use combined mode)
      export DARWIN_USE_COMBINED_MODE=""  # Test default
      if execute_darwin_build_switch --dry-run 2>&1 | grep -q "optimized combined"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Default mode uses optimized combined build-switch"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Default mode should use optimized combined build-switch"
        exit 1
      fi

      # Test legacy mode explicitly
      export DARWIN_USE_COMBINED_MODE="false"
      if execute_darwin_build_switch --dry-run 2>&1 | grep -q "legacy separate"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Legacy mode works when explicitly enabled"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Legacy mode should work when explicitly enabled"
        exit 1
      fi

      # Test combined mode explicitly
      export DARWIN_USE_COMBINED_MODE="true"
      if execute_darwin_build_switch --dry-run 2>&1 | grep -q "optimized combined"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Combined mode works when explicitly enabled"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Combined mode should work when explicitly enabled"
        exit 1
      fi

      ${testHelpers.testSubsection "Performance Monitoring Integration Test"}

      # Test that performance monitoring is properly integrated
      export DARWIN_USE_COMBINED_MODE="true"
      OUTPUT=$(execute_darwin_build_switch --dry-run 2>&1)

      if echo "$OUTPUT" | grep -q "perf_start_phase: build"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Performance monitoring starts properly"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Performance monitoring should start"
        exit 1
      fi

      if echo "$OUTPUT" | grep -q "progress_start.*빌드 및 적용"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Progress tracking starts properly"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Progress tracking should start"
        exit 1
      fi

      ${testHelpers.testSubsection "Command Optimization Test"}

      # Test that the darwin-rebuild switch command is used directly
      if echo "$OUTPUT" | grep -q "darwin-rebuild.*switch"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Uses darwin-rebuild switch directly"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Should use darwin-rebuild switch directly"
        exit 1
      fi

      ${testHelpers.testSubsection "Resource Optimization Test"}

      # Test that optimal job count is detected and used
      if echo "$OUTPUT" | grep -q "Using 4 parallel jobs"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Optimal job count is used"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Should use optimal job count"
        exit 1
      fi

      # Test that cache optimization is called
      if echo "$OUTPUT" | grep -q "optimize_cache"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache optimization is performed"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Should perform cache optimization"
        exit 1
      fi

      echo ""
      echo "${testHelpers.colors.green}✓ All Darwin build-switch performance integration tests passed!${testHelpers.colors.reset}"
    ''}
  '';
}
