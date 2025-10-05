# Error System Unit Tests
#
# lib/error-system.nix 테스트 (simplified version)
# - 에러 타입 스키마 검증
# - 심각도 우선순위 정렬
# - 에러 포매팅 함수
#
# 테스트 대상:
# - errorTypes: 에러 타입 정의 (user, build, config, validation only)
# - severityLevels: 심각도 레벨 정의 (critical, error, warning)
# - createError: 에러 생성 함수
# - formatError: 에러 포매팅 함수
# - commonErrorPatterns: 일반 에러 패턴 매칭
# - predefinedErrors: 사전 정의된 에러 팩토리
#
# Note: Korean localization removed (YAGNI - not used)

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  nixtest ? null,
  self ? null,
}:

let
  nixtestFinal =
    if nixtest != null then nixtest else (import ./nixtest-template.nix { inherit lib pkgs; }).nixtest;

  # Import error system
  errorSystem =
    if self != null then
      import (self + /lib/error-system.nix) { inherit lib pkgs; }
    else
      import ../../lib/error-system.nix { inherit lib pkgs; };

in
nixtestFinal.suite "Error System Tests" {

  # Error type schema tests
  errorTypesTests = nixtestFinal.suite "Error Type Schema Tests" {

    allTypesHaveIcon = nixtestFinal.test "All error types have icon" (
      let
        types = builtins.attrNames errorSystem.errorTypes;
        allHaveIcon = builtins.all (type: builtins.hasAttr "icon" errorSystem.errorTypes.${type}) types;
      in
      nixtestFinal.assertions.assertTrue allHaveIcon
    );

    allTypesHaveColor = nixtestFinal.test "All error types have color" (
      let
        types = builtins.attrNames errorSystem.errorTypes;
        allHaveColor = builtins.all (type: builtins.hasAttr "color" errorSystem.errorTypes.${type}) types;
      in
      nixtestFinal.assertions.assertTrue allHaveColor
    );

    allTypesHaveCategory = nixtestFinal.test "All error types have category" (
      let
        types = builtins.attrNames errorSystem.errorTypes;
        allHaveCategory = builtins.all (
          type: builtins.hasAttr "category" errorSystem.errorTypes.${type}
        ) types;
      in
      nixtestFinal.assertions.assertTrue allHaveCategory
    );

    allTypesHavePriority = nixtestFinal.test "All error types have priority" (
      let
        types = builtins.attrNames errorSystem.errorTypes;
        allHavePriority = builtins.all (
          type: builtins.hasAttr "priority" errorSystem.errorTypes.${type}
        ) types;
      in
      nixtestFinal.assertions.assertTrue allHavePriority
    );

    criticalErrorTypes = nixtestFinal.test "Critical errors identified correctly" (
      let
        criticalTypes = builtins.filter (type: errorSystem.errorTypes.${type}.priority == "critical") (
          builtins.attrNames errorSystem.errorTypes
        );
      in
      nixtestFinal.assertions.assertContains "permission" criticalTypes
    );
  };

  # Severity level tests
  severityLevelsTests = nixtestFinal.suite "Severity Level Tests" {

    severityPriorityOrdering = nixtestFinal.test "Severity levels have correct priority ordering" (
      let
        critical = errorSystem.severityLevels.critical.priority;
        error = errorSystem.severityLevels.error.priority;
        warning = errorSystem.severityLevels.warning.priority;
        info = errorSystem.severityLevels.info.priority;
        debug = errorSystem.severityLevels.debug.priority;
      in
      nixtestFinal.assertions.assertTrue (
        critical > error && error > warning && warning > info && info > debug
      )
    );

    allSeveritiesHaveExitCode = nixtestFinal.test "All severity levels have exit code" (
      let
        severities = builtins.attrNames errorSystem.severityLevels;
        allHaveExitCode = builtins.all (
          sev: builtins.hasAttr "exitCode" errorSystem.severityLevels.${sev}
        ) severities;
      in
      nixtestFinal.assertions.assertTrue allHaveExitCode
    );

    criticalHasHighestPriority = nixtestFinal.test "Critical has highest priority" (
      let
        priorities = map (sev: errorSystem.severityLevels.${sev}.priority) (
          builtins.attrNames errorSystem.severityLevels
        );
        maxPriority = builtins.foldl' lib.max 0 priorities;
      in
      nixtestFinal.assertions.assertEqual maxPriority errorSystem.severityLevels.critical.priority
    );

    errorCodesNonZeroForErrors = nixtestFinal.test "Error codes non-zero for errors" (
      nixtestFinal.assertions.assertTrue (
        errorSystem.severityLevels.critical.exitCode > 0 && errorSystem.severityLevels.error.exitCode > 0
      )
    );

    warningCodeZero = nixtestFinal.test "Warning exit code is zero" (
      nixtestFinal.assertions.assertEqual 0 errorSystem.severityLevels.warning.exitCode
    );
  };

  # Translation completeness tests
  translationTests = nixtestFinal.suite "Translation Completeness Tests" {

    bothLocalesSupported = nixtestFinal.test "Both ko and en locales supported" (
      nixtestFinal.assertions.assertTrue (
        builtins.hasAttr "ko" errorSystem.translations && builtins.hasAttr "en" errorSystem.translations
      )
    );

    allKeysInBothLocales = nixtestFinal.test "All translation keys in both locales" (
      let
        koKeys = builtins.attrNames errorSystem.translations.ko;
        enKeys = builtins.attrNames errorSystem.translations.en;
      in
      nixtestFinal.assertions.assertEqual (builtins.sort (a: b: a < b) koKeys) (
        builtins.sort (a: b: a < b) enKeys
      )
    );

    errorOccurredTranslated = nixtestFinal.test "error_occurred key translated" (
      nixtestFinal.assertions.assertTrue (
        builtins.hasAttr "error_occurred" errorSystem.translations.ko
        && builtins.hasAttr "error_occurred" errorSystem.translations.en
      )
    );

    suggestionsTranslated = nixtestFinal.test "suggestions key translated" (
      nixtestFinal.assertions.assertTrue (
        builtins.hasAttr "suggestions" errorSystem.translations.ko
        && builtins.hasAttr "suggestions" errorSystem.translations.en
      )
    );
  };

  # Error creation tests
  errorCreationTests = nixtestFinal.suite "Error Creation Tests" {

    basicErrorCreation = nixtestFinal.test "Basic error creation works" (
      let
        error = errorSystem.createError {
          message = "Test error";
          component = "test-component";
        };
      in
      nixtestFinal.assertions.assertEqual "Test error" error.message
    );

    errorHasRequiredFields = nixtestFinal.test "Created error has required fields" (
      let
        error = errorSystem.createError {
          message = "Test";
          component = "test";
        };
      in
      nixtestFinal.assertions.assertTrue (
        builtins.hasAttr "message" error
        && builtins.hasAttr "component" error
        && builtins.hasAttr "errorType" error
        && builtins.hasAttr "severity" error
      )
    );

    errorDefaultsApplied = nixtestFinal.test "Error defaults are applied" (
      let
        error = errorSystem.createError { message = "Test"; };
      in
      nixtestFinal.assertions.assertEqual "unknown" error.component
    );

    errorIdGenerated = nixtestFinal.test "Error ID is generated" (
      let
        error = errorSystem.createError {
          message = "Test";
          component = "test";
        };
      in
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "id" error && error.id != "")
    );

    errorTimestampAdded = nixtestFinal.test "Error timestamp is added" (
      let
        error = errorSystem.createError {
          message = "Test";
          component = "test";
        };
      in
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "timestamp" error)
    );
  };

  # Error formatting tests
  errorFormattingTests = nixtestFinal.suite "Error Formatting Tests" {

    formattedErrorHasColor = nixtestFinal.test "Formatted error has color codes" (
      let
        error = errorSystem.createError {
          message = "Test error";
          component = "test";
        };
        formatted = errorSystem.formatError error;
      in
      nixtestFinal.assertions.assertStringContains "\033[" formatted
    );

    formattedErrorHasMessage = nixtestFinal.test "Formatted error contains message" (
      let
        error = errorSystem.createError {
          message = "Test error message";
          component = "test";
        };
        formatted = errorSystem.formatError error;
      in
      nixtestFinal.assertions.assertStringContains "Test error message" formatted
    );

    formattedErrorHasSuggestions = nixtestFinal.test "Formatted error shows suggestions" (
      let
        error = errorSystem.createError {
          message = "Test";
          component = "test";
          suggestions = [
            "Try this"
            "Or that"
          ];
        };
        formatted = errorSystem.formatError error;
      in
      nixtestFinal.assertions.assertStringContains "Try this" formatted
    );

    formattedErrorShowsComponent = nixtestFinal.test "Formatted error shows component" (
      let
        error = errorSystem.createError {
          message = "Test";
          component = "my-component";
        };
        formatted = errorSystem.formatError error;
      in
      nixtestFinal.assertions.assertStringContains "my-component" formatted
    );
  };

  # Common error pattern tests
  commonPatternTests = nixtestFinal.suite "Common Error Pattern Tests" {

    userEnvPattern = nixtestFinal.test "USER environment variable pattern recognized" (
      nixtestFinal.assertions.assertTrue (
        builtins.hasAttr "Environment variable USER must be set" errorSystem.commonErrorPatterns
      )
    );

    assertionFailedPattern = nixtestFinal.test "Assertion failed pattern recognized" (
      nixtestFinal.assertions.assertTrue (
        builtins.hasAttr "assertion failed" errorSystem.commonErrorPatterns
      )
    );

    fileNotFoundPattern = nixtestFinal.test "File not found pattern recognized" (
      nixtestFinal.assertions.assertTrue (
        builtins.hasAttr "file not found" errorSystem.commonErrorPatterns
      )
    );

    permissionDeniedPattern = nixtestFinal.test "Permission denied pattern recognized" (
      nixtestFinal.assertions.assertTrue (
        builtins.hasAttr "permission denied" errorSystem.commonErrorPatterns
      )
    );

    patternHasSuggestions = nixtestFinal.test "Patterns have suggestions" (
      let
        pattern = errorSystem.commonErrorPatterns."Environment variable USER must be set";
      in
      nixtestFinal.assertions.assertTrue (
        builtins.hasAttr "suggestions_en" pattern && builtins.hasAttr "suggestions_ko" pattern
      )
    );
  };

  # Predefined error tests
  predefinedErrorTests = nixtestFinal.suite "Predefined Error Tests" {

    userNotSetError = nixtestFinal.test "userNotSet predefined error exists" (
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "userNotSet" errorSystem.predefinedErrors)
    );

    buildFailedError = nixtestFinal.test "buildFailed predefined error exists" (
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "buildFailed" errorSystem.predefinedErrors)
    );

    platformMismatchError = nixtestFinal.test "platformMismatch predefined error exists" (
      nixtestFinal.assertions.assertTrue (
        builtins.hasAttr "platformMismatch" errorSystem.predefinedErrors
      )
    );

    predefinedErrorHasMessages = nixtestFinal.test "Predefined errors have localized messages" (
      let
        error = errorSystem.predefinedErrors.userNotSet;
      in
      nixtestFinal.assertions.assertTrue (
        builtins.hasAttr "message_ko" error && builtins.hasAttr "message_en" error
      )
    );

    predefinedErrorHasCommand = nixtestFinal.test "Predefined errors have command examples" (
      let
        error = errorSystem.predefinedErrors.userNotSet;
      in
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "command" error)
    );
  };

  # Convenience function tests
  convenienceFunctionTests = nixtestFinal.suite "Convenience Function Tests" {

    userErrorFunction = nixtestFinal.test "userError convenience function works" (
      let
        error = errorSystem.userError "Test user error";
      in
      nixtestFinal.assertions.assertEqual "user" error.errorType
    );

    buildErrorFunction = nixtestFinal.test "buildError convenience function works" (
      let
        error = errorSystem.buildError "Test build error";
      in
      nixtestFinal.assertions.assertEqual "build" error.errorType
    );

    buildErrorIsCritical = nixtestFinal.test "buildError severity is critical" (
      let
        error = errorSystem.buildError "Test";
      in
      nixtestFinal.assertions.assertEqual "critical" error.severity
    );

    configErrorFunction = nixtestFinal.test "configError convenience function works" (
      let
        error = errorSystem.configError "Test config error";
      in
      nixtestFinal.assertions.assertEqual "config" error.errorType
    );

    permissionErrorIsCritical = nixtestFinal.test "permissionError severity is critical" (
      let
        error = errorSystem.permissionError "Test";
      in
      nixtestFinal.assertions.assertEqual "critical" error.severity
    );
  };

  # Error aggregation tests
  errorAggregationTests = nixtestFinal.suite "Error Aggregation Tests" {

    aggregateCountsErrors = nixtestFinal.test "Aggregation counts errors correctly" (
      let
        errors = [
          (errorSystem.userError "Error 1")
          (errorSystem.buildError "Error 2")
          (errorSystem.userError "Error 3")
        ];
        aggregated = errorSystem.aggregateErrors errors;
      in
      nixtestFinal.assertions.assertEqual 3 aggregated.total
    );

    aggregateGroupsBySeverity = nixtestFinal.test "Aggregation groups by severity" (
      let
        errors = [
          (errorSystem.userError "Error 1")
          (errorSystem.buildError "Error 2")
        ];
        aggregated = errorSystem.aggregateErrors errors;
      in
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "severity" aggregated.counts)
    );

    aggregateGroupsByType = nixtestFinal.test "Aggregation groups by type" (
      let
        errors = [
          (errorSystem.userError "Error 1")
          (errorSystem.buildError "Error 2")
        ];
        aggregated = errorSystem.aggregateErrors errors;
      in
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "type" aggregated.counts)
    );

    aggregateFindsMostSevere = nixtestFinal.test "Aggregation finds most severe error" (
      let
        errors = [
          (errorSystem.userError "Error 1")
          (errorSystem.buildError "Critical error")
          (errorSystem.configError "Error 3")
        ];
        aggregated = errorSystem.aggregateErrors errors;
      in
      nixtestFinal.assertions.assertEqual "critical" aggregated.mostSevere.severity
    );
  };

  # Error validation tests
  errorValidationTests = nixtestFinal.suite "Error Validation Tests" {

    validErrorStructure = nixtestFinal.test "Valid error structure passes validation" (
      let
        error = errorSystem.createError {
          message = "Test";
          component = "test";
        };
        validation = errorSystem.utils.validateError error;
      in
      nixtestFinal.assertions.assertTrue validation.valid
    );

    invalidErrorMissingFields = nixtestFinal.test "Invalid error fails validation" (
      let
        invalidError = {
          message = "Test";
        };
        validation = errorSystem.utils.validateError invalidError;
      in
      nixtestFinal.assertions.assertFalse validation.valid
    );

    validationReturnsError = nixtestFinal.test "Validation returns error on failure" (
      let
        invalidError = {
          message = "Test";
        };
        validation = errorSystem.utils.validateError invalidError;
      in
      nixtestFinal.assertions.assertTrue (validation.error != null)
    );
  };
}
