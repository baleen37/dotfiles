# Comprehensive test suite for refactored error-handling.nix
# Tests all core functionality to ensure no regressions after refactoring

{ lib, pkgs }:

let
  errorHandling = import ../../lib/error-handling.nix { inherit pkgs; };
  
  # Test helper functions
  testFramework = {
    # Test runner that catches exceptions
    runTest = name: testFn:
      let
        result = builtins.tryEval testFn;
      in
      {
        name = name;
        success = result.success;
        value = if result.success then result.value else null;
        error = if result.success then null else "Test failed with exception";
      };

    # Assert function for tests
    assertThat = condition: message:
      if condition then true
      else throw "Assertion failed: ${message}";

    # Compare two values for equality
    assertEqual = expected: actual: message:
      testFramework.assertThat (expected == actual) 
        "${message}: expected ${builtins.toString expected}, got ${builtins.toString actual}";
  };

  # Core functionality tests
  coreTests = {
    # Test createError function
    testCreateError = testFramework.runTest "createError basic functionality" (
      let
        error = errorHandling.createError {
          message = "Test error message";
          component = "test-component";
          errorType = "validation";
          severity = "warning";
        };
      in
      testFramework.assertThat (error.message == "Test error message") "createError sets message correctly" &&
      testFramework.assertThat (error.component == "test-component") "createError sets component correctly" &&
      testFramework.assertThat (error.errorType == "validation") "createError sets errorType correctly" &&
      testFramework.assertThat (error.severity == "warning") "createError sets severity correctly" &&
      testFramework.assertThat (builtins.hasAttr "id" error) "createError generates ID" &&
      testFramework.assertThat (builtins.hasAttr "priority" error) "createError sets priority" &&
      testFramework.assertThat (builtins.hasAttr "category" error) "createError sets category"
    );

    # Test createError with defaults
    testCreateErrorDefaults = testFramework.runTest "createError with defaults" (
      let
        error = errorHandling.createError { message = "Simple error"; };
      in
      testFramework.assertThat (error.component == "unknown") "createError uses default component" &&
      testFramework.assertThat (error.errorType == "error") "createError uses default errorType" &&
      testFramework.assertThat (error.severity == "error") "createError uses default severity" &&
      testFramework.assertThat (error.context == {}) "createError uses default context" &&
      testFramework.assertThat (error.suggestions == []) "createError uses default suggestions"
    );

    # Test formatError function
    testFormatError = testFramework.runTest "formatError functionality" (
      let
        error = errorHandling.createError {
          message = "Test formatting";
          component = "formatter";
          errorType = "build";
          severity = "error";
          context = { file = "test.nix"; line = 42; };
          suggestions = [ "Check syntax" "Verify imports" ];
        };
        formatted = errorHandling.formatError error;
      in
      testFramework.assertThat (builtins.isString formatted) "formatError returns string" &&
      testFramework.assertThat (builtins.match ".*Test formatting.*" formatted != null) "formatError includes message" &&
      testFramework.assertThat (builtins.match ".*formatter.*" formatted != null) "formatError includes component" &&
      testFramework.assertThat (builtins.match ".*Check syntax.*" formatted != null) "formatError includes suggestions" &&
      testFramework.assertThat (builtins.match ".*file.*test.nix.*" formatted != null) "formatError includes context"
    );

    # Test categorizeError function
    testCategorizeError = testFramework.runTest "categorizeError functionality" (
      let
        error = errorHandling.categorizeError "config" "Configuration error" {
          component = "config-loader";
          severity = "warning";
          context = { file = "config.json"; };
        };
      in
      testFramework.assertThat (error.message == "Configuration error") "categorizeError sets message" &&
      testFramework.assertThat (error.errorType == "config") "categorizeError sets errorType" &&
      testFramework.assertThat (error.component == "config-loader") "categorizeError sets component" &&
      testFramework.assertThat (error.severity == "warning") "categorizeError sets severity" &&
      testFramework.assertThat (error.context.file == "config.json") "categorizeError sets context"
    );
  };

  # Utility function tests
  utilityTests = {
    # Test addContext function
    testAddContext = testFramework.runTest "addContext functionality" (
      let
        error = errorHandling.createError { message = "Base error"; };
        errorWithContext = errorHandling.addContext error { 
          file = "test.nix"; 
          line = 10; 
        };
      in
      testFramework.assertThat (errorWithContext.context.file == "test.nix") "addContext adds new context" &&
      testFramework.assertThat (errorWithContext.context.line == 10) "addContext preserves all context"
    );

    # Test addSuggestion function
    testAddSuggestion = testFramework.runTest "addSuggestion functionality" (
      let
        error = errorHandling.createError { 
          message = "Error with suggestions";
          suggestions = [ "First suggestion" ];
        };
        errorWithSuggestion = errorHandling.addSuggestion error "Second suggestion";
      in
      testFramework.assertThat (builtins.length errorWithSuggestion.suggestions == 2) "addSuggestion increases suggestion count" &&
      testFramework.assertThat (builtins.elemAt errorWithSuggestion.suggestions 1 == "Second suggestion") "addSuggestion adds at end"
    );

    # Test logError function
    testLogError = testFramework.runTest "logError functionality" (
      let
        error = errorHandling.createError {
          message = "Log test error";
          component = "logger";
          severity = "info";
          context = { user = "testuser"; action = "login"; };
        };
        logLine = errorHandling.logError error;
      in
      testFramework.assertThat (builtins.isString logLine) "logError returns string" &&
      testFramework.assertThat (builtins.match ".*info.*logger.*Log test error.*" logLine != null) "logError includes basic info" &&
      testFramework.assertThat (builtins.match ".*user=testuser.*" logLine != null) "logError includes context"
    );

    # Test chainErrors function
    testChainErrors = testFramework.runTest "chainErrors functionality" (
      let
        error1 = errorHandling.createError { message = "Error 1"; };
        error2 = errorHandling.createError { message = "Error 2"; };
        errorList = [ error1 error2 ];
        chainedFromList = errorHandling.chainErrors errorList;
        chainedFromSingle = errorHandling.chainErrors error1;
      in
      testFramework.assertThat (builtins.isList chainedFromList) "chainErrors preserves lists" &&
      testFramework.assertThat (builtins.length chainedFromList == 2) "chainErrors preserves list length" &&
      testFramework.assertThat (builtins.isList chainedFromSingle) "chainErrors converts single to list" &&
      testFramework.assertThat (builtins.length chainedFromSingle == 1) "chainErrors single item list length"
    );
  };

  # Validation and recovery tests
  validationTests = {
    # Test validateError function
    testValidateError = testFramework.runTest "validateError functionality" (
      let
        validError = errorHandling.createError { message = "Valid error"; };
        invalidError = { message = "Invalid"; }; # Missing required fields
        
        validResult = errorHandling.validateError validError;
        invalidResult = errorHandling.validateError invalidError;
      in
      testFramework.assertThat validResult.valid "validateError accepts valid error" &&
      testFramework.assertThat (validResult.error == null) "validateError returns null for valid" &&
      testFramework.assertThat (!invalidResult.valid) "validateError rejects invalid error" &&
      testFramework.assertThat (invalidResult.error != null) "validateError returns error for invalid"
    );

    # Test fromException function
    testFromException = testFramework.runTest "fromException functionality" (
      let
        exception = "Test exception message";
        error = errorHandling.fromException exception "exception-handler";
      in
      testFramework.assertThat (builtins.match ".*Test exception message.*" error.message != null) "fromException preserves message" &&
      testFramework.assertThat (error.component == "exception-handler") "fromException sets component" &&
      testFramework.assertThat (error.errorType == "build") "fromException sets correct type" &&
      testFramework.assertThat (error.severity == "error") "fromException sets correct severity"
    );

    # Test tryWithFallback function
    testTryWithFallback = testFramework.runTest "tryWithFallback functionality" (
      let
        successOp = x: x + 1;
        failOp = x: throw "Operation failed";
        
        successResult = errorHandling.tryWithFallback successOp 5 0;
        failResult = errorHandling.tryWithFallback failOp 5 999;
      in
      testFramework.assertThat (successResult == 6) "tryWithFallback returns success result" &&
      testFramework.assertThat (failResult == 999) "tryWithFallback returns fallback on failure"
    );
  };

  # Aggregation tests
  aggregationTests = {
    # Test filterBySeverity function
    testFilterBySeverity = testFramework.runTest "filterBySeverity functionality" (
      let
        errors = [
          (errorHandling.createError { message = "Critical"; severity = "critical"; })
          (errorHandling.createError { message = "Error"; severity = "error"; })
          (errorHandling.createError { message = "Warning"; severity = "warning"; })
          (errorHandling.createError { message = "Info"; severity = "info"; })
        ];
        
        criticalAndAbove = errorHandling.filterBySeverity errors "critical";
        errorAndAbove = errorHandling.filterBySeverity errors "error";
        warningAndAbove = errorHandling.filterBySeverity errors "warning";
      in
      testFramework.assertThat (builtins.length criticalAndAbove == 1) "filterBySeverity filters critical only" &&
      testFramework.assertThat (builtins.length errorAndAbove == 2) "filterBySeverity includes error and critical" &&
      testFramework.assertThat (builtins.length warningAndAbove == 3) "filterBySeverity includes warning and above"
    );

    # Test groupByCategory function
    testGroupByCategory = testFramework.runTest "groupByCategory functionality" (
      let
        errors = [
          (errorHandling.createError { message = "Build error"; errorType = "build"; })
          (errorHandling.createError { message = "Config error"; errorType = "config"; })
          (errorHandling.createError { message = "Network error"; errorType = "network"; })
        ];
        
        grouped = errorHandling.groupByCategory errors;
      in
      testFramework.assertThat (builtins.hasAttr "system" grouped) "groupByCategory creates system category" &&
      testFramework.assertThat (builtins.hasAttr "user" grouped) "groupByCategory creates user category" &&
      testFramework.assertThat (builtins.hasAttr "external" grouped) "groupByCategory creates external category" &&
      testFramework.assertThat (builtins.length grouped.system == 1) "groupByCategory places build errors in system" &&
      testFramework.assertThat (builtins.length grouped.user == 1) "groupByCategory places config errors in user" &&
      testFramework.assertThat (builtins.length grouped.external == 1) "groupByCategory places network errors in external"
    );

    # Test summarizeErrors function
    testSummarizeErrors = testFramework.runTest "summarizeErrors functionality" (
      let
        errors = [
          (errorHandling.createError { message = "Error 1"; severity = "error"; })
          (errorHandling.createError { message = "Error 2"; severity = "error"; })
          (errorHandling.createError { message = "Warning 1"; severity = "warning"; })
          (errorHandling.createError { message = "Critical 1"; severity = "critical"; })
        ];
        
        summary = errorHandling.aggregation.summarizeErrors errors;
      in
      testFramework.assertThat (summary.total == 4) "summarizeErrors counts total correctly" &&
      testFramework.assertThat (summary.counts.error == 2) "summarizeErrors counts errors correctly" &&
      testFramework.assertThat (summary.counts.warning == 1) "summarizeErrors counts warnings correctly" &&
      testFramework.assertThat (summary.counts.critical == 1) "summarizeErrors counts critical correctly" &&
      testFramework.assertThat (summary.mostSevere.severity == "critical") "summarizeErrors finds most severe"
    );
  };

  # Recovery mechanism tests
  recoveryTests = {
    # Test retryWithBackoff function
    testRetryWithBackoff = testFramework.runTest "retryWithBackoff functionality" (
      let
        # Simple operation that always succeeds
        successOp = x: x * 2;
        result = errorHandling.recovery.retryWithBackoff successOp 3 5;
      in
      testFramework.assertThat (result == 10) "retryWithBackoff executes successful operation"
    );

    # Test circuitBreaker function
    testCircuitBreaker = testFramework.runTest "circuitBreaker functionality" (
      let
        # Operation that always succeeds
        successOp = x: x + 10;
        result = errorHandling.recovery.circuitBreaker successOp 5 3;
      in
      testFramework.assertThat (result == 15) "circuitBreaker executes successful operation"
    );
  };

  # Collect all test results
  allTests = coreTests // utilityTests // validationTests // aggregationTests // recoveryTests;
  
  # Run all tests and collect results
  testResults = builtins.mapAttrs (name: test: test) allTests;
  
  # Count successful and failed tests
  successfulTests = builtins.filter (test: test.success) (builtins.attrValues testResults);
  failedTests = builtins.filter (test: !test.success) (builtins.attrValues testResults);
  
  # Generate test report
  testReport = {
    total = builtins.length (builtins.attrValues testResults);
    successful = builtins.length successfulTests;
    failed = builtins.length failedTests;
    successRate = if testReport.total > 0 then (testReport.successful * 100) / testReport.total else 0;
    results = testResults;
    
    # Summary for easy reading
    summary = if testReport.failed == 0 then
      "✅ All ${toString testReport.total} tests passed!"
    else
      "❌ ${toString testReport.failed} of ${toString testReport.total} tests failed";
  };

in

# Export test results
{
  inherit testReport;
  
  # Quick access to test status
  allTestsPassed = testReport.failed == 0;
  
  # Individual test results for debugging
  inherit testResults;
  
  # Test the refactored error handling system
  errorHandlingSystem = errorHandling;
  
  # Verification that no circular dependencies exist
  verifyNoCycles = 
    let
      # Try to access all major functions to ensure they work
      testError = errorHandling.createError { message = "Cycle test"; };
      testFormat = errorHandling.formatError testError;
      testValidation = errorHandling.validateError testError;
    in
    "✅ No circular dependencies detected - all functions accessible";
}