# Enhanced unit tests for lib/error-handling.nix
# Tests new standardized error processing and enhanced error capabilities

{ pkgs ? import <nixpkgs> {}, flake ? null, src ? ../.. }:

let
  # Import the module we're testing (will fail initially - TDD Red phase)
  errorHandling = import ../../lib/error-handling.nix { inherit pkgs; };

  # Pre-computed test values for new error scenarios
  testError = {
    message = "Test error occurred";
    component = "test-module";
    errorType = "validation";
  };

  # Pre-compute test results
  createdError = errorHandling.createError testError;
  formattedError = errorHandling.formatError createdError;
  criticalError = errorHandling.createError (testError // { severity = "critical"; });
  warningError = errorHandling.createError (testError // { severity = "warning"; });
  buildError = errorHandling.categorizeError "build" "Build failed" {};
  configError = errorHandling.categorizeError "config" "Invalid configuration" {};
  errorWithContext = errorHandling.addContext createdError { filepath = "/test/path"; };
  errorWithSuggestion = errorHandling.addSuggestion createdError "Try restarting the service";
  logOutput = errorHandling.logError createdError;
  successResult = errorHandling.tryWithFallback (x: x + 1) 5 "fallback";
  error1 = errorHandling.createError { message = "First error"; component = "comp1"; errorType = "build"; };
  error2 = errorHandling.createError { message = "Second error"; component = "comp2"; errorType = "config"; };
  chainedErrors = errorHandling.chainErrors [error1 error2];

in
pkgs.runCommand "error-handling-enhanced-unit-tests" { } ''
  # Test 1: Enhanced error creation and formatting
  echo "Testing enhanced error creation..."

  # Test createError function with new features
  ${if createdError != null then "echo 'PASS: createError produces output'" else "exit 1"}

  # Test formatError function
  ${if builtins.isString formattedError then "echo 'PASS: formatError returns string'" else "exit 1"}

  # Test 2: Error severity levels with enhanced categorization
  echo "Testing error severity levels..."

  # Test different severity levels
  ${if criticalError.severity == "critical" then "echo 'PASS: Critical severity set correctly'" else "exit 1"}
  ${if warningError.severity == "warning" then "echo 'PASS: Warning severity set correctly'" else "exit 1"}

  # Test 3: Enhanced error categorization
  echo "Testing error categorization..."

  # Test error types with new categorizeError function
  ${if buildError.errorType == "build" then "echo 'PASS: Build error categorized correctly'" else "exit 1"}
  ${if configError.errorType == "config" then "echo 'PASS: Config error categorized correctly'" else "exit 1"}

  # Test 4: Error context and suggestions
  echo "Testing error context and suggestions..."

  # Test addContext function
  ${if errorWithContext.context.filepath == "/test/path" then "echo 'PASS: Context added correctly'" else "exit 1"}

  # Test addSuggestion function
  ${if builtins.elem "Try restarting the service" errorWithSuggestion.suggestions then "echo 'PASS: Suggestion added correctly'" else "exit 1"}

  # Test 5: Error logging and output
  echo "Testing error logging..."

  # Test logError function (should return formatted string)
  ${if builtins.isString logOutput then "echo 'PASS: logError produces string output'" else "exit 1"}

  # Test 6: Error recovery mechanisms
  echo "Testing error recovery..."

  # Test tryWithFallback function
  ${if successResult == 6 then "echo 'PASS: tryWithFallback succeeds correctly'" else "exit 1"}

  # Test 7: Error chaining and aggregation
  echo "Testing error chaining..."

  # Test chainErrors function

  ${if builtins.length chainedErrors == 2 then "echo 'PASS: Error chaining works correctly'" else "exit 1"}

  echo "All enhanced error handling tests passed!"
  touch $out
''
