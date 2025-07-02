# Extended User Resolution System
# Provides enhanced user resolution with platform-specific utilities
# Use this when you need more than just the username string

{
  # Environment variable to check (default: "USER")
  envVar ? "USER",
  # Default value if all methods fail
  default ? null,
  # Whether to allow SUDO_USER as a valid source
  allowSudoUser ? true,
  # Enable debug output
  debugMode ? false,
  # Mock environment for testing (optional)
  mockEnv ? { },
  # Target platform for platform-specific behavior
  platform ? null
}:

let
  # Import the base user resolution
  getUser = import ./get-user.nix {
    inherit envVar default allowSudoUser debugMode mockEnv platform;
  };

  # Environment variable reading function (supports mocking for tests)
  getEnvVar = var:
    if builtins.hasAttr var mockEnv
    then mockEnv.${var}
    else builtins.getEnv var;

  # Platform detection
  currentPlatform =
    if platform != null then platform
    else if builtins.currentSystem or "" != "" then
      if builtins.match ".*-darwin" (builtins.currentSystem or "") != null then "darwin"
      else if builtins.match ".*-linux" (builtins.currentSystem or "") != null then "linux"
      else "unknown"
    else "unknown";

  # Utility function to get user home directory path
  getUserHomePath = user: platform:
    if platform == "darwin" then "/Users/${user}"
    else if platform == "linux" then "/home/${user}"
    else throw "Unsupported platform: ${platform}";

in
{
  # The resolved user name
  user = getUser;

  # Get home directory path for the user
  homePath = getUserHomePath getUser currentPlatform;

  # Get platform-specific user configuration
  userConfig = {
    name = getUser;
    home = getUserHomePath getUser currentPlatform;
    platform = currentPlatform;
  };

  # Platform information
  platform = currentPlatform;

  # Utility functions
  utils = {
    # Get config directory path
    getConfigPath = "${getUserHomePath getUser currentPlatform}/.config";

    # Get SSH directory path
    getSshPath = "${getUserHomePath getUser currentPlatform}/.ssh";

    # Check if platform is Darwin
    isDarwin = currentPlatform == "darwin";

    # Check if platform is Linux
    isLinux = currentPlatform == "linux";
  };
}
