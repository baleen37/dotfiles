# Enhanced Error Handler System
# 개선된 에러 처리 시스템 - 컨텍스트 기반 메시지, 해결책 제시, 한국어 지원

{
  # Error categorization
  errorType ? "user",  # "build" | "config" | "dependency" | "user" | "system"
  # Component that failed
  component ? "unknown",
  # The actual error description
  message,
  # Array of suggested solutions
  suggestions ? [],
  # Severity level
  severity ? "error",  # "critical" | "error" | "warning" | "info"
  # Language preference
  locale ? "ko",  # "ko" | "en"
  # Debug mode for detailed output
  debugMode ? false,
  # Additional context information
  context ? {}
}:

let
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

  # Error type icons and colors
  errorTypeInfo = {
    build = { icon = "🔨"; color = colors.red; };
    config = { icon = "⚙️"; color = colors.yellow; };
    dependency = { icon = "📦"; color = colors.magenta; };
    user = { icon = "👤"; color = colors.blue; };
    system = { icon = "💻"; color = colors.cyan; };
  };

  # Severity level formatting
  severityInfo = {
    critical = { icon = "🚨"; color = colors.red + colors.bold; label_ko = "치명적"; label_en = "CRITICAL"; };
    error = { icon = "❌"; color = colors.red; label_ko = "오류"; label_en = "ERROR"; };
    warning = { icon = "⚠️"; color = colors.yellow; label_ko = "경고"; label_en = "WARNING"; };
    info = { icon = "ℹ️"; color = colors.blue; label_ko = "정보"; label_en = "INFO"; };
  };

  # Korean translations for common terms
  translations = {
    ko = {
      error_occurred = "오류가 발생했습니다";
      component = "구성요소";
      error_type = "오류 유형";
      suggestions = "해결 방법";
      context = "추가 정보";
      debug_info = "디버그 정보";
      no_suggestions = "해결 방법이 제공되지 않았습니다";
    };
    en = {
      error_occurred = "An error occurred";
      component = "Component";
      error_type = "Error Type";
      suggestions = "Suggestions";
      context = "Context";
      debug_info = "Debug Information";
      no_suggestions = "No suggestions provided";
    };
  };

  # Get translation for current locale
  t = key:
    if builtins.hasAttr locale translations && builtins.hasAttr key translations.${locale}
    then translations.${locale}.${key}
    else translations.en.${key};

  # Format suggestions list
  formatSuggestions = suggestions:
    if suggestions == [] then
      "   ${t "no_suggestions"}"
    else
      builtins.concatStringsSep "\n" (
        map (i: let
          idx = toString (i + 1);
          suggestion = builtins.elemAt suggestions i;
        in "   ${idx}. ${suggestion}")
        (builtins.genList (x: x) (builtins.length suggestions))
      );

  # Format context information
  formatContext = context:
    if context == {} then ""
    else
      let
        contextLines = builtins.attrNames context;
        formatLine = key: "   ${key}: ${builtins.toString context.${key}}";
      in
      "\n\n${colors.cyan}${t "context"}:${colors.reset}\n" +
      builtins.concatStringsSep "\n" (map formatLine contextLines);

  # Get error type information
  getErrorTypeInfo = errorType:
    if builtins.hasAttr errorType errorTypeInfo
    then errorTypeInfo.${errorType}
    else errorTypeInfo.user;

  # Get severity information
  getSeverityInfo = severity:
    if builtins.hasAttr severity severityInfo
    then severityInfo.${severity}
    else severityInfo.error;

  # Common error patterns and their Korean translations
  commonErrorPatterns = {
    "Environment variable USER must be set" = {
      ko = "환경변수 USER가 설정되지 않았습니다";
      suggestions_ko = [
        "export USER=$(whoami) 실행 후 다시 시도"
        "nix run --impure .#build 사용"
        "make build USER=$(whoami) 실행"
      ];
    };
    "assertion failed" = {
      ko = "검증 조건이 실패했습니다";
      suggestions_ko = [
        "설정 파일의 문법을 확인하세요"
        "필수 환경변수가 설정되었는지 확인하세요"
        "make doctor 명령어로 시스템 상태를 진단하세요"
      ];
    };
    "file not found" = {
      ko = "파일을 찾을 수 없습니다";
      suggestions_ko = [
        "파일 경로를 확인하세요"
        "파일이 존재하는지 확인하세요"
        "권한 설정을 확인하세요"
      ];
    };
  };

  # Enhance message with Korean translation if available
  enhancedMessage =
    let
      matchingPattern = builtins.filter
        (pattern: builtins.match ".*${pattern}.*" message != null)
        (builtins.attrNames commonErrorPatterns);
    in
    if matchingPattern != [] then
      let
        pattern = builtins.head matchingPattern;
        patternInfo = commonErrorPatterns.${pattern};
      in
      if locale == "ko" && builtins.hasAttr "ko" patternInfo then
        {
          message = patternInfo.ko;
          suggestions = if suggestions == [] && builtins.hasAttr "suggestions_ko" patternInfo
            then patternInfo.suggestions_ko
            else suggestions;
        }
      else
        { message = message; suggestions = suggestions; }
    else
      { message = message; suggestions = suggestions; };

  # Final error information
  finalErrorInfo = enhancedMessage;
  typeInfo = getErrorTypeInfo errorType;
  sevInfo = getSeverityInfo severity;

  # Build the complete error message
  errorHeader =
    "${sevInfo.color}${sevInfo.icon} ${
      if locale == "ko" then sevInfo.label_ko else sevInfo.label_en
    }${colors.reset}";

  componentInfo =
    "${colors.bold}${t "component"}:${colors.reset} ${typeInfo.color}${typeInfo.icon} ${component}${colors.reset}";

  errorTypeDisplay =
    "${colors.bold}${t "error_type"}:${colors.reset} ${typeInfo.color}${errorType}${colors.reset}";

  messageDisplay =
    "${colors.red}${finalErrorInfo.message}${colors.reset}";

  suggestionsDisplay =
    if finalErrorInfo.suggestions != [] then
      "\n\n${colors.green}${colors.bold}${t "suggestions"}:${colors.reset}\n" +
      formatSuggestions finalErrorInfo.suggestions
    else "";

  contextDisplay = formatContext context;

  debugDisplay =
    if debugMode then
      "\n\n${colors.yellow}${t "debug_info"}:${colors.reset}\n" +
      "   Severity: ${severity}\n" +
      "   Error Type: ${errorType}\n" +
      "   Component: ${component}\n" +
      "   Locale: ${locale}\n" +
      "   Original Message: ${message}"
    else "";

  # Complete formatted error message
  completeErrorMessage = ''
    ${errorHeader}

    ${componentInfo}
    ${errorTypeDisplay}

    ${messageDisplay}${suggestionsDisplay}${contextDisplay}${debugDisplay}

    ${colors.yellow}💡 더 자세한 정보는 CLAUDE.md 파일을 참조하세요${colors.reset}
  '';

in
  builtins.throw completeErrorMessage
