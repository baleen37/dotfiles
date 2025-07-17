# Error Handler System - Legacy Compatibility Wrapper
# Redirects to unified error-system.nix for consistency
# 에러 처리 시스템 - 통합된 error-system.nix로 리다이렉트

{
  # Error categorization
  errorType ? "user"
, # "build" | "config" | "dependency" | "user" | "system"
  # Component that failed
  component ? "unknown"
, # The actual error description
  message
, # Array of suggested solutions
  suggestions ? [ ]
, # Severity level
  severity ? "error"
, # "critical" | "error" | "warning" | "info"
  # Language preference
  locale ? "ko"
, # "ko" | "en"
  # Debug mode for detailed output
  debugMode ? false
, # Additional context information
  context ? { }
}:

let
  # Import unified error system
  errorSystem = import ./error-system.nix { };

  # Create error using new system
  error = errorSystem.createError {
    inherit message component errorType severity locale debugMode context suggestions;
  };

in
errorSystem.throwError error
