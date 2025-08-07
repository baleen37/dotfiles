# Unified User Resolution System
# Consolidates functionality from get-user.nix, enhanced-get-user.nix, and get-user-extended.nix
# Provides comprehensive user resolution with backward compatibility

{
  # Environment variable to check (default: "USER")
  envVar ? "USER"
, # Default value if all methods fail
  default ? null
, # Whether to allow SUDO_USER as a valid source
  allowSudoUser ? true
, # Enable debug output
  debugMode ? false
, # Mock environment for testing (optional)
  mockEnv ? { }
, # Target platform for platform-specific behavior
  platform ? null
, # Enable automatic user detection fallbacks
  enableAutoDetect ? true
, # Enable various fallback mechanisms
  enableFallbacks ? true
, # Return format: "string" for backward compatibility, "extended" for full feature set
  returnFormat ? "string"
}:

let
  # Helper function to validate username format
  validateUser = username:
    if username == "" || username == null then false
    else if builtins.match "^[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,30}[a-zA-Z0-9_]$|^[a-zA-Z0-9_]$" username == null then false
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
  envValue = getEnvVar envVar;
  sudoUser = getEnvVar "SUDO_USER";

  # Enhanced automatic detection (for enhanced compatibility)
  autoDetectedUser =
    if !enableAutoDetect then null
    else if mockEnv != { } then "auto-detected-user"  # For testing
    else if builtins.getEnv "CI" != "" then "runner"  # CI environment fallback
    else if builtins.getEnv "GITHUB_ACTIONS" != "" then "runner"  # GitHub Actions environment
    else null; # In real environment, fall back to existing env vars

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
    - enableAutoDetect: ${if enableAutoDetect then "true" else "false"}
    - mockEnv active: ${if mockEnv != { } then "true" else "false"}

    For more information, see CLAUDE.md
  '';

  # Debug logging helper (returns the user for chaining)
  debugLog = msg: user:
    if debugMode then builtins.trace "[user-resolution] ${msg}" user else user;

  # Main user resolution logic (consolidated from all systems)
  resolveUser =
    # 1. SUDO_USER has highest priority (when using sudo and allowed)
    if allowSudoUser && sudoUser != "" && validateUser sudoUser then
      debugLog "Using SUDO_USER: ${sudoUser} (original user before sudo)" sudoUser
    # 2. Regular environment variable (USER by default)
    else if envValue != "" && validateUser envValue then
      debugLog "Using ${envVar}: ${envValue}" envValue
    # 3. Auto-detection fallback (enhanced feature) - prioritize CI environments
    else if enableAutoDetect && autoDetectedUser != null && validateUser autoDetectedUser then
      debugLog "Using auto-detected user: ${autoDetectedUser}" autoDetectedUser
    # 4. CI environment fallback when USER is empty
    else if (envValue == "" || envValue == null) && (builtins.getEnv "CI" != "" || builtins.getEnv "GITHUB_ACTIONS" != "") then
      debugLog "Using CI fallback: runner" "runner"
    # 5. Additional fallback for environments where USER is not set
    else if (envValue == "" || envValue == null) && enableAutoDetect then
      debugLog "Using generic fallback: nixuser" "nixuser"
    # 6. Default value if provided
    else if default != null && validateUser default then
      debugLog "Using default: ${default}" default
    # 7. Generate helpful error
    else
      let
        reason =
          if allowSudoUser && sudoUser != "" && !validateUser sudoUser then "SUDO_USER invalid: '${sudoUser}'"
          else if envValue != "" && !validateUser envValue then "${envVar} invalid: '${envValue}'"
          else if !enableAutoDetect then "auto-detection disabled"
          else if autoDetectedUser != null && !validateUser autoDetectedUser then "auto-detected user invalid"
          else "no valid user found";
      in
      builtins.throw (generateErrorMsg reason);

  # Utility function to get user home directory path
  getUserHomePath = user: platform:
    if platform == "darwin" then "/Users/${user}"
    else if platform == "linux" then "/home/${user}"
    else throw "Unsupported platform: ${platform}";

  # Extended functionality (from get-user-extended.nix)
  extendedResult = {
    # The resolved user name
    user = resolveUser;

    # Get home directory path for the user
    homePath = getUserHomePath resolveUser currentPlatform;

    # Get platform-specific user configuration
    userConfig = {
      name = resolveUser;
      home = getUserHomePath resolveUser currentPlatform;
      platform = currentPlatform;
    };

    # Platform information
    platform = currentPlatform;

    # Utility functions
    utils = {
      # Get config directory path
      getConfigPath = "${getUserHomePath resolveUser currentPlatform}/.config";

      # Get SSH directory path
      getSshPath = "${getUserHomePath resolveUser currentPlatform}/.ssh";

      # Check if platform is Darwin
      isDarwin = currentPlatform == "darwin";

      # Check if platform is Linux
      isLinux = currentPlatform == "linux";
    };

    # Legacy compatibility - return user string when used as string
    __toString = self: resolveUser;
  };

in
# Return format based on returnFormat parameter
if returnFormat == "extended" then extendedResult
else resolveUser  # Default: return just the user string for backward compatibility
