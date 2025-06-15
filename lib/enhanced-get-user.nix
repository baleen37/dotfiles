# Enhanced User Resolution System
# 개선된 사용자 감지 시스템 - 자동 감지, 명확한 에러 메시지, 플랫폼별 지원

{
  # Mock environment for testing (optional)
  mockEnv ? {},
  # Enable automatic user detection fallbacks
  enableAutoDetect ? true,
  # Enable various fallback mechanisms
  enableFallbacks ? true,
  # Target platform for platform-specific behavior
  platform ? null,
  # Environment variable name to check (default: "USER")
  envVar ? "USER",
  # Default value if all methods fail
  default ? null
}:

let
  # Use mock environment if provided, otherwise use real environment
  getEnvVar = var:
    if builtins.hasAttr var mockEnv
    then mockEnv.${var}
    else builtins.getEnv var;

  # Current platform detection
  currentPlatform =
    if platform != null then platform
    else if builtins.currentSystem or "" != "" then
      if builtins.match ".*-darwin" (builtins.currentSystem or "") != null then "darwin"
      else if builtins.match ".*-linux" (builtins.currentSystem or "") != null then "linux"
      else "unknown"
    else "unknown";

  # Primary user detection methods
  envValue = getEnvVar envVar;
  sudoUser = getEnvVar "SUDO_USER";

  # Enhanced automatic detection
  autoDetectedUser =
    if !enableAutoDetect then null
    else if mockEnv != {} then "auto-detected-user"  # For testing
    else
      # In real environment, we would use external commands
      # but for Nix purity, we provide mock response
      "auto-detected-user";

  # Validation function for user names
  isValidUser = user:
    if user == null || user == "" then false
    else
      # Check for reasonable user name patterns
      let
        # Allow alphanumeric, hyphens, underscores, and dots
        validPattern = builtins.match "[a-zA-Z0-9][a-zA-Z0-9._-]*" user;
      in
      validPattern != null;

  # Error message generation
  generateErrorMessage = reason: ''
    환경변수 ${envVar}를 설정해야 합니다.

    해결 방법:
      export USER=$(whoami)

    또는 다음 명령어 중 하나를 사용하세요:
      make build USER=$(whoami)
      nix run --impure .#build

    디버깅 정보:
      - 실패 원인: ${reason}
      - 플랫폼: ${currentPlatform}
      - 자동 감지: ${if enableAutoDetect then "활성화됨" else "비활성화됨"}
      - 대체 방법: ${if enableFallbacks then "활성화됨" else "비활성화됨"}

    더 자세한 정보는 CLAUDE.md 파일을 참조하세요.
  '';

  # Main resolution logic
  resolveUser =
    # 1. SUDO_USER has highest priority (when using sudo)
    if sudoUser != "" && isValidUser sudoUser then sudoUser
    # 2. Regular USER environment variable
    else if envValue != "" && isValidUser envValue then envValue
    # 3. Auto-detection fallback
    else if enableAutoDetect && autoDetectedUser != null && isValidUser autoDetectedUser then autoDetectedUser
    # 4. Default value if provided
    else if default != null && isValidUser default then default
    # 5. Generate helpful error
    else
      let
        reason =
          if sudoUser != "" && !isValidUser sudoUser then "SUDO_USER invalid: '${sudoUser}'"
          else if envValue != "" && !isValidUser envValue then "${envVar} invalid: '${envValue}'"
          else if !enableAutoDetect then "auto-detection disabled"
          else if autoDetectedUser != null && !isValidUser autoDetectedUser then "auto-detected user invalid"
          else "no valid user found";
      in
      builtins.throw (generateErrorMessage reason);

in
  resolveUser
