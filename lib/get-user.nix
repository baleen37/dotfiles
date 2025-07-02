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
  # Helper function to validate username format
  validateUser = username:
    if username == "" then false
    else if builtins.match "^[a-zA-Z0-9_][a-zA-Z0-9_-]{0,30}[a-zA-Z0-9_]$|^[a-zA-Z0-9_]$" username == null then false
    else true;

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

  # Read environment variables
  envValue = getEnvVar envVar; # read from USER environment variable
  sudoUser = getEnvVar "SUDO_USER"; # get original user when using sudo

  # Generate detailed error message with actionable steps
  generateErrorMsg = currentContext: ''
    Failed to detect valid user. Current context: ${currentContext}

    Please resolve by:
    1. Set USER environment variable: export USER=$(whoami)
    2. Or use --impure flag: nix build --impure
    3. Ensure you're not in a problematic sudo context

    Debug info:
    - Platform: ${currentPlatform}
    - envVar (${envVar}): "${envValue}"
    - SUDO_USER: "${sudoUser}"
    - allowSudoUser: ${if allowSudoUser then "true" else "false"}
    - mockEnv active: ${if mockEnv != { } then "true" else "false"}

    For more information, see CLAUDE.md
  '';

  # Debug logging helper (returns the user for chaining)
  debugLog = msg: user:
    if debugMode then builtins.trace "[get-user] ${msg}" user else user;

  # Validate and select user with security awareness
  selectUser =
    # First priority: SUDO_USER (if allowed and valid)
    if allowSudoUser && sudoUser != "" then
      if validateUser sudoUser then
        debugLog "Using SUDO_USER: ${sudoUser} (original user before sudo)" sudoUser
      else builtins.throw (generateErrorMsg "SUDO_USER invalid format: '${sudoUser}'")
    # Second priority: Environment variable (if valid)
    else if envValue != "" then
      if validateUser envValue then
        debugLog "Using ${envVar}: ${envValue}" envValue
      else builtins.throw (generateErrorMsg "${envVar} invalid format: '${envValue}'")
    # Third priority: Default value (if provided and valid)
    else if default != null then
      if validateUser default then
        debugLog "Using default: ${default}" default
      else builtins.throw (generateErrorMsg "default invalid format: '${default}'")
    # No valid user found
    else builtins.throw (generateErrorMsg "no valid user source found");

  # Utility function to get user home directory path
  getUserHomePath = user: platform:
    if platform == "darwin" then "/Users/${user}"
    else if platform == "linux" then "/home/${user}"
    else throw "Unsupported platform: ${platform}";

  # Main result with user and helper functions
  result = {
    # The resolved user name
    user = selectUser;

    # Get home directory path for the user
    homePath = getUserHomePath selectUser currentPlatform;

    # Get platform-specific user configuration
    userConfig = {
      name = selectUser;
      home = getUserHomePath selectUser currentPlatform;
      platform = currentPlatform;
    };

    # Legacy compatibility - just return the user string when used as string
    __toString = self: selectUser;
  };

in
# Return just the user string for full backward compatibility
selectUser
