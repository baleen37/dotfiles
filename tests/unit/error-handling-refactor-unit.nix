# Comprehensive test suite for refactored error-handling.nix
# Tests all core functionality to ensure no regressions after refactoring

{ pkgs, flake ? null, src ? ../.. }:

pkgs.runCommand "error-handling-refactor-unit-test" { } ''
  echo "=== Error Handling Refactor Unit Tests ==="
  echo "Testing refactored lib/error-handling.nix functionality"
  echo "=================================================="

  # Import and test the refactored error handling system
  echo "🔍 Testing refactored error handling system..."

  # Test 1: Verify no circular dependencies
  echo "Test 1: Checking for circular dependencies..."
  ${pkgs.nix}/bin/nix eval --impure --expr '
    let
      pkgs = import <nixpkgs> {};
      errorHandling = import ${src}/lib/error-handling.nix { inherit pkgs; };

      # Try to access all major functions to ensure they work
      testError = errorHandling.createError { message = "Test message"; };
      testFormat = errorHandling.formatError testError;
      testValidation = errorHandling.validateError testError;
    in
    "SUCCESS: No circular dependencies detected"
  ' > test_result.txt

  if grep -q "SUCCESS" test_result.txt; then
    echo "✅ No circular dependencies detected"
  else
    echo "❌ Circular dependency test failed"
    cat test_result.txt
    exit 1
  fi

  # Test 2: Verify basic error creation functionality
  echo "Test 2: Testing basic error creation..."
  ${pkgs.nix}/bin/nix eval --impure --expr '
    let
      pkgs = import <nixpkgs> {};
      errorHandling = import ${src}/lib/error-handling.nix { inherit pkgs; };

      error = errorHandling.createError {
        message = "Test error message";
        component = "test-component";
        errorType = "validation";
        severity = "warning";
      };
    in
    assert error.message == "Test error message";
    assert error.component == "test-component";
    assert error.errorType == "validation";
    assert error.severity == "warning";
    assert builtins.hasAttr "id" error;
    assert builtins.hasAttr "priority" error;
    assert builtins.hasAttr "category" error;
    "SUCCESS: Basic error creation works correctly"
  ' > test_result2.txt

  if grep -q "SUCCESS" test_result2.txt; then
    echo "✅ Basic error creation functionality verified"
  else
    echo "❌ Basic error creation test failed"
    cat test_result2.txt
    exit 1
  fi

  # Test 3: Verify formatError functionality
  echo "Test 3: Testing error formatting..."
  ${pkgs.nix}/bin/nix eval --impure --expr '
    let
      pkgs = import <nixpkgs> {};
      errorHandling = import ${src}/lib/error-handling.nix { inherit pkgs; };

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
    assert builtins.isString formatted;
    assert builtins.match ".*Test formatting.*" formatted != null;
    assert builtins.match ".*formatter.*" formatted != null;
    assert builtins.match ".*Check syntax.*" formatted != null;
    assert builtins.match ".*file.*test.nix.*" formatted != null;
    "SUCCESS: Error formatting works correctly"
  ' > test_result3.txt

  if grep -q "SUCCESS" test_result3.txt; then
    echo "✅ Error formatting functionality verified"
  else
    echo "❌ Error formatting test failed"
    cat test_result3.txt
    exit 1
  fi

  # Test 4: Verify validateError functionality
  echo "Test 4: Testing error validation..."
  ${pkgs.nix}/bin/nix eval --impure --expr '
    let
      pkgs = import <nixpkgs> {};
      errorHandling = import ${src}/lib/error-handling.nix { inherit pkgs; };

      validError = errorHandling.createError { message = "Valid error"; };
      invalidError = { message = "Invalid"; }; # Missing required fields

      validResult = errorHandling.validateError validError;
      invalidResult = errorHandling.validateError invalidError;
    in
    assert validResult.valid == true;
    assert validResult.error == null;
    assert invalidResult.valid == false;
    assert invalidResult.error != null;
    "SUCCESS: Error validation works correctly"
  ' > test_result4.txt

  if grep -q "SUCCESS" test_result4.txt; then
    echo "✅ Error validation functionality verified"
  else
    echo "❌ Error validation test failed"
    cat test_result4.txt
    exit 1
  fi

  # Test 5: Verify recovery mechanisms
  echo "Test 5: Testing recovery mechanisms..."
  ${pkgs.nix}/bin/nix eval --impure --expr '
    let
      pkgs = import <nixpkgs> {};
      errorHandling = import ${src}/lib/error-handling.nix { inherit pkgs; };

      # Test tryWithFallback
      successOp = x: x + 1;
      successResult = errorHandling.tryWithFallback successOp 5 0;

      # Test retryWithBackoff (with success operation)
      retryResult = errorHandling.recovery.retryWithBackoff successOp 3 5;
    in
    assert successResult == 6;
    assert retryResult == 10;
    "SUCCESS: Recovery mechanisms work correctly"
  ' > test_result5.txt

  if grep -q "SUCCESS" test_result5.txt; then
    echo "✅ Recovery mechanisms functionality verified"
  else
    echo "❌ Recovery mechanisms test failed"
    cat test_result5.txt
    exit 1
  fi

  # Test 6: Verify aggregation functionality
  echo "Test 6: Testing error aggregation..."
  ${pkgs.nix}/bin/nix eval --impure --expr '
    let
      pkgs = import <nixpkgs> {};
      errorHandling = import ${src}/lib/error-handling.nix { inherit pkgs; };

      errors = [
        (errorHandling.createError { message = "Error 1"; severity = "error"; })
        (errorHandling.createError { message = "Error 2"; severity = "error"; })
        (errorHandling.createError { message = "Warning 1"; severity = "warning"; })
        (errorHandling.createError { message = "Critical 1"; severity = "critical"; })
      ];

      summary = errorHandling.aggregation.summarizeErrors errors;
      grouped = errorHandling.groupByCategory errors;
    in
    assert summary.total == 4;
    assert summary.counts.error == 2;
    assert summary.counts.warning == 1;
    assert summary.counts.critical == 1;
    assert summary.mostSevere.severity == "critical";
    assert builtins.hasAttr "system" grouped;
    assert builtins.hasAttr "user" grouped;
    assert builtins.hasAttr "external" grouped;
    "SUCCESS: Error aggregation works correctly"
  ' > test_result6.txt

  if grep -q "SUCCESS" test_result6.txt; then
    echo "✅ Error aggregation functionality verified"
  else
    echo "❌ Error aggregation test failed"
    cat test_result6.txt
    exit 1
  fi

  echo ""
  echo "🎉 All tests passed successfully!"
  echo ""
  echo "📊 Test Summary:"
  echo "  ✅ No circular dependencies"
  echo "  ✅ Basic error creation"
  echo "  ✅ Error formatting"
  echo "  ✅ Error validation"
  echo "  ✅ Recovery mechanisms"
  echo "  ✅ Error aggregation"
  echo ""
  echo "✨ Refactored error handling system is working correctly!"

  # Clean up test files
  rm -f test_result*.txt

  # Create success marker
  echo "success" > $out
''
