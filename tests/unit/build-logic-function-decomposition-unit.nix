{ lib, pkgs }:

let
  # Import test utilities
  testUtils = import ../lib/test-helpers.nix { inherit pkgs; };

  # Test configuration for build-logic.sh function decomposition
  testConfig = {
    # Target file for refactoring
    targetFile = "scripts/lib/build-logic.sh";

    # Complex function to be decomposed
    complexFunction = "execute_build_switch";
    currentLines = 112; # Current line count of the function
    targetLines = 30;   # Target maximum lines per function

    # Expected decomposed functions after refactoring
    expectedFunctions = [
      "execute_build_switch"           # Main orchestrator (< 30 lines)
      "prepare_build_environment"     # Environment setup
      "execute_platform_build"        # Platform-specific build logic
      "handle_build_completion"       # Post-build cleanup and reporting
      "setup_build_monitoring"        # Performance and progress monitoring
    ];

    # Expected improvements
    expectedImprovements = {
      maxFunctionLines = 30;
      reducedComplexity = true;
      improvedTestability = true;
      betterErrorHandling = true;
      eliminatedDuplication = true;
    };
  };

in

{
  # Test 1: Current function is too complex (Red phase - should fail initially)
  test_current_function_too_complex = testUtils.createTestScript {
    name = "current-function-too-complex";
    script = ''
      # Count lines in execute_build_switch function
      FUNCTION_LINES=$(sed -n '/^execute_build_switch()/,/^}/p' scripts/lib/build-logic.sh | wc -l)

      # Test should fail initially (function is too long)
      if [ "$FUNCTION_LINES" -le 30 ]; then
        echo "FAIL: Function is already small enough ($FUNCTION_LINES lines)"
        exit 1
      fi

      echo "PASS: Function is too complex ($FUNCTION_LINES lines > 30), needs decomposition"
    '';
  };

  # Test 2: Decomposed functions should exist after refactoring
  test_decomposed_functions_exist = testUtils.createTestScript {
    name = "decomposed-functions-exist";
    script = ''
      # Check that all expected decomposed functions exist
      MISSING_FUNCTIONS=""

      for func in prepare_build_environment execute_platform_build handle_build_completion setup_build_monitoring; do
        if ! grep -q "^$func()" scripts/lib/build-logic.sh; then
          MISSING_FUNCTIONS="$MISSING_FUNCTIONS $func"
        fi
      done

      if [ -n "$MISSING_FUNCTIONS" ]; then
        echo "FAIL: Missing decomposed functions:$MISSING_FUNCTIONS"
        exit 1
      fi

      echo "PASS: All decomposed functions exist"
    '';
  };

  # Test 3: Main orchestrator function should be simplified
  test_main_orchestrator_simplified = testUtils.createTestScript {
    name = "main-orchestrator-simplified";
    script = ''
      # Count lines in main execute_build_switch function after refactoring
      MAIN_FUNCTION_LINES=$(sed -n '/^execute_build_switch()/,/^}/p' scripts/lib/build-logic.sh | wc -l)

      if [ "$MAIN_FUNCTION_LINES" -gt 30 ]; then
        echo "FAIL: Main orchestrator still too complex ($MAIN_FUNCTION_LINES lines > 30)"
        exit 1
      fi

      echo "PASS: Main orchestrator simplified ($MAIN_FUNCTION_LINES lines <= 30)"
    '';
  };

  # Test 4: Duplicated error handling should be eliminated
  test_duplicated_error_handling_eliminated = testUtils.createTestScript {
    name = "duplicated-error-handling-eliminated";
    script = ''
      # Count occurrences of duplicated error handling patterns
      PROGRESS_STOP_COUNT=$(grep -c "progress_stop" scripts/lib/build-logic.sh)
      LOG_ERROR_BUILD_COUNT=$(grep -c "log_error.*Build.*failed" scripts/lib/build-logic.sh)
      LOG_FOOTER_FAILED_COUNT=$(grep -c "log_footer.*failed" scripts/lib/build-logic.sh)

      # After refactoring, these should be centralized
      if [ "$PROGRESS_STOP_COUNT" -gt 3 ] || [ "$LOG_ERROR_BUILD_COUNT" -gt 2 ] || [ "$LOG_FOOTER_FAILED_COUNT" -gt 2 ]; then
        echo "FAIL: Error handling still duplicated (progress_stop: $PROGRESS_STOP_COUNT, log_error: $LOG_ERROR_BUILD_COUNT, log_footer: $LOG_FOOTER_FAILED_COUNT)"
        exit 1
      fi

      echo "PASS: Error handling properly centralized"
    '';
  };

  # Test 5: Platform-specific logic should be separated
  test_platform_logic_separated = testUtils.createTestScript {
    name = "platform-logic-separated";
    script = ''
      # Check that platform-specific logic is properly separated
      if ! grep -q "execute_platform_build" scripts/lib/build-logic.sh; then
        echo "FAIL: Platform-specific logic not separated into execute_platform_build function"
        exit 1
      fi

      # Check that the main function doesn't have large platform-specific blocks
      DARWIN_BLOCKS=$(sed -n '/^execute_build_switch()/,/^}/p' scripts/lib/build-logic.sh | grep -c "if.*PLATFORM_TYPE.*darwin")

      if [ "$DARWIN_BLOCKS" -gt 1 ]; then
        echo "FAIL: Platform-specific logic still embedded in main function ($DARWIN_BLOCKS darwin blocks)"
        exit 1
      fi

      echo "PASS: Platform-specific logic properly separated"
    '';
  };

  # Test 6: Environment setup should be modularized
  test_environment_setup_modularized = testUtils.createTestScript {
    name = "environment-setup-modularized";
    script = ''
      # Check that environment setup is extracted to its own function
      if ! grep -q "prepare_build_environment" scripts/lib/build-logic.sh; then
        echo "FAIL: Environment setup not modularized"
        exit 1
      fi

      # Check that the main function calls the setup function
      if ! sed -n '/^execute_build_switch()/,/^}/p' scripts/lib/build-logic.sh | grep -q "prepare_build_environment"; then
        echo "FAIL: Main function doesn't call prepare_build_environment"
        exit 1
      fi

      echo "PASS: Environment setup properly modularized"
    '';
  };

  # Test 7: Build completion handling should be centralized
  test_build_completion_centralized = testUtils.createTestScript {
    name = "build-completion-centralized";
    script = ''
      # Check that build completion handling is extracted
      if ! grep -q "handle_build_completion" scripts/lib/build-logic.sh; then
        echo "FAIL: Build completion handling not centralized"
        exit 1
      fi

      # Check for reduced complexity in completion logic
      CLEANUP_PATTERNS=$(grep -c "run_cleanup\|perf_show_summary\|log_footer\|cleanup_sudo_session" scripts/lib/build-logic.sh)

      # After refactoring, these should be centralized in handle_build_completion
      if [ "$CLEANUP_PATTERNS" -gt 8 ]; then  # Allow some patterns but not excessive duplication
        echo "FAIL: Build completion logic still scattered ($CLEANUP_PATTERNS patterns)"
        exit 1
      fi

      echo "PASS: Build completion properly centralized"
    '';
  };

  # Test 8: Monitoring setup should be extracted
  test_monitoring_setup_extracted = testUtils.createTestScript {
    name = "monitoring-setup-extracted";
    script = ''
      # Check that monitoring setup is extracted
      if ! grep -q "setup_build_monitoring" scripts/lib/build-logic.sh; then
        echo "FAIL: Monitoring setup not extracted"
        exit 1
      fi

      # Check that monitoring calls are centralized
      PERF_INIT_COUNT=$(grep -c "perf_start_total\|progress_init" scripts/lib/build-logic.sh)

      if [ "$PERF_INIT_COUNT" -gt 4 ]; then  # Should be centralized
        echo "FAIL: Monitoring initialization still scattered ($PERF_INIT_COUNT patterns)"
        exit 1
      fi

      echo "PASS: Monitoring setup properly extracted"
    '';
  };

  # Test 9: Function complexity should be reduced overall
  test_overall_complexity_reduced = testUtils.createTestScript {
    name = "overall-complexity-reduced";
    script = ''
      # Count total lines in all functions (excluding comments and blank lines)
      TOTAL_FUNCTION_LINES=$(grep -v '^#\|^$' scripts/lib/build-logic.sh | wc -l)

      # Check that no single function exceeds the complexity limit
      MAX_FUNCTION_SIZE=0

      for func in execute_build_switch prepare_build_environment execute_platform_build handle_build_completion setup_build_monitoring; do
        if grep -q "^$func()" scripts/lib/build-logic.sh; then
          FUNC_SIZE=$(sed -n "/^$func()/,/^}/p" scripts/lib/build-logic.sh | wc -l)
          if [ "$FUNC_SIZE" -gt "$MAX_FUNCTION_SIZE" ]; then
            MAX_FUNCTION_SIZE=$FUNC_SIZE
          fi
        fi
      done

      if [ "$MAX_FUNCTION_SIZE" -gt 40 ]; then  # Allow some flexibility but enforce reasonable limits
        echo "FAIL: Functions still too complex (max size: $MAX_FUNCTION_SIZE lines)"
        exit 1
      fi

      echo "PASS: Overall complexity reduced (max function size: $MAX_FUNCTION_SIZE lines)"
    '';
  };

  # Test 10: Code reusability should be improved
  test_code_reusability_improved = testUtils.createTestScript {
    name = "code-reusability-improved";
    script = ''
      # Check that common patterns are extracted to reusable functions

      # Check for reduced duplication in build command construction
      BUILD_CMD_PATTERNS=$(grep -c "OPTIMIZED.*CMD" scripts/lib/build-logic.sh)

      # After refactoring, command construction should be more centralized
      if [ "$BUILD_CMD_PATTERNS" -gt 6 ]; then
        echo "FAIL: Build command construction still duplicated ($BUILD_CMD_PATTERNS patterns)"
        exit 1
      fi

      # Check for extracted common utilities
      if ! grep -q -E "(build_command_for_platform|execute_with_sudo_if_needed)" scripts/lib/build-logic.sh; then
        echo "WARN: Consider extracting common utilities for better reusability"
      fi

      echo "PASS: Code reusability improved"
    '';
  };

  # Test configuration: Now expected to pass (Green + Refactor phase complete)
  expectedPasses = [
    "decomposed-functions-exist"
    "main-orchestrator-simplified"
    "duplicated-error-handling-eliminated"
    "platform-logic-separated"
    "environment-setup-modularized"
    "build-completion-centralized"
    "monitoring-setup-extracted"
    "overall-complexity-reduced"
    "code-reusability-improved"
  ];

  # This test should now fail (function is no longer too complex)
  expectedFailures = [
    "current-function-too-complex"  # Should fail now - function is simplified
  ];

  # Refactoring objectives
  refactoringObjectives = {
    description = "Decompose complex execute_build_switch function into smaller, focused functions";
    benefits = [
      "Improved readability and maintainability"
      "Better testability of individual components"
      "Reduced code duplication"
      "Clearer separation of concerns"
      "Enhanced error handling consistency"
    ];
    targets = {
      maxFunctionLines = 30;
      eliminateDuplication = true;
      improveModularity = true;
      enhanceTestability = true;
    };
  };
}
