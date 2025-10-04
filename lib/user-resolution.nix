# Simplified User Resolution System
# Provides cross-platform user detection with minimal complexity
#
# Key Features:
# - Dynamic user detection from USER or SUDO_USER environment variables
# - Username validation against POSIX standards
# - Cross-platform home directory path resolution (macOS/Linux)
# - Flexible return formats (string or extended with metadata)
# - Mock environment support for testing
#
# Usage Examples:
# - Basic: import ./user-resolution.nix { }  # Returns username string
# - Extended: import ./user-resolution.nix { returnFormat = "extended"; }
# - With default: import ./user-resolution.nix { default = "fallback-user"; }

{ envVar ? "USER"
, default ? null
, allowSudoUser ? true
, returnFormat ? "string"
, platform ? null
, mockEnv ? { }
, pkgs ? null
, lib ? null
,
}:

let
  # Determine lib with fallback for error handling
  actualLib =
    if lib != null then
      lib
    else if pkgs != null then
      pkgs.lib
    else
      null;

  # Import error system for consistent error handling
  errorSystem =
    if pkgs != null then
      import ./error-system.nix { inherit pkgs lib; }
    else
      {
        throwUserError = msg: builtins.throw "User Error: ${msg}";
      };

  # Environment variable reading (supports mocking for tests)
  getEnvVar = var: if builtins.hasAttr var mockEnv then mockEnv.${var} else builtins.getEnv var;

  # Validate username format
  validateUser =
    username:
    username != ""
    && username != null
    && builtins.match "^[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,30}[a-zA-Z0-9_]$|^[a-zA-Z0-9_]$" username != null;

  # Detect platform if not provided
  currentPlatform =
    if platform != null then
      platform
    else if builtins ? currentSystem then
      if builtins.match ".*-darwin" builtins.currentSystem != null then "darwin" else "linux"
    else
      "unknown";

  # Read environment variables
  envValue = getEnvVar envVar;
  sudoUser = getEnvVar "SUDO_USER";

  # Resolve user with priority: SUDO_USER > envVar > default
  resolveUser =
    if allowSudoUser && sudoUser != "" && validateUser sudoUser then
      sudoUser
    else if envValue != "" && validateUser envValue then
      envValue
    else if default != null && validateUser default then
      default
    else
      errorSystem.throwUserError ''
        Failed to detect valid user.
        Set USER environment variable: export USER=$(whoami)
        Or use --impure flag: nix build --impure
      '';

  # Get home directory path
  getUserHomePath =
    user: platform: if platform == "darwin" then "/Users/${user}" else "/home/${user}";

  # Extended result with additional metadata
  homePath = getUserHomePath resolveUser currentPlatform;
  extendedResult = {
    user = resolveUser;
    inherit homePath;
    platform = currentPlatform;
    # Legacy compatibility: paths.home for old code
    paths = {
      home = homePath;
    };
    __toString = self: resolveUser;
  };

in
# Return format based on returnFormat parameter
if returnFormat == "extended" then extendedResult else resolveUser
