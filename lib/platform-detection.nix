# Centralized Platform Detection Utility
# Provides optimized, cached platform detection functions
# Replaces duplicate platform detection patterns across the codebase

{
  system ? null,
  pkgs ? null,
  lib ? null,
}:

let
  # Import error system for better error handling
  errorSystem =
    if pkgs != null then
      import ./error-system.nix { inherit pkgs lib; }
    else
      {
        throwUserError = msg: throw "User Error: ${msg}";
        throwValidationError = msg: throw "Validation Error: ${msg}";
      };

  # Determine the system string to use
  currentSystem =
    if system != null then
      system
    else if pkgs != null && pkgs ? system then
      pkgs.system
    else
      builtins.currentSystem or "unknown";

  # Core pattern matching functions (cached results)
  patterns = rec {
    # Darwin platform detection
    isDarwinSystem = builtins.match ".*-darwin" currentSystem != null;

    # Linux platform detection
    isLinuxSystem = builtins.match ".*-linux" currentSystem != null;

    # Architecture detection
    isX86_64System = builtins.match "x86_64-.*" currentSystem != null;
    isAarch64System = builtins.match "aarch64-.*" currentSystem != null;
  };

  # Derived platform information (cached)
  platformInfo = rec {
    # Platform identification
    platform =
      if patterns.isDarwinSystem then
        "darwin"
      else if patterns.isLinuxSystem then
        "linux"
      else
        "unknown";

    # Architecture identification
    arch =
      if patterns.isX86_64System then
        "x86_64"
      else if patterns.isAarch64System then
        "aarch64"
      else
        "unknown";

    # System string
    system = currentSystem;

    # Platform boolean flags (for detection functions)
    isDarwin = patterns.isDarwinSystem;
    isLinux = patterns.isLinuxSystem;

    # Validation flags
    isValidPlatform = platform != "unknown";
    isValidArch = arch != "unknown";
    isSupported = isValidPlatform && isValidArch;
  };

  # Platform detection functions for external use
  detection = {
    # Primary detection functions (optimized - use cached results)
    isDarwin =
      system_input:
      if system_input == currentSystem then
        platformInfo.isDarwin
      else
        builtins.match ".*-darwin" system_input != null;

    isLinux =
      system_input:
      if system_input == currentSystem then
        platformInfo.isLinux
      else
        builtins.match ".*-linux" system_input != null;

    isX86_64 =
      system_input:
      if system_input == currentSystem then
        platformInfo.isX86_64
      else
        builtins.match "x86_64-.*" system_input != null;

    isAarch64 =
      system_input:
      if system_input == currentSystem then
        platformInfo.isAarch64
      else
        builtins.match "aarch64-.*" system_input != null;

    # Platform string extraction
    getPlatform =
      system_input:
      if system_input == currentSystem then
        platformInfo.platform
      else if detection.isDarwin system_input then
        "darwin"
      else if detection.isLinux system_input then
        "linux"
      else
        errorSystem.throwValidationError "Unknown platform in system: ${system_input}";

    # Architecture string extraction
    getArch =
      system_input:
      if system_input == currentSystem then
        platformInfo.arch
      else if detection.isX86_64 system_input then
        "x86_64"
      else if detection.isAarch64 system_input then
        "aarch64"
      else
        errorSystem.throwValidationError "Unknown architecture in system: ${system_input}";

    # System validation
    validateSystem =
      system_input:
      let
        isValid =
          (detection.isDarwin system_input || detection.isLinux system_input)
          && (detection.isX86_64 system_input || detection.isAarch64 system_input);
      in
      if !isValid then
        errorSystem.throwValidationError "Invalid system string: ${system_input}"
      else
        system_input;
  };

  # Cross-platform utilities
  crossPlatform = {
    # Conditional execution based on platform
    whenDarwin = value: if platformInfo.isDarwin then value else null;
    whenLinux = value: if platformInfo.isLinux then value else null;
    whenX86_64 = value: if platformInfo.isX86_64 then value else null;
    whenAarch64 = value: if platformInfo.isAarch64 then value else null;

    # Platform-specific value selection
    platformSpecific =
      values:
      if builtins.hasAttr platformInfo.platform values then
        values.${platformInfo.platform}
      else if builtins.hasAttr "default" values then
        values.default
      else
        errorSystem.throwUserError "No value for platform ${platformInfo.platform} and no default provided";

    # Architecture-specific value selection
    archSpecific =
      values:
      if builtins.hasAttr platformInfo.arch values then
        values.${platformInfo.arch}
      else if builtins.hasAttr "default" values then
        values.default
      else
        errorSystem.throwUserError "No value for architecture ${platformInfo.arch} and no default provided";
  };

  # Performance monitoring (for debugging)
  performance = {
    cacheHitCount = 0; # Would be incremented in real usage
    totalQueries = 0; # Would be incremented in real usage
    cacheEfficiency =
      if performance.totalQueries > 0 then
        (performance.cacheHitCount / performance.totalQueries * 100.0)
      else
        0.0;
  };

in
{
  # Export current platform information (cached results)
  inherit (platformInfo) platform arch system;
  inherit (platformInfo) isValidPlatform isValidArch isSupported;

  # Export detection functions
  inherit detection;
  inherit (detection) getPlatform getArch validateSystem;

  # Export convenience functions (for common patterns)
  inherit crossPlatform;

  # Legacy compatibility (direct function exports)
  inherit (detection) isDarwin;
  inherit (detection) isLinux;
  inherit (detection) isX86_64;
  inherit (detection) isAarch64;

  # Performance and metadata
  inherit performance;
  version = "1.0.0-optimized";
  description = "Centralized platform detection with caching optimization";

  # Supported configurations
  supportedPlatforms = [
    "darwin"
    "linux"
  ];
  supportedArchitectures = [
    "x86_64"
    "aarch64"
  ];
  supportedSystems = [
    "x86_64-darwin"
    "aarch64-darwin"
    "x86_64-linux"
    "aarch64-linux"
  ];

  # Platform information record (for structured access)
  info = platformInfo;

  # Validation utilities
  validate = {
    platform =
      platform:
      builtins.elem platform [
        "darwin"
        "linux"
      ];
    arch =
      arch:
      builtins.elem arch [
        "x86_64"
        "aarch64"
      ];
    system =
      system:
      builtins.elem system [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
  };
}
