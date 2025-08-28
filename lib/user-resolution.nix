# User Resolution System for Dotfiles
# Provides consistent user detection across different environments

{ system ? builtins.currentSystem, pkgs ? null, lib ? null }:

let
  # Get environment variable value
  envValue = builtins.getEnv "USER";

  # Check if environment variable is set and non-empty
  hasEnvUser = envValue != "";

  # Resolve the current user using various methods
  resolvedUser =
    if hasEnvUser then
      envValue
    else
    # Fallback to default user if env var is not available
      "user";

  # Validate user exists (basic check)
  validateUserFn = user: user != "" && user != null;

in
{
  # Environment variable to check (default: "USER")
  envVar = "USER";

  # Fallback methods for user resolution
  fallbackMethods = [
    "whoami"
    "id -un"
    "logname"
  ];

  # Default user (used when all methods fail)
  defaultUser = "user";

  # Resolve the current user using various methods
  resolveUser = resolvedUser;

  # Get the user for system configuration
  getSystemUser =
    let
      resolved = resolvedUser;
    in
    if resolved != "" then resolved else "user";

  # Check if user resolution is working
  isResolved = resolvedUser != "user" && resolvedUser != "";

  # Get user home directory path (platform-aware)
  getUserHome =
    let
      user = resolvedUser;
      isDarwin = builtins.match ".*darwin.*" system != null;
    in
    if isDarwin then
      "/Users/${user}"
    else
      "/home/${user}";

  # Validate user exists (basic check)
  validateUser = validateUserFn;

  # Get all user information
  getUserInfo = {
    username = resolvedUser;
    homeDir = "/Users/${resolvedUser}"; # Simplified for now
    isValid = validateUserFn resolvedUser;
    isResolved = resolvedUser != "user" && resolvedUser != "";
    system = system;
    method = if builtins.getEnv "USER" != "" then "environment" else "fallback";
  };

  # Debug information
  debugInfo = {
    envVar = builtins.getEnv "USER";
    resolvedUser = resolvedUser;
    systemUser = resolvedUser;
    homeDir = "/Users/${resolvedUser}";
    platform = system;
    isValid = validateUserFn resolvedUser;
  };
}
