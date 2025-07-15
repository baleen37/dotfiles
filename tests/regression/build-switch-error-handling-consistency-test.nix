{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildLogicScript = "${src}/scripts/lib/build-logic.sh";
in
pkgs.runCommand "build-switch-error-handling-consistency-regression-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Error Handling Consistency Regression Tests"}

  # Test 1: Document current inconsistent error handling patterns
  ${testHelpers.testSubsection "Error Handling Pattern Inconsistencies"}

  # Create a clean test environment
  mkdir -p test_workspace
  cd test_workspace

  # Copy the build-logic script to test workspace
  cp "${buildLogicScript}" ./build-logic-test.sh
  chmod +x ./build-logic-test.sh

  # Test 2: Check for inconsistent exit strategies
  ${testHelpers.testSubsection "Exit Strategy Inconsistencies"}

  # Count different error handling patterns
  RETURN_1_COUNT=$(grep -c "return 1" ./build-logic-test.sh)
  EXIT_1_COUNT=$(grep -c "exit 1" ./build-logic-test.sh)

  echo "Found error handling patterns:"
  echo "- 'return 1' patterns: $RETURN_1_COUNT"
  echo "- 'exit 1' patterns: $EXIT_1_COUNT"

  # Test for the current inconsistency (should be fixed)
  if [ "$RETURN_1_COUNT" -gt 0 ] && [ "$EXIT_1_COUNT" -gt 0 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Bug reproduced: Mixed exit strategies found (return 1: $RETURN_1_COUNT, exit 1: $EXIT_1_COUNT)"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Pattern may have changed: return 1: $RETURN_1_COUNT, exit 1: $EXIT_1_COUNT"
  fi

  # Test 3: Check for generic error messages lacking context
  ${testHelpers.testSubsection "Generic Error Messages"}

  # Find generic error messages that could be more descriptive
  GENERIC_FAILED_COUNT=$(grep -c "failed\"" ./build-logic-test.sh)
  SPECIFIC_ERROR_COUNT=$(grep -c "log_error.*failed (exit code:" ./build-logic-test.sh)

  echo "Error message analysis:"
  echo "- Generic 'failed' messages: $GENERIC_FAILED_COUNT"
  echo "- Specific error messages with exit codes: $SPECIFIC_ERROR_COUNT"

  if [ "$GENERIC_FAILED_COUNT" -gt "$SPECIFIC_ERROR_COUNT" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Bug reproduced: More generic than specific error messages"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Error messaging may have improved"
  fi

  # Test 4: Check for missing error recovery patterns
  ${testHelpers.testSubsection "Error Recovery Mechanisms"}

  # Look for any retry or recovery patterns
  RETRY_COUNT=$(grep -c "retry\|recover\|fallback" ./build-logic-test.sh)
  TOTAL_ERROR_COUNT=$(grep -c "log_error" ./build-logic-test.sh)

  echo "Error recovery analysis:"
  echo "- Total error cases: $TOTAL_ERROR_COUNT"
  echo "- Recovery/retry mechanisms: $RETRY_COUNT"

  if [ "$RETRY_COUNT" -lt 3 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Bug reproduced: Limited error recovery mechanisms ($RETRY_COUNT found)"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Error recovery may have been improved"
  fi

  # Test 5: Document expected improvements
  ${testHelpers.testSubsection "Expected Error Handling Improvements"}

  echo "${testHelpers.colors.blue}Expected improvements after Phase 1.3:${testHelpers.colors.reset}"
  echo "1. Consistent error handling patterns (prefer 'return 1' over 'exit 1' in functions)"
  echo "2. More descriptive error messages with context and timestamps"
  echo "3. Basic error recovery mechanisms for common failure scenarios"
  echo "4. Categorized error handling (recoverable vs fatal errors)"
  echo "5. Improved error propagation through the call stack"

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Error Handling Consistency Regression Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ Successfully documented current error handling inconsistencies!${testHelpers.colors.reset}"
  echo "${testHelpers.colors.yellow}⚠ Phase 1.3 improvements needed for consistent and robust error handling${testHelpers.colors.reset}"

  touch $out
''
