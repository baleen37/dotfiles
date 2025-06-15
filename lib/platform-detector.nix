# Platform Detection System
# 현재 플랫폼 감지 및 빌드 최적화를 위한 시스템

{
  # Override platform detection (for testing)
  overridePlatform ? null
, # Override architecture detection (for testing)
  overrideArch ? null
, # Enable debug output
  debugMode ? false
}:

let
  # Get current system from Nix
  nixSystem = builtins.currentSystem or "unknown";

  # Extract platform and architecture from Nix system
  systemParts = builtins.split "-" nixSystem;
  detectedArch = if builtins.length systemParts >= 1 then builtins.head systemParts else "unknown";
  detectedPlatform = if builtins.length systemParts >= 3 then builtins.elemAt systemParts 2 else "unknown";

  # Apply overrides if provided
  currentArch = if overrideArch != null then overrideArch else detectedArch;
  currentPlatform = if overridePlatform != null then overridePlatform else detectedPlatform;
  currentSystem = "${currentArch}-${currentPlatform}";

  # Supported platforms and architectures
  supportedPlatforms = [ "darwin" "linux" ];
  supportedArchs = [ "x86_64" "aarch64" ];
  supportedSystems = [
    "x86_64-darwin"
    "aarch64-darwin"
    "x86_64-linux"
    "aarch64-linux"
  ];

  # Validation functions
  isValidPlatform = platform: builtins.elem platform supportedPlatforms;
  isValidArch = arch: builtins.elem arch supportedArchs;
  isValidSystem = system: builtins.elem system supportedSystems;

  # Platform checks
  isDarwin = currentPlatform == "darwin";
  isLinux = currentPlatform == "linux";
  isX86_64 = currentArch == "x86_64";
  isAarch64 = currentArch == "aarch64";

  # Build optimization hints
  buildOptimizations = {
    # Platform-specific build flags
    darwin = {
      extraArgs = [ "--option" "system-features" "nixos-test" ];
      parallelism = "auto";
      substituters = [ "https://cache.nixos.org" "https://nix-community.cachix.org" ];
    };
    linux = {
      extraArgs = [ "--option" "sandbox" "true" ];
      parallelism = "auto";
      substituters = [ "https://cache.nixos.org" ];
    };
  };

  # Get platform-specific optimizations
  getCurrentOptimizations =
    if builtins.hasAttr currentPlatform buildOptimizations
    then buildOptimizations.${currentPlatform}
    else { extraArgs = [ ]; parallelism = "auto"; substituters = [ ]; };

  # Debug information
  debugInfo = {
    nixSystem = nixSystem;
    detectedArch = detectedArch;
    detectedPlatform = detectedPlatform;
    currentArch = currentArch;
    currentPlatform = currentPlatform;
    currentSystem = currentSystem;
    overrides = {
      platform = overridePlatform;
      arch = overrideArch;
    };
    validations = {
      validPlatform = isValidPlatform currentPlatform;
      validArch = isValidArch currentArch;
      validSystem = isValidSystem currentSystem;
    };
  };

  # Error handling
  validateCurrentSystem =
    if !isValidSystem currentSystem then
      builtins.throw ''
        ❌ Unsupported system detected: ${currentSystem}

        🖥️  Supported systems:
          ${builtins.concatStringsSep "\n  " supportedSystems}

        🔍 Detection details:
          - Nix system: ${nixSystem}
          - Detected arch: ${detectedArch}
          - Detected platform: ${detectedPlatform}
          - Current arch: ${currentArch}
          - Current platform: ${currentPlatform}

        💡 해결 방법:
          1. 지원되는 시스템에서 실행하세요
          2. --override-platform=<platform> 옵션 사용
          3. --override-arch=<arch> 옵션 사용
      ''
    else currentSystem;

  # Main API functions
  api = {
    # Core detection functions
    getCurrentPlatform = currentPlatform;
    getCurrentArch = currentArch;
    getCurrentSystem = validateCurrentSystem;

    # Boolean checks
    isPlatform = platform: currentPlatform == platform;
    isArch = arch: currentArch == arch;
    isDarwin = isDarwin;
    isLinux = isLinux;
    isX86_64 = isX86_64;
    isAarch64 = isAarch64;

    # Validation functions
    validatePlatform = isValidPlatform;
    validateArch = isValidArch;
    validateSystem = isValidSystem;

    # Build optimization
    getOptimizations = getCurrentOptimizations;

    # Supported values
    getSupportedPlatforms = supportedPlatforms;
    getSupportedArchs = supportedArchs;
    getSupportedSystems = supportedSystems;

    # Debug information
    getDebugInfo = if debugMode then debugInfo else { };

    # Utility functions
    getOtherPlatforms = builtins.filter (p: p != currentPlatform) supportedPlatforms;
    getOtherArchs = builtins.filter (a: a != currentArch) supportedArchs;
    getOtherSystems = builtins.filter (s: s != currentSystem) supportedSystems;

    # Build target helpers
    getCurrentTarget = currentSystem;
    getAllTargets = supportedSystems;
    getCrossTargets = builtins.filter (s: s != currentSystem) supportedSystems;
  };

in
api
