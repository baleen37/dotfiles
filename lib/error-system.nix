# Unified Error Handling System for Dotfiles
# Combines error-handler.nix, error-handling.nix, and error-messages.nix
# Provides comprehensive error processing, localization, and recovery mechanisms

{
  pkgs ? null,
  lib ? null,
}:

let
  # Determine pkgs and lib based on what's available
  actualPkgs = if pkgs != null then pkgs else (import <nixpkgs> { });
  actualLib = if lib != null then lib else actualPkgs.lib;

  # Color codes for terminal output
  colors = {
    red = "\033[31m";
    green = "\033[32m";
    yellow = "\033[33m";
    blue = "\033[34m";
    magenta = "\033[35m";
    cyan = "\033[36m";
    white = "\033[37m";
    bold = "\033[1m";
    reset = "\033[0m";
  };

  # Error type definitions with comprehensive metadata
  errorTypes = {
    build = {
      icon = "🔨";
      color = colors.red;
      category = "system";
      priority = "high";
    };
    config = {
      icon = "⚙️";
      color = colors.yellow;
      category = "user";
      priority = "medium";
    };
    dependency = {
      icon = "📦";
      color = colors.magenta;
      category = "system";
      priority = "high";
    };
    user = {
      icon = "👤";
      color = colors.blue;
      category = "user";
      priority = "low";
    };
    system = {
      icon = "💻";
      color = colors.cyan;
      category = "system";
      priority = "high";
    };
    validation = {
      icon = "✅";
      color = colors.blue;
      category = "user";
      priority = "medium";
    };
    network = {
      icon = "🌐";
      color = colors.cyan;
      category = "external";
      priority = "medium";
    };
    permission = {
      icon = "🔒";
      color = colors.red;
      category = "system";
      priority = "critical";
    };
    test = {
      icon = "🧪";
      color = colors.magenta;
      category = "development";
      priority = "medium";
    };
    platform = {
      icon = "🖥️";
      color = colors.yellow;
      category = "system";
      priority = "medium";
    };
  };

  # Severity levels with enhanced metadata
  severityLevels = {
    critical = {
      priority = 100;
      icon = "🚨";
      color = colors.red + colors.bold;
      label_ko = "치명적";
      label_en = "CRITICAL";
      exitCode = 2;
    };
    error = {
      priority = 75;
      icon = "❌";
      color = colors.red;
      label_ko = "오류";
      label_en = "ERROR";
      exitCode = 1;
    };
    warning = {
      priority = 50;
      icon = "⚠️";
      color = colors.yellow;
      label_ko = "경고";
      label_en = "WARNING";
      exitCode = 0;
    };
    info = {
      priority = 25;
      icon = "ℹ️";
      color = colors.blue;
      label_ko = "정보";
      label_en = "INFO";
      exitCode = 0;
    };
    debug = {
      priority = 10;
      icon = "🔍";
      color = colors.cyan;
      label_ko = "디버그";
      label_en = "DEBUG";
      exitCode = 0;
    };
  };

  # Localization support
  translations = {
    ko = {
      error_occurred = "오류가 발생했습니다";
      component = "구성요소";
      error_type = "오류 유형";
      suggestions = "해결 방법";
      context = "추가 정보";
      debug_info = "디버그 정보";
      no_suggestions = "해결 방법이 제공되지 않았습니다";
      help_text = "💡 더 자세한 정보는 CLAUDE.md 파일을 참조하세요";
    };
    en = {
      error_occurred = "An error occurred";
      component = "Component";
      error_type = "Error Type";
      suggestions = "Suggestions";
      context = "Context";
      debug_info = "Debug Information";
      no_suggestions = "No suggestions provided";
      help_text = "💡 For more information, see CLAUDE.md";
    };
  };

  # Common error patterns with localization
  commonErrorPatterns = {
    "Environment variable USER must be set" = {
      ko = "환경변수 USER가 설정되지 않았습니다";
      type = "user";
      severity = "error";
      suggestions_ko = [
        "export USER=$(whoami) 실행 후 다시 시도"
        "nix run --impure .#build 사용"
        "make build USER=$(whoami) 실행"
      ];
      suggestions_en = [
        "Run: export USER=$(whoami) and try again"
        "Use: nix run --impure .#build"
        "Execute: make build USER=$(whoami)"
      ];
    };
    "assertion failed" = {
      ko = "검증 조건이 실패했습니다";
      type = "validation";
      severity = "error";
      suggestions_ko = [
        "설정 파일의 문법을 확인하세요"
        "필수 환경변수가 설정되었는지 확인하세요"
        "make doctor 명령어로 시스템 상태를 진단하세요"
      ];
      suggestions_en = [
        "Check configuration file syntax"
        "Verify required environment variables are set"
        "Run 'make doctor' to diagnose system state"
      ];
    };
    "file not found" = {
      ko = "파일을 찾을 수 없습니다";
      type = "system";
      severity = "error";
      suggestions_ko = [
        "파일 경로를 확인하세요"
        "파일이 존재하는지 확인하세요"
        "권한 설정을 확인하세요"
      ];
      suggestions_en = [
        "Check file path"
        "Verify file exists"
        "Check file permissions"
      ];
    };
    "permission denied" = {
      ko = "권한이 거부되었습니다";
      type = "permission";
      severity = "error";
      suggestions_ko = [
        "sudo 권한으로 실행하세요"
        "파일 권한을 확인하세요"
        "사용자 그룹 설정을 확인하세요"
      ];
      suggestions_en = [
        "Run with sudo privileges"
        "Check file permissions"
        "Verify user group settings"
      ];
    };
    "network" = {
      ko = "네트워크 연결에 실패했습니다";
      type = "network";
      severity = "warning";
      suggestions_ko = [
        "인터넷 연결을 확인하세요"
        "프록시 설정을 확인하세요"
        "잠시 후 다시 시도하세요"
      ];
      suggestions_en = [
        "Check internet connection"
        "Verify proxy settings"
        "Try again later"
      ];
    };
  };

  # Predefined error messages for common scenarios
  predefinedErrors = {
    userNotSet = {
      type = "user";
      message_ko = "USER 환경변수가 설정되지 않았습니다";
      message_en = "USER environment variable is not set";
      hint_ko = "사용자별 설정을 결정하는데 필요합니다";
      hint_en = "This is required for determining user-specific configurations";
      command = ''
        export USER=$(whoami)
        # Or use the detect-user script:
        ./scripts/detect-user
      '';
    };

    buildFailed =
      { system }:
      {
        type = "build";
        message_ko = "${system}에 대한 빌드가 실패했습니다";
        message_en = "Build failed for ${system}";
        hint_ko = "위의 빌드 로그에서 구체적인 오류를 확인하세요";
        hint_en = "Check the build log above for specific errors";
        command = ''
          # Show detailed trace:
          nix build --impure --show-trace .#${system}

          # Clear cache and retry:
          nix store gc && nix build --impure .#${system}
        '';
      };

    platformMismatch =
      { expected, actual }:
      {
        type = "platform";
        message_ko = "플랫폼 불일치: ${expected}가 예상되었지만 ${actual}에서 실행 중입니다";
        message_en = "Platform mismatch: expected ${expected}, but running on ${actual}";
        hint_ko = "크로스 플랫폼 빌드에는 추가 설정이 필요할 수 있습니다";
        hint_en = "Cross-platform builds may require additional setup";
        command = ''
          # Build for current platform instead:
          nix build --impure .#$(nix eval --impure --expr 'builtins.currentSystem')
        '';
      };

    dependencyMissing =
      { package }:
      {
        type = "dependency";
        message_ko = "필수 의존성 '${package}'이(가) 누락되었습니다";
        message_en = "Required dependency '${package}' is missing";
        hint_ko = "모든 의존성이 flake에 올바르게 선언되었는지 확인하세요";
        hint_en = "Ensure all dependencies are properly declared in the flake";
        command = ''
          # Add to appropriate packages.nix:
          # - modules/shared/packages.nix (cross-platform)
          # - modules/darwin/packages.nix (macOS only)
          # - modules/nixos/packages.nix (Linux only)
        '';
      };

    testFailed =
      { category, test }:
      {
        type = "test";
        message_ko = "테스트 실패: ${category}/${test}";
        message_en = "Test failed: ${category}/${test}";
        hint_ko = "구체적인 실패에 대해서는 테스트 출력을 검토하세요";
        hint_en = "Review the test output for specific failures";
        command = ''
          # Run specific test with details:
          nix build --impure --show-trace .#checks.$(nix eval --impure --expr 'builtins.currentSystem').${test}

          # Run all ${category} tests:
          nix run --impure .#test-${category}
        '';
      };

    configurationInvalid =
      { file, error }:
      {
        type = "config";
        message_ko = "${file}의 설정이 유효하지 않습니다";
        message_en = "Invalid configuration in ${file}";
        hint_ko = "오류: ${error}";
        hint_en = "Error: ${error}";
        command = ''
          # Validate configuration:
          nix flake check --impure --show-trace

          # Check specific file syntax:
          nix-instantiate --parse ${file}
        '';
      };

    networkError =
      { url }:
      {
        type = "network";
        message_ko = "${url} 가져오기에 실패했습니다";
        message_en = "Failed to fetch ${url}";
        hint_ko = "인터넷 연결과 프록시 설정을 확인하세요";
        hint_en = "Check your internet connection and proxy settings";
        command = ''
          # Test connectivity:
          curl -I ${url}

          # Retry with fallback substituters:
          nix build --substituters https://cache.nixos.org --impure .#build
        '';
      };
  };

  # Get current timestamp
  getTimestamp = builtins.toString (builtins.currentTime or 0);

  # Get translation function
  getTranslation =
    locale: key:
    if builtins.hasAttr locale translations && builtins.hasAttr key translations.${locale} then
      translations.${locale}.${key}
    else
      translations.en.${key};

  # Enhanced message processing with pattern matching
  enhanceMessage =
    {
      message,
      locale ? "en",
      suggestions ? [ ],
    }:
    let
      matchingPattern = actualLib.findFirst (
        pattern: builtins.match ".*${pattern}.*" message != null
      ) null (builtins.attrNames commonErrorPatterns);
    in
    if matchingPattern != null then
      let
        patternInfo = commonErrorPatterns.${matchingPattern};
        suggestionsKey = "suggestions_${locale}";
        fallbackSuggestionsKey = "suggestions_en";
      in
      {
        message = if locale == "ko" && builtins.hasAttr "ko" patternInfo then patternInfo.ko else message;
        suggestions =
          if suggestions == [ ] then
            patternInfo.${suggestionsKey} or patternInfo.${fallbackSuggestionsKey} or [ ]
          else
            suggestions;
        type = patternInfo.type or "user";
        severity = patternInfo.severity or "error";
      }
    else
      {
        inherit message suggestions;
        type = "user";
        severity = "error";
      };

  # Format error for display
  formatError =
    error:
    let
      t = getTranslation error.locale;

      # Header with severity
      header = "${error.severityColor}${error.severityIcon} ${
        if error.locale == "ko" then
          severityLevels.${error.severity}.label_ko
        else
          severityLevels.${error.severity}.label_en
      }${colors.reset}";

      # Component and type information
      componentLine = "${colors.bold}${t "component"}:${colors.reset} ${error.color}${error.icon} ${error.component}${colors.reset}";
      typeLine = "${colors.bold}${t "error_type"}:${colors.reset} ${error.color}${error.errorType}${colors.reset}";

      # Main message
      messageLine = "${colors.red}${error.enhancedMessage}${colors.reset}";

      # Context section
      contextSection =
        if error.context != { } then
          let
            contextLines = builtins.attrNames error.context;
            formatContextLine = key: "  ${key}: ${builtins.toString error.context.${key}}";
          in
          "\n\n${colors.cyan}${t "context"}:${colors.reset}\n"
          + actualLib.concatMapStringsSep "\n" formatContextLine contextLines
        else
          "";

      # Suggestions section
      suggestionsSection =
        if error.suggestions != [ ] then
          let
            formatSuggestion = i: "  ${toString (i + 1)}. ${builtins.elemAt error.suggestions i}";
            indices = builtins.genList (x: x) (builtins.length error.suggestions);
          in
          "\n\n${colors.green}${colors.bold}${t "suggestions"}:${colors.reset}\n"
          + actualLib.concatMapStringsSep "\n" formatSuggestion indices
        else
          "";

      # Debug section
      debugSection =
        if error.debugMode then
          "\n\n${colors.yellow}${t "debug_info"}:${colors.reset}\n"
          + "  Severity: ${error.severity}\n"
          + "  Error Type: ${error.errorType}\n"
          + "  Component: ${error.component}\n"
          + "  Locale: ${error.locale}\n"
          + "  Priority: ${error.priority}\n"
          + "  Exit Code: ${toString error.exitCode}\n"
          + "  Original Message: ${error.message}"
        else
          "";

      # Help text
      helpText = "\n\n${colors.yellow}${t "help_text"}${colors.reset}";

    in
    "${header}\n\n${componentLine}\n${typeLine}\n\n${messageLine}${contextSection}${suggestionsSection}${debugSection}${helpText}";

  # Core error creation function
  createError =
    {
      message,
      component ? "unknown",
      errorType ? "user",
      severity ? "error",
      locale ? "en",
      debugMode ? false,
      context ? { },
      suggestions ? [ ],
      timestamp ? getTimestamp,
    }:
    let
      # Enhance message with pattern matching
      enhanced = enhanceMessage {
        inherit message locale suggestions;
      };

      # Use enhanced values or fallback to provided values
      finalType = enhanced.type or errorType;
      finalSeverity = enhanced.severity or severity;
      finalMessage = enhanced.message;
      finalSuggestions = enhanced.suggestions;

      typeInfo = errorTypes.${finalType} or errorTypes.user;
      severityInfo = severityLevels.${finalSeverity} or severityLevels.error;
    in
    {
      inherit
        message
        component
        locale
        debugMode
        context
        timestamp
        ;
      errorType = finalType;
      severity = finalSeverity;
      enhancedMessage = finalMessage;
      suggestions = finalSuggestions;
      inherit (typeInfo) icon;
      inherit (typeInfo) color;
      inherit (typeInfo) category;
      inherit (typeInfo) priority;
      severityIcon = severityInfo.icon;
      severityColor = severityInfo.color;
      severityPriority = severityInfo.priority;
      inherit (severityInfo) exitCode;
      id = builtins.hashString "sha256" "${component}-${finalType}-${finalMessage}";
    };

in
rec {
  # Export constants for external use
  inherit
    colors
    errorTypes
    severityLevels
    translations
    commonErrorPatterns
    predefinedErrors
    ;

  # Export the createError and formatError functions
  inherit createError formatError;

  # Convenience functions for creating specific error types
  userError =
    message:
    createError {
      inherit message;
      errorType = "user";
    };
  buildError =
    message:
    createError {
      inherit message;
      errorType = "build";
      severity = "critical";
    };
  configError =
    message:
    createError {
      inherit message;
      errorType = "config";
    };
  systemError =
    message:
    createError {
      inherit message;
      errorType = "system";
      severity = "critical";
    };
  validationError =
    message:
    createError {
      inherit message;
      errorType = "validation";
    };
  networkError =
    message:
    createError {
      inherit message;
      errorType = "network";
      severity = "warning";
    };
  permissionError =
    message:
    createError {
      inherit message;
      errorType = "permission";
      severity = "critical";
    };
  testError =
    message:
    createError {
      inherit message;
      errorType = "test";
    };
  platformError =
    message:
    createError {
      inherit message;
      errorType = "platform";
    };

  # Error handling functions
  throwError = error: builtins.throw (formatError error);
  throwFormattedError = errorConfig: throwError (createError errorConfig);

  # Quick throw functions
  throwUserError = message: throwError (userError message);
  throwBuildError = message: throwError (buildError message);
  throwConfigError = message: throwError (configError message);
  throwSystemError = message: throwError (systemError message);
  throwValidationError = message: throwError (validationError message);

  # Error aggregation and reporting
  aggregateErrors =
    errors:
    let
      totalCount = builtins.length errors;
      bySeverity = builtins.groupBy (error: error.severity) errors;
      severityCounts = builtins.mapAttrs (_sev: errs: builtins.length errs) bySeverity;
      byType = builtins.groupBy (error: error.errorType) errors;
      typeCounts = builtins.mapAttrs (_type: errs: builtins.length errs) byType;
    in
    {
      total = totalCount;
      counts = {
        severity = severityCounts;
        type = typeCounts;
      };
      mostSevere =
        if totalCount > 0 then
          let
            priorities = map (error: error.severityPriority) errors;
            maxPriority = builtins.foldl' actualLib.max 0 priorities;
            mostSevereErrors = builtins.filter (error: error.severityPriority == maxPriority) errors;
          in
          builtins.head mostSevereErrors
        else
          null;
    };

  # Predefined error factories
  errors = {
    inherit (predefinedErrors)
      userNotSet
      buildFailed
      platformMismatch
      dependencyMissing
      testFailed
      configurationInvalid
      networkError
      ;
  };

  # Progress indicators with localization
  progress = {
    starting =
      {
        phase,
        locale ? "en",
      }:
      if locale == "ko" then "${phase} 시작 중..." else "Starting ${phase}...";
    completed =
      {
        phase,
        locale ? "en",
      }:
      if locale == "ko" then "✓ ${phase} 성공적으로 완료됨" else "✓ ${phase} completed successfully";
    failed =
      {
        phase,
        locale ? "en",
      }:
      if locale == "ko" then "✗ ${phase} 실패" else "✗ ${phase} failed";
    skipped =
      {
        phase,
        locale ? "en",
      }:
      if locale == "ko" then "- ${phase} 건너뜀" else "- ${phase} skipped";
  };

  # Utility functions
  utils = {
    # Require environment variable with error handling
    requireEnv =
      var: default:
      let
        value = builtins.getEnv var;
      in
      if value == "" && default == null then
        throwError (createError {
          message = "Environment variable ${var} is required but not set";
          component = "environment";
          errorType = "user";
          suggestions = [ "Set the environment variable: export ${var}=<value>" ];
        })
      else if value == "" then
        default
      else
        value;

    # Try operation with fallback
    tryWithFallback =
      operation: input: fallback:
      let
        result = builtins.tryEval (operation input);
      in
      if result.success then result.value else fallback;

    # Validate error structure
    validateError =
      error:
      let
        requiredFields = [
          "message"
          "component"
          "errorType"
          "severity"
        ];
        hasField = field: builtins.hasAttr field error;
        missingFields = builtins.filter (field: !(hasField field)) requiredFields;
      in
      if missingFields == [ ] then
        {
          valid = true;
          error = null;
        }
      else
        {
          valid = false;
          error = createError {
            message = "Invalid error structure: missing fields [${actualLib.concatStringsSep ", " missingFields}]";
            component = "error-validation";
            errorType = "validation";
            severity = "error";
          };
        };
  };

  # Version and metadata
  version = "2.0.0-unified";
  description = "Unified error handling system combining all error modules";
  supportedLocales = [
    "en"
    "ko"
  ];
}
