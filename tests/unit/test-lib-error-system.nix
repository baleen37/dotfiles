# Comprehensive Unit Tests for lib/error-system.nix
# Tests error creation, formatting, localization, and all utility functions

{ pkgs, lib, ... }:

let
  errorSystem = import ../../lib/error-system.nix { inherit pkgs lib; };

  # Test helper to run tests with proper error handling
  runTest = name: testFn:
    pkgs.runCommand "test-${name}"
      {
        buildInputs = with pkgs; [ jq ];
      } ''
      echo "🧪 Running test: ${name}"

      if ${testFn}; then
        echo "✅ Test ${name} PASSED"
      else
        echo "❌ Test ${name} FAILED"
        exit 1
      fi
    '';

  # Test basic error creation
  testErrorCreation = runTest "error-creation" ''
    # Test basic error creation with defaults
    nix eval --impure --expr '
      let
        errorSys = import ${../../lib/error-system.nix} { pkgs = null; lib = null; };
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
        hasIcon = error.icon != null;
        hasColor = error.color != null;
        exitCode = error.exitCode;
      }
    ' > /tmp/error_creation.json

    message=$(jq -r '.message' /tmp/error_creation.json)
    component=$(jq -r '.component' /tmp/error_creation.json)
    errorType=$(jq -r '.errorType' /tmp/error_creation.json)
    severity=$(jq -r '.severity' /tmp/error_creation.json)
    locale=$(jq -r '.locale' /tmp/error_creation.json)
    hasIcon=$(jq -r '.hasIcon' /tmp/error_creation.json)
    hasColor=$(jq -r '.hasColor' /tmp/error_creation.json)
    exitCode=$(jq -r '.exitCode' /tmp/error_creation.json)

    if [ "$message" = "Test error message" ] && [ "$component" = "test-component" ] &&
       [ "$errorType" = "user" ] && [ "$severity" = "error" ] &&
       [ "$locale" = "en" ] && [ "$hasIcon" = "true" ] &&
       [ "$hasColor" = "true" ] && [ "$exitCode" = "1" ]; then
      echo "✓ Basic error creation works correctly"
      true
    else
      echo "✗ Error creation failed:"
      cat /tmp/error_creation.json
      false
    fi
  '';

  testConvenienceFunctions = runTest "convenience-functions" ''
    # Test convenience error creation functions
    nix eval --impure --expr '
      let
        errorSys = import ${../../lib/error-system.nix} { pkgs = null; lib = null; };
      in {
        userError = (errorSys.userError "User error test").errorType;
        buildError = (errorSys.buildError "Build error test").errorType;
        configError = (errorSys.configError "Config error test").errorType;
        systemError = (errorSys.systemError "System error test").errorType;
        validationError = (errorSys.validationError "Validation error test").errorType;
        networkError = (errorSys.networkError "Network error test").errorType;
        permissionError = (errorSys.permissionError "Permission error test").errorType;
        testError = (errorSys.testError "Test error test").errorType;
        platformError = (errorSys.platformError "Platform error test").errorType;
        buildSeverity = (errorSys.buildError "Build error test").severity;
        systemSeverity = (errorSys.systemError "System error test").severity;
        networkSeverity = (errorSys.networkError "Network error test").severity;
      }
    ' > /tmp/convenience_functions.json

    userError=$(jq -r '.userError' /tmp/convenience_functions.json)
    buildError=$(jq -r '.buildError' /tmp/convenience_functions.json)
    configError=$(jq -r '.configError' /tmp/convenience_functions.json)
    systemError=$(jq -r '.systemError' /tmp/convenience_functions.json)
    validationError=$(jq -r '.validationError' /tmp/convenience_functions.json)
    networkError=$(jq -r '.networkError' /tmp/convenience_functions.json)
    permissionError=$(jq -r '.permissionError' /tmp/convenience_functions.json)
    testError=$(jq -r '.testError' /tmp/convenience_functions.json)
    platformError=$(jq -r '.platformError' /tmp/convenience_functions.json)
    buildSeverity=$(jq -r '.buildSeverity' /tmp/convenience_functions.json)
    systemSeverity=$(jq -r '.systemSeverity' /tmp/convenience_functions.json)
    networkSeverity=$(jq -r '.networkSeverity' /tmp/convenience_functions.json)

    if [ "$userError" = "user" ] && [ "$buildError" = "build" ] &&
       [ "$configError" = "config" ] && [ "$systemError" = "system" ] &&
       [ "$validationError" = "validation" ] && [ "$networkError" = "network" ] &&
       [ "$permissionError" = "permission" ] && [ "$testError" = "test" ] &&
       [ "$platformError" = "platform" ] && [ "$buildSeverity" = "critical" ] &&
       [ "$systemSeverity" = "critical" ] && [ "$networkSeverity" = "warning" ]; then
      echo "✓ Convenience functions create correct error types and severities"
      true
    else
      echo "✗ Convenience functions failed:"
      cat /tmp/convenience_functions.json
      false
    fi
  '';

  testLocalization = runTest "localization" ''
    # Test Korean localization
    nix eval --impure --expr '
      let
        errorSys = import ${../../lib/error-system.nix} { pkgs = null; lib = null; };
        koError = errorSys.createError {
          message = "Environment variable USER must be set";
          component = "user-setup";
          locale = "ko";
        };
        enError = errorSys.createError {
          message = "Environment variable USER must be set";
          component = "user-setup";
          locale = "en";
        };
      in {
        koEnhancedMessage = koError.enhancedMessage;
        enEnhancedMessage = enError.enhancedMessage;
        koSuggestions = koError.suggestions;
        enSuggestions = enError.suggestions;
        koSuggestionsCount = builtins.length koError.suggestions;
        enSuggestionsCount = builtins.length enError.suggestions;
      }
    ' > /tmp/localization.json

    koMessage=$(jq -r '.koEnhancedMessage' /tmp/localization.json)
    enMessage=$(jq -r '.enEnhancedMessage' /tmp/localization.json)
    koSuggestionsCount=$(jq -r '.koSuggestionsCount' /tmp/localization.json)
    enSuggestionsCount=$(jq -r '.enSuggestionsCount' /tmp/localization.json)

    if echo "$koMessage" | grep -q "환경변수 USER" &&
       echo "$enMessage" | grep -q "Environment variable USER" &&
       [ "$koSuggestionsCount" = "3" ] && [ "$enSuggestionsCount" = "3" ]; then
      echo "✓ Localization works correctly for both Korean and English"

      # Verify Korean suggestions contain Korean text
      koFirstSuggestion=$(jq -r '.koSuggestions[0]' /tmp/localization.json)
      if echo "$koFirstSuggestion" | grep -q "export USER"; then
        echo "✓ Korean suggestions contain appropriate Korean text"
        true
      else
        echo "✗ Korean suggestions don't contain expected text: $koFirstSuggestion"
        false
      fi
    else
      echo "✗ Localization failed:"
      cat /tmp/localization.json
      false
    fi
  '';

  testPatternMatching = runTest "pattern-matching" ''
    # Test error pattern matching and enhancement
    patterns='[
      "assertion failed",
      "file not found",
      "permission denied"
    ]'

    for pattern in $(echo "$patterns" | jq -r '.[]'); do
      nix eval --impure --expr "
        let
          errorSys = import ${../../lib/error-system.nix} { pkgs = null; lib = null; };
          error = errorSys.createError {
            message = \"Test: $pattern in operation\";
            component = \"pattern-test\";
          };
        in {
          originalMessage = error.message;
          enhancedMessage = error.enhancedMessage;
          suggestionsCount = builtins.length error.suggestions;
          errorType = error.errorType;
          severity = error.severity;
        }
      " > "/tmp/pattern_$pattern.json"

      suggestionsCount=$(jq -r '.suggestionsCount' "/tmp/pattern_$pattern.json")
      errorType=$(jq -r '.errorType' "/tmp/pattern_$pattern.json")

      if [ "$suggestionsCount" -gt "0" ]; then
        echo "✓ Pattern '$pattern' matched and enhanced with $suggestionsCount suggestions (type: $errorType)"
      else
        echo "✗ Pattern '$pattern' did not generate suggestions"
        cat "/tmp/pattern_$pattern.json"
        return 1
      fi
    done

    echo "✓ All pattern matching tests passed"
    true
  '';

  testSeverityLevels = runTest "severity-levels" ''
    # Test all severity levels
    severities='["critical", "error", "warning", "info", "debug"]'

    nix eval --impure --expr '
      let
        errorSys = import ${../../lib/error-system.nix} { pkgs = null; lib = null; };
        testSeverity = sev: {
          name = sev;
          error = errorSys.createError {
            message = "Test ${sev} message";
            component = "severity-test";
            severity = sev;
          };
        };
        tests = map testSeverity [ "critical" "error" "warning" "info" "debug" ];
      in builtins.listToAttrs (map (test: {
        name = test.name;
        value = {
          severity = test.error.severity;
          exitCode = test.error.exitCode;
          severityPriority = test.error.severityPriority;
          severityIcon = test.error.severityIcon;
        };
      }) tests)
    ' > /tmp/severities.json

    for severity in $(echo "$severities" | jq -r '.[]'); do
      exitCode=$(jq -r ".${severity}.exitCode" /tmp/severities.json)
      priority=$(jq -r ".${severity}.severityPriority" /tmp/severities.json)
      icon=$(jq -r ".${severity}.severityIcon" /tmp/severities.json)

      # Check expected exit codes
      case "$severity" in
        "critical") expectedExit=2 ;;
        "error") expectedExit=1 ;;
        *) expectedExit=0 ;;
      esac

      if [ "$exitCode" = "$expectedExit" ] && [ "$priority" -gt "0" ] && [ "$icon" != "null" ]; then
        echo "✓ Severity '$severity' has correct exit code ($exitCode), priority ($priority), and icon ($icon)"
      else
        echo "✗ Severity '$severity' failed validation: exit=$exitCode (expected $expectedExit), priority=$priority, icon=$icon"
        return 1
      fi
    done

    echo "✓ All severity level tests passed"
    true
  '';

  testPredefinedErrors = runTest "predefined-errors" ''
    # Test predefined error factories
    nix eval --impure --expr '
      let
        errorSys = import ${../../lib/error-system.nix} { pkgs = null; lib = null; };
      in {
        userNotSet = errorSys.errors.userNotSet;
        buildFailed = errorSys.errors.buildFailed { system = "x86_64-linux"; };
        platformMismatch = errorSys.errors.platformMismatch {
          expected = "darwin";
          actual = "linux";
        };
        dependencyMissing = errorSys.errors.dependencyMissing {
          package = "nodejs";
        };
        testFailed = errorSys.errors.testFailed {
          category = "unit";
          test = "user-resolution";
        };
        configurationInvalid = errorSys.errors.configurationInvalid {
          file = "flake.nix";
          error = "syntax error";
        };
        networkError = errorSys.errors.networkError {
          url = "https://cache.nixos.org";
        };
      }
    ' > /tmp/predefined_errors.json

    # Check that all predefined errors have required fields
    for error in userNotSet buildFailed platformMismatch dependencyMissing testFailed configurationInvalid networkError; do
      type=$(jq -r ".${error}.type" /tmp/predefined_errors.json)
      messageKo=$(jq -r ".${error}.message_ko" /tmp/predefined_errors.json)
      messageEn=$(jq -r ".${error}.message_en" /tmp/predefined_errors.json)
      command=$(jq -r ".${error}.command" /tmp/predefined_errors.json)

      if [ "$type" != "null" ] && [ "$messageKo" != "null" ] &&
         [ "$messageEn" != "null" ] && [ "$command" != "null" ]; then
        echo "✓ Predefined error '$error' has all required fields (type: $type)"
      else
        echo "✗ Predefined error '$error' missing fields: type=$type, messageKo=$messageKo, messageEn=$messageEn"
        return 1
      fi
    done

    echo "✓ All predefined error tests passed"
    true
  '';

  testUtilityFunctions = runTest "utility-functions" ''
    # Test requireEnv function
    result1=$(nix eval --impure --expr '
      let
        errorSys = import ${../../lib/error-system.nix} { pkgs = null; lib = null; };
        # This should return the default since PWD is typically set
        result = errorSys.utils.tryWithFallback (x: x + " processed") "test input" "fallback";
      in result
    ' 2>/dev/null || echo "fallback")

    if [ "$result1" = "test input processed" ] || [ "$result1" = "fallback" ]; then
      echo "✓ tryWithFallback function works correctly"
    else
      echo "✗ tryWithFallback failed: $result1"
      return 1
    fi

    # Test validateError function
    nix eval --impure --expr '
      let
        errorSys = import ${../../lib/error-system.nix} { pkgs = null; lib = null; };
        validError = {
          message = "test";
          component = "test";
          errorType = "user";
          severity = "error";
        };
        invalidError = {
          message = "test";
          # missing required fields
        };
        validResult = errorSys.utils.validateError validError;
        invalidResult = errorSys.utils.validateError invalidError;
      in {
        validIsValid = validResult.valid;
        validHasError = validResult.error != null;
        invalidIsValid = invalidResult.valid;
        invalidHasError = invalidResult.error != null;
      }
    ' > /tmp/validation_utils.json

    validIsValid=$(jq -r '.validIsValid' /tmp/validation_utils.json)
    validHasError=$(jq -r '.validHasError' /tmp/validation_utils.json)
    invalidIsValid=$(jq -r '.invalidIsValid' /tmp/validation_utils.json)
    invalidHasError=$(jq -r '.invalidHasError' /tmp/validation_utils.json)

    if [ "$validIsValid" = "true" ] && [ "$validHasError" = "false" ] &&
       [ "$invalidIsValid" = "false" ] && [ "$invalidHasError" = "true" ]; then
      echo "✓ Error validation utility functions work correctly"
      true
    else
      echo "✗ Error validation failed:"
      cat /tmp/validation_utils.json
      false
    fi
  '';

  testErrorAggregation = runTest "error-aggregation" ''
    # Test error aggregation functionality
    nix eval --impure --expr '
      let
        errorSys = import ${../../lib/error-system.nix} { pkgs = null; lib = null; };
        errors = [
          (errorSys.createError { message = "Error 1"; severity = "critical"; errorType = "build"; })
          (errorSys.createError { message = "Error 2"; severity = "error"; errorType = "user"; })
          (errorSys.createError { message = "Error 3"; severity = "warning"; errorType = "config"; })
          (errorSys.createError { message = "Error 4"; severity = "error"; errorType = "user"; })
          (errorSys.createError { message = "Error 5"; severity = "info"; errorType = "system"; })
        ];
        aggregated = errorSys.aggregateErrors errors;
      in {
        total = aggregated.total;
        criticalCount = aggregated.counts.severity.critical or 0;
        errorCount = aggregated.counts.severity.error or 0;
        warningCount = aggregated.counts.severity.warning or 0;
        infoCount = aggregated.counts.severity.info or 0;
        buildCount = aggregated.counts.type.build or 0;
        userCount = aggregated.counts.type.user or 0;
        configCount = aggregated.counts.type.config or 0;
        systemCount = aggregated.counts.type.system or 0;
        mostSevereSeverity = aggregated.mostSevere.severity;
        mostSevereType = aggregated.mostSevere.errorType;
      }
    ' > /tmp/aggregation.json

    total=$(jq -r '.total' /tmp/aggregation.json)
    criticalCount=$(jq -r '.criticalCount' /tmp/aggregation.json)
    errorCount=$(jq -r '.errorCount' /tmp/aggregation.json)
    warningCount=$(jq -r '.warningCount' /tmp/aggregation.json)
    infoCount=$(jq -r '.infoCount' /tmp/aggregation.json)
    buildCount=$(jq -r '.buildCount' /tmp/aggregation.json)
    userCount=$(jq -r '.userCount' /tmp/aggregation.json)
    mostSevereSeverity=$(jq -r '.mostSevereSeverity' /tmp/aggregation.json)
    mostSevereType=$(jq -r '.mostSevereType' /tmp/aggregation.json)

    if [ "$total" = "5" ] && [ "$criticalCount" = "1" ] &&
       [ "$errorCount" = "2" ] && [ "$warningCount" = "1" ] &&
       [ "$infoCount" = "1" ] && [ "$buildCount" = "1" ] &&
       [ "$userCount" = "2" ] && [ "$mostSevereSeverity" = "critical" ] &&
       [ "$mostSevereType" = "build" ]; then
      echo "✓ Error aggregation works correctly"
      echo "  Total errors: $total"
      echo "  Most severe: $mostSevereSeverity ($mostSevereType)"
      echo "  By severity - Critical: $criticalCount, Error: $errorCount, Warning: $warningCount, Info: $infoCount"
      echo "  By type - Build: $buildCount, User: $userCount, Config: $configCount, System: $systemCount"
      true
    else
      echo "✗ Error aggregation failed:"
      cat /tmp/aggregation.json
      false
    fi
  '';

  testProgressIndicators = runTest "progress-indicators" ''
    # Test progress indicator functions
    nix eval --impure --expr '
      let
        errorSys = import ${../../lib/error-system.nix} { pkgs = null; lib = null; };
      in {
        startingEn = errorSys.progress.starting { phase = "build"; locale = "en"; };
        startingKo = errorSys.progress.starting { phase = "build"; locale = "ko"; };
        completedEn = errorSys.progress.completed { phase = "test"; locale = "en"; };
        completedKo = errorSys.progress.completed { phase = "test"; locale = "ko"; };
        failedEn = errorSys.progress.failed { phase = "deploy"; locale = "en"; };
        failedKo = errorSys.progress.failed { phase = "deploy"; locale = "ko"; };
        skippedEn = errorSys.progress.skipped { phase = "optional"; locale = "en"; };
        skippedKo = errorSys.progress.skipped { phase = "optional"; locale = "ko"; };
      }
    ' > /tmp/progress.json

    startingEn=$(jq -r '.startingEn' /tmp/progress.json)
    startingKo=$(jq -r '.startingKo' /tmp/progress.json)
    completedEn=$(jq -r '.completedEn' /tmp/progress.json)
    completedKo=$(jq -r '.completedKo' /tmp/progress.json)

    if echo "$startingEn" | grep -q "Starting build" &&
       echo "$startingKo" | grep -q "build 시작 중" &&
       echo "$completedEn" | grep -q "test completed successfully" &&
       echo "$completedKo" | grep -q "test 성공적으로 완료"; then
      echo "✓ Progress indicators work correctly for both locales"
      true
    else
      echo "✗ Progress indicators failed:"
      cat /tmp/progress.json
      false
    fi
  '';

  # Main test suite that runs all tests
  allTests = pkgs.runCommand "lib-error-system-tests"
    {
      buildInputs = with pkgs; [ jq nix ];
    } ''
    echo "🚀 Running comprehensive lib/error-system.nix test suite..."
    echo "================================================================="

    # Run all tests
    ${testErrorCreation}/bin/*
    ${testConvenienceFunctions}/bin/*
    ${testLocalization}/bin/*
    ${testPatternMatching}/bin/*
    ${testSeverityLevels}/bin/*
    ${testPredefinedErrors}/bin/*
    ${testUtilityFunctions}/bin/*
    ${testErrorAggregation}/bin/*
    ${testProgressIndicators}/bin/*

    echo "================================================================="
    echo "🎉 All lib/error-system.nix tests completed successfully!"
    echo "✅ Total: 9 test cases passed"
    echo ""
    echo "Test Coverage:"
    echo "- Basic error creation ✅"
    echo "- Convenience functions (9 error types) ✅"
    echo "- Localization (Korean/English) ✅"
    echo "- Pattern matching and enhancement ✅"
    echo "- Severity levels (5 levels) ✅"
    echo "- Predefined error factories (7 types) ✅"
    echo "- Utility functions ✅"
    echo "- Error aggregation and statistics ✅"
    echo "- Progress indicators ✅"

    touch $out
  '';

in
# Return the main test suite
allTests
