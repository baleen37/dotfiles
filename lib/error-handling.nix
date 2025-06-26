# Enhanced Error Handling System for Nix Flake-based Dotfiles
# Provides standardized error processing, logging, and recovery mechanisms

{ pkgs }:

let
  # Color codes for terminal output
  colors = {
    red = "\033[0;31m";
    yellow = "\033[1;33m";
    green = "\033[0;32m";
    blue = "\033[0;34m";
    magenta = "\033[0;35m";
    cyan = "\033[0;36m";
    bold = "\033[1m";
    reset = "\033[0m";
  };

  # Severity levels with priorities
  severityLevels = {
    critical = { priority = 100; icon = "🚨"; color = colors.red + colors.bold; };
    error = { priority = 75; icon = "❌"; color = colors.red; };
    warning = { priority = 50; icon = "⚠️"; color = colors.yellow; };
    info = { priority = 25; icon = "ℹ️"; color = colors.blue; };
    debug = { priority = 10; icon = "🔍"; color = colors.cyan; };
  };

  # Error types with their characteristics
  errorTypes = {
    build = { icon = "🔨"; color = colors.red; category = "system"; };
    config = { icon = "⚙️"; color = colors.yellow; category = "user"; };
    dependency = { icon = "📦"; color = colors.magenta; category = "system"; };
    validation = { icon = "✅"; color = colors.blue; category = "user"; };
    network = { icon = "🌐"; color = colors.cyan; category = "external"; };
    permission = { icon = "🔒"; color = colors.red; category = "system"; };
  };

  # Get current timestamp for logging
  getTimestamp = builtins.toString (builtins.currentTime or 0);

  # Simple uppercase conversion for common severity levels
  toUpper = str: {
    "critical" = "CRITICAL";
    "error" = "ERROR";
    "warning" = "WARNING";
    "info" = "INFO";
    "debug" = "DEBUG";
  }.${str} or str;

in
{
  # Export constants
  inherit colors severityLevels errorTypes;

  # Core error creation function
  createError = { message, component ? "unknown", errorType ? "error", severity ? "error", timestamp ? getTimestamp, context ? {}, suggestions ? [] }:
    let
      errorTypeInfo = errorTypes.${errorType} or errorTypes.validation;
      severityInfo = severityLevels.${severity} or severityLevels.error;
    in
    {
      inherit message component errorType severity timestamp context suggestions;
      icon = errorTypeInfo.icon;
      color = errorTypeInfo.color;
      severityIcon = severityInfo.icon;
      severityColor = severityInfo.color;
      priority = severityInfo.priority;
      category = errorTypeInfo.category;
      id = builtins.hashString "sha256" "${component}-${errorType}-${message}";
    };

  # Format error for display
  formatError = error:
    let
      header = "${error.severityColor}${error.severityIcon} ${toUpper error.severity}${colors.reset}";
      componentLine = "${colors.bold}Component:${colors.reset} ${error.color}${error.icon} ${error.component}${colors.reset}";
      typeLine = "${colors.bold}Type:${colors.reset} ${error.color}${error.errorType}${colors.reset}";
      messageLine = "${colors.red}${error.message}${colors.reset}";

      contextSection = if error.context != {} then
        let
          contextLines = builtins.attrNames error.context;
          formatContextLine = key: "  ${key}: ${builtins.toString error.context.${key}}";
        in
        "\n\n${colors.cyan}Context:${colors.reset}\n" +
        builtins.concatStringsSep "\n" (map formatContextLine contextLines)
      else "";

      suggestionsSection = if error.suggestions != [] then
        let
          formatSuggestion = i: "  ${toString (i + 1)}. ${builtins.elemAt error.suggestions i}";
          indices = builtins.genList (x: x) (builtins.length error.suggestions);
        in
        "\n\n${colors.green}Suggestions:${colors.reset}\n" +
        builtins.concatStringsSep "\n" (map formatSuggestion indices)
      else "";
    in
    "${header}\n\n${componentLine}\n${typeLine}\n\n${messageLine}${contextSection}${suggestionsSection}";

  # Categorize error by type and create standardized error object
  categorizeError = errorType: message: attrs:
    let
      self = { inherit colors severityLevels errorTypes; } // {
        createError = { message, component ? "unknown", errorType ? "error", severity ? "error", timestamp ? getTimestamp, context ? {}, suggestions ? [] }:
          let
            errorTypeInfo = errorTypes.${errorType} or errorTypes.validation;
            severityInfo = severityLevels.${severity} or severityLevels.error;
          in
          {
            inherit message component errorType severity timestamp context suggestions;
            icon = errorTypeInfo.icon;
            color = errorTypeInfo.color;
            severityIcon = severityInfo.icon;
            severityColor = severityInfo.color;
            priority = severityInfo.priority;
            category = errorTypeInfo.category;
            id = builtins.hashString "sha256" "${component}-${errorType}-${message}";
          };
      };
    in
    self.createError ({
      inherit message errorType;
      component = attrs.component or "unknown";
      severity = attrs.severity or "error";
      context = attrs.context or {};
      suggestions = attrs.suggestions or [];
    } // attrs);

  # Add context information to an error
  addContext = error: newContext:
    error // {
      context = error.context // newContext;
    };

  # Add suggestion to an error
  addSuggestion = error: suggestion:
    error // {
      suggestions = error.suggestions ++ [ suggestion ];
    };

  # Log error to string format
  logError = error:
    let
      timestamp = error.timestamp or getTimestamp;
      logLine = "[${timestamp}] ${error.severity}: ${error.component} - ${error.message}";
      contextLog = if error.context != {} then
        let
          contextPairs = builtins.attrNames error.context;
          formatPair = key: "${key}=${builtins.toString error.context.${key}}";
        in
        " | " + builtins.concatStringsSep " " (map formatPair contextPairs)
      else "";
    in
    logLine + contextLog;

  # Try operation with fallback
  tryWithFallback = operation: input: fallback:
    let
      result = builtins.tryEval (operation input);
    in
    if result.success then result.value else fallback;

  # Chain multiple errors together
  chainErrors = errors:
    if builtins.isList errors then errors else [ errors ];

  # Filter errors by severity
  filterBySeverity = errors: minSeverity:
    let
      minPriority = severityLevels.${minSeverity}.priority or 0;
    in
    builtins.filter (error: error.priority >= minPriority) errors;

  # Group errors by category
  groupByCategory = errors:
    let
      categories = [ "system" "user" "external" ];
      filterByCategory = category: builtins.filter (error: error.category == category) errors;
    in
    builtins.listToAttrs (map (cat: { name = cat; value = filterByCategory cat; }) categories);

  # Validate error structure
  validateError = error:
    let
      requiredFields = [ "message" "component" "errorType" "severity" ];
      hasField = field: builtins.hasAttr field error;
      missingFields = builtins.filter (field: !(hasField field)) requiredFields;

      # Create self-reference for recursive call
      self = { inherit colors severityLevels errorTypes; } // {
        createError = { message, component ? "unknown", errorType ? "error", severity ? "error", timestamp ? getTimestamp, context ? {}, suggestions ? [] }:
          let
            errorTypeInfo = errorTypes.${errorType} or errorTypes.validation;
            severityInfo = severityLevels.${severity} or severityLevels.error;
          in
          {
            inherit message component errorType severity timestamp context suggestions;
            icon = errorTypeInfo.icon;
            color = errorTypeInfo.color;
            severityIcon = severityInfo.icon;
            severityColor = severityInfo.color;
            priority = severityInfo.priority;
            category = errorTypeInfo.category;
            id = builtins.hashString "sha256" "${component}-${errorType}-${message}";
          };
      };
    in
    if missingFields == [] then
      { valid = true; error = null; }
    else
      {
        valid = false;
        error = self.createError {
          message = "Invalid error structure: missing fields [${builtins.concatStringsSep ", " missingFields}]";
          component = "error-validation";
          errorType = "validation";
          severity = "error";
        };
      };

  # Create error from exception
  fromException = exception: component:
    let
      # Create self-reference for recursive call
      self = { inherit colors severityLevels errorTypes; } // {
        createError = { message, component ? "unknown", errorType ? "error", severity ? "error", timestamp ? getTimestamp, context ? {}, suggestions ? [] }:
          let
            errorTypeInfo = errorTypes.${errorType} or errorTypes.validation;
            severityInfo = severityLevels.${severity} or severityLevels.error;
          in
          {
            inherit message component errorType severity timestamp context suggestions;
            icon = errorTypeInfo.icon;
            color = errorTypeInfo.color;
            severityIcon = severityInfo.icon;
            severityColor = severityInfo.color;
            priority = severityInfo.priority;
            category = errorTypeInfo.category;
            id = builtins.hashString "sha256" "${component}-${errorType}-${message}";
          };
      };
    in
    self.createError {
      message = builtins.toString exception;
      inherit component;
      errorType = "build";
      severity = "error";
      context = { exception = builtins.toString exception; };
    };

  # Recovery mechanisms
  recovery = {
    # Retry with exponential backoff simulation
    retryWithBackoff = operation: maxAttempts: initialInput:
      let
        # Create self-reference for recursive call
        self = { inherit colors severityLevels errorTypes; } // {
          createError = { message, component ? "unknown", errorType ? "error", severity ? "error", timestamp ? getTimestamp, context ? {}, suggestions ? [] }:
            let
              errorTypeInfo = errorTypes.${errorType} or errorTypes.validation;
              severityInfo = severityLevels.${severity} or severityLevels.error;
            in
            {
              inherit message component errorType severity timestamp context suggestions;
              icon = errorTypeInfo.icon;
              color = errorTypeInfo.color;
              severityIcon = severityInfo.icon;
              severityColor = severityInfo.color;
              priority = severityInfo.priority;
              category = errorTypeInfo.category;
              id = builtins.hashString "sha256" "${component}-${errorType}-${message}";
            };
        };

        tryWithFallbackLocal = operation: input: fallback:
          let
            result = builtins.tryEval (operation input);
          in
          if result.success then result.value else fallback;

        attempt = n: input:
          if n >= maxAttempts then
            self.createError {
              message = "Max retry attempts (${toString maxAttempts}) exceeded";
              component = "retry-mechanism";
              errorType = "build";
              severity = "error";
            }
          else
            tryWithFallbackLocal operation input (attempt (n + 1) input);
      in
      attempt 0 initialInput;

    # Circuit breaker pattern simulation
    circuitBreaker = operation: input: threshold:
      let
        # Create self-reference for recursive call
        self = { inherit colors severityLevels errorTypes; } // {
          createError = { message, component ? "unknown", errorType ? "error", severity ? "error", timestamp ? getTimestamp, context ? {}, suggestions ? [] }:
            let
              errorTypeInfo = errorTypes.${errorType} or errorTypes.validation;
              severityInfo = severityLevels.${severity} or severityLevels.error;
            in
            {
              inherit message component errorType severity timestamp context suggestions;
              icon = errorTypeInfo.icon;
              color = errorTypeInfo.color;
              severityIcon = severityInfo.icon;
              severityColor = severityInfo.color;
              priority = severityInfo.priority;
              category = errorTypeInfo.category;
              id = builtins.hashString "sha256" "${component}-${errorType}-${message}";
            };
        };

        tryWithFallbackLocal = operation: input: fallback:
          let
            result = builtins.tryEval (operation input);
          in
          if result.success then result.value else fallback;
      in
      tryWithFallbackLocal operation input (self.createError {
        message = "Circuit breaker activated - operation failed too many times";
        component = "circuit-breaker";
        errorType = "build";
        severity = "warning";
        suggestions = [ "Wait before retrying" "Check system resources" ];
      });
  };

  # Error aggregation utilities
  aggregation = {
    # Summarize multiple errors
    summarizeErrors = errors:
      let
        totalCount = builtins.length errors;
        bySeverity = builtins.groupBy (error: error.severity) errors;
        severityCounts = builtins.mapAttrs (sev: errs: builtins.length errs) bySeverity;
      in
      {
        total = totalCount;
        counts = severityCounts;
        mostSevere = if totalCount > 0 then
          let
            priorities = map (error: error.priority) errors;
            maxPriority = builtins.foldl' builtins.max 0 priorities;
            mostSevereErrors = builtins.filter (error: error.priority == maxPriority) errors;
          in
          builtins.head mostSevereErrors
        else null;
      };

    # Create consolidated error report
    createReport = errors:
      let
        # Call summarizeErrors directly
        totalCount = builtins.length errors;
        bySeverity = builtins.groupBy (error: error.severity) errors;
        severityCounts = builtins.mapAttrs (sev: errs: builtins.length errs) bySeverity;
        summary = {
          total = totalCount;
          counts = severityCounts;
          mostSevere = if totalCount > 0 then
            let
              priorities = map (error: error.priority) errors;
              maxPriority = builtins.foldl' builtins.max 0 priorities;
              mostSevereErrors = builtins.filter (error: error.priority == maxPriority) errors;
            in
            builtins.head mostSevereErrors
          else null;
        };

        # Group by category function
        groupByCategory = errors:
          let
            categories = [ "system" "user" "external" ];
            filterByCategory = category: builtins.filter (error: error.category == category) errors;
          in
          builtins.listToAttrs (map (cat: { name = cat; value = filterByCategory cat; }) categories);

        grouped = groupByCategory errors;

        # Create self-reference for recursive call
        self = { inherit colors severityLevels errorTypes; } // {
          createError = { message, component ? "unknown", errorType ? "error", severity ? "error", timestamp ? getTimestamp, context ? {}, suggestions ? [] }:
            let
              errorTypeInfo = errorTypes.${errorType} or errorTypes.validation;
              severityInfo = severityLevels.${severity} or severityLevels.error;
            in
            {
              inherit message component errorType severity timestamp context suggestions;
              icon = errorTypeInfo.icon;
              color = errorTypeInfo.color;
              severityIcon = severityInfo.icon;
              severityColor = severityInfo.color;
              priority = severityInfo.priority;
              category = errorTypeInfo.category;
              id = builtins.hashString "sha256" "${component}-${errorType}-${message}";
            };

          formatError = error:
            let
              header = "${error.severityColor}${error.severityIcon} ${toUpper error.severity}${colors.reset}";
              componentLine = "${colors.bold}Component:${colors.reset} ${error.color}${error.icon} ${error.component}${colors.reset}";
              typeLine = "${colors.bold}Type:${colors.reset} ${error.color}${error.errorType}${colors.reset}";
              messageLine = "${colors.red}${error.message}${colors.reset}";

              contextSection = if error.context != {} then
                let
                  contextLines = builtins.attrNames error.context;
                  formatContextLine = key: "  ${key}: ${builtins.toString error.context.${key}}";
                in
                "\n\n${colors.cyan}Context:${colors.reset}\n" +
                builtins.concatStringsSep "\n" (map formatContextLine contextLines)
              else "";

              suggestionsSection = if error.suggestions != [] then
                let
                  formatSuggestion = i: "  ${toString (i + 1)}. ${builtins.elemAt error.suggestions i}";
                  indices = builtins.genList (x: x) (builtins.length error.suggestions);
                in
                "\n\n${colors.green}Suggestions:${colors.reset}\n" +
                builtins.concatStringsSep "\n" (map formatSuggestion indices)
              else "";
            in
            "${header}\n\n${componentLine}\n${typeLine}\n\n${messageLine}${contextSection}${suggestionsSection}";
        };
      in
      {
        inherit summary grouped;
        timestamp = getTimestamp;
        report = self.formatError (self.createError {
          message = "Error Report: ${toString summary.total} total errors";
          component = "error-aggregator";
          errorType = "build";
          severity = if summary.mostSevere != null then summary.mostSevere.severity else "info";
          context = summary.counts;
        });
      };
  };
}
