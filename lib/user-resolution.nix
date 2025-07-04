# Unified User Resolution System
# Consolidates functionality from get-user.nix, enhanced-get-user.nix, and get-user-extended.nix
#
# This is the single source of truth for user resolution across the entire dotfiles system.
# It provides backward compatibility while unifying the three separate user resolution systems.
#
# Usage:
#   Basic string return: (import ./user-resolution.nix) {}
#   Extended return:     (import ./user-resolution.nix) { returnFormat = "extended"; }
#
# Parameters:
#   - envVar: Environment variable to read (default: "USER")
#   - default: Default user if environment detection fails
#   - allowSudoUser: Whether to fall back to SUDO_USER (default: true)
#   - debugMode: Enable debug output (default: false)
#   - mockEnv: Mock environment for testing (default: {})
#   - platform: Target platform ("darwin" or "linux", auto-detected if null)
#   - enableAutoDetect: Enable automatic user detection fallbacks (default: true)
#   - enableFallbacks: Enable fallback mechanisms (default: true)
#   - returnFormat: "string" for simple user string, "extended" for structured data (default: "string")

{
  envVar ? "USER",
  default ? null,
  allowSudoUser ? true,
  debugMode ? false,
  mockEnv ? { },
  platform ? null,
  enableAutoDetect ? true,
  enableFallbacks ? true,
  returnFormat ? "string"
}:

let
  # Import necessary libraries
  lib = import <nixpkgs/lib>;

  # Environment variable resolution with mock support
  getEnvVar = var:
    if mockEnv != { } && builtins.hasAttr var mockEnv
    then mockEnv.${var}
    else builtins.getEnv var;

  # Platform detection
  detectedPlatform =
    if platform != null then platform
    else if builtins.pathExists "/System/Library/CoreServices/SystemVersion.plist" then "darwin"
    else "linux";

  # Debug logging function
  debugLog = msg:
    if debugMode then builtins.trace "[DEBUG] User Resolution: ${msg}" null
    else null;

  # User validation function
  isValidUser = user:
    user != null && user != "" &&
    builtins.match "^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$" user != null;

  # Core user resolution logic
  resolveUser =
    let
      # Primary resolution attempt
      primaryUser = getEnvVar envVar;

      # SUDO_USER fallback (if enabled)
      sudoUser = if allowSudoUser then getEnvVar "SUDO_USER" else null;

      # Auto-detection fallback (if enabled)
      autoDetectedUser =
        if enableAutoDetect then
          # Try to detect from system (this would need external commands in real usage)
          null  # Simplified for now - would use external detection methods
        else null;

      # Apply fallback chain
      candidateUser =
        if primaryUser != null && primaryUser != "" then primaryUser
        else if allowSudoUser && sudoUser != null && sudoUser != "" then sudoUser
        else if enableFallbacks && autoDetectedUser != null then autoDetectedUser
        else if default != null then default
        else null;
    in
    candidateUser;

  # Get the resolved user
  resolvedUser = resolveUser;

  # Validation
  validatedUser =
    if resolvedUser != null && isValidUser resolvedUser then resolvedUser
    else null;

  # Error handling
  finalUser =
    if validatedUser != null then validatedUser
    else throw ''
      Failed to detect valid user.

      Environment variable ${envVar} is ${if getEnvVar envVar == "" then "empty" else "not set"}.
      ${if allowSudoUser && getEnvVar "SUDO_USER" != "" then "SUDO_USER is set to: " + getEnvVar "SUDO_USER" else ""}

      To fix this issue:
      1. Set the environment variable: export ${envVar}=$(whoami)
      2. Or run with --impure flag: nix run --impure
      3. Or set a default user in your configuration

      This error occurs because Nix requires explicit environment variable access
      for reproducible builds.
    '';

  # Home path resolution
  homePath =
    if detectedPlatform == "darwin" then "/Users/${finalUser}"
    else "/home/${finalUser}";

  # User configuration object (for extended format)
  userConfig = {
    name = finalUser;
    home = homePath;
    platform = detectedPlatform;
    configHome =
      if detectedPlatform == "darwin" then "${homePath}/.config"
      else "${homePath}/.config";
    environment = {
      USER = finalUser;
      HOME = homePath;
    };
  };

  # Debug output
  _ = if debugMode then [
    (debugLog "Platform: ${detectedPlatform}")
    (debugLog "Environment variable ${envVar}: ${getEnvVar envVar}")
    (debugLog "Final user: ${finalUser}")
    (debugLog "Home path: ${homePath}")
  ] else null;

in
# Return based on format
if returnFormat == "extended" then {
  user = finalUser;
  homePath = homePath;
  userConfig = userConfig;
  platform = detectedPlatform;
}
else finalUser
