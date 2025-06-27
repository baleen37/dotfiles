{ envVar ? "USER", default ? null, allowSudoUser ? true, debugMode ? false }:
let
  # Helper function to validate username format
  validateUser = username:
    if username == "" then false
    else if builtins.match "^[a-zA-Z0-9_][a-zA-Z0-9_-]{0,30}[a-zA-Z0-9_]$|^[a-zA-Z0-9_]$" username == null then false
    else true;

  # Read environment variables
  envValue = builtins.getEnv envVar; # read from USER environment variable
  sudoUser = builtins.getEnv "SUDO_USER"; # get original user when using sudo

  # Generate detailed error message with actionable steps
  generateErrorMsg = currentContext: ''
    Failed to detect valid user. Current context: ${currentContext}

    Please resolve by:
    1. Set USER environment variable: export USER=$(whoami)
    2. Or use --impure flag: nix build --impure
    3. Ensure you're not in a problematic sudo context

    Debug info:
    - envVar (${envVar}): "${envValue}"
    - SUDO_USER: "${sudoUser}"
    - allowSudoUser: ${if allowSudoUser then "true" else "false"}
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

in
selectUser
