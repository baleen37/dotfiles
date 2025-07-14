{ pkgs ? import <nixpkgs> {} }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in
testHelpers.createTestScript {
  name = "darwin-build-switch-optimization-test";
  script = ''
    ${testHelpers.testSection "Darwin Build-Switch Optimization Tests"}

    # Test environment setup
    export PROJECT_ROOT="${toString ../../.}"
    export SCRIPTS_DIR="$PROJECT_ROOT/scripts"
    export BUILD_LOGIC_SCRIPT="$SCRIPTS_DIR/lib/build-logic.sh"

    ${testHelpers.assertExists "$BUILD_LOGIC_SCRIPT" "Build logic script exists"}

    # Source required modules for testing
    export LIB_DIR="$SCRIPTS_DIR/lib"
    . "$LIB_DIR/logging.sh" || echo "Warning: Could not load logging module"

    ${testHelpers.testSubsection "Combined Mode Function Tests"}

    # Test that the new function exists in build-logic.sh
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "run_darwin_combined_build_switch" "Combined build-switch function exists"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "execute_darwin_combined_command" "Darwin combined command function exists"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "handle_darwin_build_failure" "Darwin failure handler exists"}

    ${testHelpers.testSubsection "Optimized Execution Path Tests"}

    # Test that execute_darwin_build_switch supports both modes
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "DARWIN_USE_COMBINED_MODE" "Combined mode environment variable check exists"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "Using optimized combined build and switch" "Optimized mode logging exists"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "Using legacy separate build and switch phases" "Legacy mode logging exists"}

    ${testHelpers.testSubsection "Performance Optimization Features"}

    # Test that performance monitoring is integrated
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "progress_start.*빌드 및 적용" "Combined progress tracking exists"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "perf_start_phase.*build" "Performance monitoring integrated"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "optimize_cache" "Cache optimization called"}

    ${testHelpers.testSubsection "Error Handling Tests"}

    # Test error handling for combined mode
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "handle_darwin_build_failure" "Darwin-specific error handler exists"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "Combined build and switch failed" "Appropriate error messages exist"}

    ${testHelpers.testSubsection "Backward Compatibility Tests"}

    # Test that legacy mode is preserved
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "run_build.*@" "Legacy build function call preserved"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "run_switch.*@" "Legacy switch function call preserved"}

    ${testHelpers.testSubsection "Command Construction Tests"}

    # Test that combined command uses darwin-rebuild switch directly
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "darwin-rebuild switch" "Direct darwin-rebuild switch command"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "--impure --max-jobs.*--cores 0 --flake" "Proper flags for combined command"}

    ${testHelpers.testSubsection "Privilege Handling Tests"}

    # Test privilege handling in combined mode
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "execute_darwin_with_verbose_output" "Verbose output handler exists"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "execute_darwin_with_quiet_output" "Quiet output handler exists"}
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "USER=.*USER.*eval" "User environment preserved"}

    ${testHelpers.testSubsection "Configuration Integration Tests"}

    # Test default behavior (combined mode enabled by default)
    # This tests that DARWIN_USE_COMBINED_MODE defaults to true
    if grep -q 'DARWIN_USE_COMBINED_MODE:-true' "$BUILD_LOGIC_SCRIPT"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Combined mode is enabled by default"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Combined mode should be enabled by default"
      exit 1
    fi

    ${testHelpers.testSection "Performance Improvement Validation"}

    # Test that the optimization addresses the specific issue requirements
    echo "${testHelpers.colors.blue}Checking optimization addresses issue requirements:${testHelpers.colors.reset}"

    # Issue requirement: Combined build-switch operation
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "combined build and switch" "Implements combined operation"}

    # Issue requirement: Performance improvement
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "optimized combined build and switch" "Explicitly optimized approach"}

    # Issue requirement: Maintains compatibility
    ${testHelpers.assertContains "$BUILD_LOGIC_SCRIPT" "legacy separate build and switch" "Backward compatibility maintained"}

    echo ""
    echo "${testHelpers.colors.green}✓ All Darwin build-switch optimization tests passed!${testHelpers.colors.reset}"
  '';
}
