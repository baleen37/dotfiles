# Enhanced Error Handling System - Legacy Compatibility Wrapper
# Redirects to unified error-system.nix
# Provides standardized error processing, logging, and recovery mechanisms

{ pkgs, lib ? pkgs.lib }:

let
  # Import unified error system
  errorSystem = import ./error-system.nix { inherit pkgs lib; };

in
# Re-export all functions from the unified system
errorSystem // {
  # Legacy function names for backward compatibility
  inherit (errorSystem) createError formatError;
  inherit (errorSystem.utils) tryWithFallback validateError;

  # Legacy structured exports
  recovery = {
    retryWithBackoff = operation: maxAttempts: initialInput:
      errorSystem.utils.tryWithFallback operation initialInput null;
    circuitBreaker = operation: input: threshold:
      errorSystem.utils.tryWithFallback operation input null;
  };

  aggregation = {
    summarizeErrors = errorSystem.aggregateErrors;
    createReport = errors:
      let summary = errorSystem.aggregateErrors errors;
      in {
        inherit summary;
        timestamp = builtins.toString (builtins.currentTime or 0);
        report = errorSystem.formatError (errorSystem.createError {
          message = "Error Report: ${toString summary.total} total errors";
          component = "error-aggregator";
          errorType = "build";
          severity = if summary.mostSevere != null then summary.mostSevere.severity else "info";
          context = summary.counts.severity;
        });
      };
  };
}
