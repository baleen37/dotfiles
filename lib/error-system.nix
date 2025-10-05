# Simplified Error Handling System
# Applies YAGNI principle - keeps only actually-used features
# Removed: Korean localization, unused error types, progress indicators, aggregateErrors

{
  pkgs ? null,
  lib ? null,
}:

let
  # Determine pkgs and lib based on what's available
  actualPkgs = if pkgs != null then pkgs else (import <nixpkgs> { });
  actualLib = if lib != null then lib else actualPkgs.lib;

  # Basic color codes for terminal output
  colors = {
    red = "\033[31m";
    yellow = "\033[33m";
    blue = "\033[34m";
    bold = "\033[1m";
    reset = "\033[0m";
  };

  # Only keep actually-used error types
  errorTypes = {
    build = {
      icon = "🔨";
      color = colors.red;
      priority = "high";
    };
    config = {
      icon = "⚙️";
      color = colors.yellow;
      priority = "medium";
    };
    user = {
      icon = "👤";
      color = colors.blue;
      priority = "low";
    };
    validation = {
      icon = "✅";
      color = colors.blue;
      priority = "medium";
    };
  };

  # Simplified severity levels (only what's used)
  severityLevels = {
    critical = {
      priority = 100;
      icon = "🚨";
      color = colors.red + colors.bold;
      label = "CRITICAL";
      exitCode = 2;
    };
    error = {
      priority = 75;
      icon = "❌";
      color = colors.red;
      label = "ERROR";
      exitCode = 1;
    };
    warning = {
      priority = 50;
      icon = "⚠️";
      color = colors.yellow;
      label = "WARNING";
      exitCode = 0;
    };
  };

  # Common error patterns (English only - Korean not used)
  commonErrorPatterns = {
    "Environment variable USER must be set" = {
      type = "user";
      severity = "error";
      suggestions = [
        "Run: export USER=$(whoami) and try again"
        "Use: nix run --impure .#build"
        "Execute: make build USER=$(whoami)"
      ];
    };
    "assertion failed" = {
      type = "validation";
      severity = "error";
      suggestions = [
        "Check configuration file syntax"
        "Verify required environment variables are set"
        "Run 'make doctor' to diagnose system state"
      ];
    };
    "file not found" = {
      type = "build";
      severity = "error";
      suggestions = [
        "Check file path"
        "Verify file exists"
        "Check file permissions"
      ];
    };
  };

  # Only keep actually-used predefined errors
  predefinedErrors = {
    userNotSet = {
      type = "user";
      message = "USER environment variable is not set";
      hint = "This is required for determining user-specific configurations";
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
        message = "Build failed for ${system}";
        hint = "Check the build log above for specific errors";
        command = ''
          # Show detailed trace:
          nix build --impure --show-trace .#${system}

          # Clear cache and retry:
          nix store gc && nix build --impure .#${system}
        '';
      };

    configurationInvalid =
      { file, error }:
      {
        type = "config";
        message = "Invalid configuration in ${file}";
        hint = "Error: ${error}";
        command = ''
          # Validate configuration:
          nix flake check --impure --show-trace

          # Check specific file syntax:
          nix-instantiate --parse ${file}
        '';
      };
  };

  # Get current timestamp
  getTimestamp = builtins.toString (builtins.currentTime or 0);

  # Enhanced message processing with pattern matching
  enhanceMessage =
    {
      message,
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
      in
      {
        inherit message;
        suggestions = if suggestions == [ ] then patternInfo.suggestions or [ ] else suggestions;
        type = patternInfo.type or "user";
        severity = patternInfo.severity or "error";
      }
    else
      {
        inherit message suggestions;
        type = "user";
        severity = "error";
      };

  # Simplified error formatting
  formatError =
    error:
    let
      # Header with severity
      header = "${error.severityColor}${error.severityIcon} ${
        severityLevels.${error.severity}.label
      }${colors.reset}";

      # Component and type information
      componentLine = "${colors.bold}Component:${colors.reset} ${error.color}${error.icon} ${error.component}${colors.reset}";
      typeLine = "${colors.bold}Error Type:${colors.reset} ${error.color}${error.errorType}${colors.reset}";

      # Main message
      messageLine = "${colors.red}${error.enhancedMessage}${colors.reset}";

      # Context section (if provided)
      contextSection =
        if error.context != { } then
          let
            contextLines = builtins.attrNames error.context;
            formatContextLine = key: "  ${key}: ${builtins.toString error.context.${key}}";
          in
          "\n\nContext:\n" + actualLib.concatMapStringsSep "\n" formatContextLine contextLines
        else
          "";

      # Suggestions section (if provided)
      suggestionsSection =
        if error.suggestions != [ ] then
          let
            formatSuggestion = i: "  ${toString (i + 1)}. ${builtins.elemAt error.suggestions i}";
            indices = builtins.genList (x: x) (builtins.length error.suggestions);
          in
          "\n\nSuggestions:\n" + actualLib.concatMapStringsSep "\n" formatSuggestion indices
        else
          "";

    in
    "${header}\n\n${componentLine}\n${typeLine}\n\n${messageLine}${contextSection}${suggestionsSection}";

  # Core error creation function
  createError =
    {
      message,
      component ? "unknown",
      errorType ? "user",
      severity ? "error",
      context ? { },
      suggestions ? [ ],
      timestamp ? getTimestamp,
    }:
    let
      # Enhance message with pattern matching
      enhanced = enhanceMessage { inherit message suggestions; };

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
        context
        timestamp
        ;
      errorType = finalType;
      severity = finalSeverity;
      enhancedMessage = finalMessage;
      suggestions = finalSuggestions;
      inherit (typeInfo) icon;
      inherit (typeInfo) color;
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
  validationError =
    message:
    createError {
      inherit message;
      errorType = "validation";
    };

  # Error handling functions
  throwError = error: builtins.throw (formatError error);
  throwFormattedError = errorConfig: throwError (createError errorConfig);

  # Quick throw functions (most commonly used)
  throwUserError = message: throwError (userError message);
  throwBuildError = message: throwError (buildError message);
  throwConfigError = message: throwError (configError message);
  throwValidationError = message: throwError (validationError message);

  # Predefined error factories
  errors = {
    inherit (predefinedErrors)
      userNotSet
      buildFailed
      configurationInvalid
      ;
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
  version = "3.0.0-simplified";
  description = "Simplified error handling system (YAGNI applied - removed unused features)";
}
