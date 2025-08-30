# Simple Unit Test for lib/error-system.nix
# Focused on core error handling and localization

{ pkgs, lib, ... }:

pkgs.runCommand "lib-error-system-test"
{
  buildInputs = with pkgs; [ nix jq ];
} ''
  echo "🚀 Testing lib/error-system.nix"
  echo "================================"

  # Test 1: Basic error creation
  echo "Test 1: Basic error creation..."
  nix eval --impure --json --expr '
    let
      pkgs = import <nixpkgs> {};
      errorSys = import ${../../lib/error-system.nix} { inherit pkgs; lib = pkgs.lib; };
      error = errorSys.createError {
        message = "Test error message";
        component = "test-component";
      };
    in {
      message = error.message;
      component = error.component;
      errorType = error.errorType;
      severity = error.severity;
      locale = error.locale;
    }
  ' > error_creation.json

  message=$(jq -r '.message' error_creation.json || echo "error")
  component=$(jq -r '.component' error_creation.json || echo "error")
  errorType=$(jq -r '.errorType' error_creation.json || echo "error")

  if [ "$message" = "Test error message" ] && [ "$component" = "test-component" ] &&
     [ "$errorType" = "user" ]; then
    echo "✓ Basic error creation: PASSED"
  else
    echo "✗ Basic error creation: FAILED"
    echo "  message: $message"
    echo "  component: $component"
    echo "  errorType: $errorType"
    exit 1
  fi

  # Test 2: Convenience functions
  echo "Test 2: Convenience functions..."
  nix eval --impure --json --expr '
    let
      pkgs = import <nixpkgs> {};
      errorSys = import ${../../lib/error-system.nix} { inherit pkgs; lib = pkgs.lib; };
    in {
      userError = (errorSys.userError "User error test").errorType;
      buildError = (errorSys.buildError "Build error test").errorType;
      buildSeverity = (errorSys.buildError "Build error test").severity;
      networkError = (errorSys.networkError "Network error test").errorType;
      networkSeverity = (errorSys.networkError "Network error test").severity;
    }
  ' > convenience_functions.json

  userError=$(jq -r '.userError' convenience_functions.json)
  buildError=$(jq -r '.buildError' convenience_functions.json)
  buildSeverity=$(jq -r '.buildSeverity' convenience_functions.json)
  networkSeverity=$(jq -r '.networkSeverity' convenience_functions.json)

  if [ "$userError" = "user" ] && [ "$buildError" = "build" ] &&
     [ "$buildSeverity" = "critical" ] && [ "$networkSeverity" = "warning" ]; then
    echo "✓ Convenience functions: PASSED"
  else
    echo "✗ Convenience functions: FAILED"
    exit 1
  fi

  # Test 3: Korean localization
  echo "Test 3: Korean localization..."
  nix eval --impure --json --expr '
    let
      pkgs = import <nixpkgs> {};
      errorSys = import ${../../lib/error-system.nix} { inherit pkgs; lib = pkgs.lib; };
      koError = errorSys.createError {
        message = "Environment variable USER must be set";
        component = "user-setup";
        locale = "ko";
      };
    in {
      enhancedMessage = koError.enhancedMessage;
      suggestionsCount = builtins.length koError.suggestions;
    }
  ' > localization.json

  koMessage=$(jq -r '.enhancedMessage' localization.json)
  suggestionsCount=$(jq -r '.suggestionsCount' localization.json)

  if echo "$koMessage" | grep -q "환경변수 USER" && [ "$suggestionsCount" = "3" ]; then
    echo "✓ Korean localization: PASSED"
  else
    echo "✗ Korean localization: FAILED"
    echo "  message: $koMessage"
    echo "  suggestions count: $suggestionsCount"
    exit 1
  fi

  # Test 4: Severity levels
  echo "Test 4: Severity levels..."
  nix eval --impure --json --expr '
    let
      pkgs = import <nixpkgs> {};
      errorSys = import ${../../lib/error-system.nix} { inherit pkgs; lib = pkgs.lib; };
      criticalError = errorSys.createError {
        message = "Critical test";
        component = "test";
        severity = "critical";
      };
      warningError = errorSys.createError {
        message = "Warning test";
        component = "test";
        severity = "warning";
      };
    in {
      criticalExitCode = criticalError.exitCode;
      warningExitCode = warningError.exitCode;
      criticalPriority = criticalError.severityPriority;
      warningPriority = warningError.severityPriority;
    }
  ' > severities.json

  criticalExit=$(jq -r '.criticalExitCode' severities.json)
  warningExit=$(jq -r '.warningExitCode' severities.json)
  criticalPriority=$(jq -r '.criticalPriority' severities.json)
  warningPriority=$(jq -r '.warningPriority' severities.json)

  if [ "$criticalExit" = "2" ] && [ "$warningExit" = "0" ] &&
     [ "$criticalPriority" -gt "$warningPriority" ]; then
    echo "✓ Severity levels: PASSED"
  else
    echo "✗ Severity levels: FAILED"
    echo "  criticalExit: $criticalExit (expected: 2)"
    echo "  warningExit: $warningExit (expected: 0)"
    exit 1
  fi

  # Test 5: Predefined errors
  echo "Test 5: Predefined errors..."
  nix eval --impure --json --expr '
    let
      pkgs = import <nixpkgs> {};
      errorSys = import ${../../lib/error-system.nix} { inherit pkgs; lib = pkgs.lib; };
    in {
      userNotSetType = errorSys.errors.userNotSet.type;
      buildFailedType = (errorSys.errors.buildFailed { system = "x86_64-linux"; }).type;
      hasKoreanMessage = errorSys.errors.userNotSet ? message_ko;
      hasEnglishMessage = errorSys.errors.userNotSet ? message_en;
      hasCommand = errorSys.errors.userNotSet ? command;
    }
  ' > predefined_errors.json

  userNotSetType=$(jq -r '.userNotSetType' predefined_errors.json)
  buildFailedType=$(jq -r '.buildFailedType' predefined_errors.json)
  hasKorean=$(jq -r '.hasKoreanMessage' predefined_errors.json)
  hasEnglish=$(jq -r '.hasEnglishMessage' predefined_errors.json)
  hasCommand=$(jq -r '.hasCommand' predefined_errors.json)

  if [ "$userNotSetType" = "user" ] && [ "$buildFailedType" = "build" ] &&
     [ "$hasKorean" = "true" ] && [ "$hasEnglish" = "true" ] &&
     [ "$hasCommand" = "true" ]; then
    echo "✓ Predefined errors: PASSED"
  else
    echo "✗ Predefined errors: FAILED"
    exit 1
  fi

  echo "================================"
  echo "🎉 All lib/error-system.nix tests completed!"
  echo "✅ Total: 5 test cases passed"
  echo ""
  echo "Test Coverage:"
  echo "- Basic error creation ✅"
  echo "- Convenience functions ✅"
  echo "- Korean localization ✅"
  echo "- Severity levels ✅"
  echo "- Predefined error factories ✅"

  touch $out
''
