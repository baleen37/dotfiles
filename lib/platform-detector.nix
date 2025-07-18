# Platform Detection System - Legacy Compatibility Wrapper
# Redirects to unified platform-system.nix
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
  # Import unified platform system
  platformSystem = import ./platform-system.nix { };

  # Apply overrides if provided
  actualArch = if overrideArch != null then overrideArch else platformSystem.arch;
  actualPlatform = if overridePlatform != null then overridePlatform else platformSystem.platform;
  actualSystem = "${actualArch}-${actualPlatform}";

  # Override detection results if needed
  overriddenSystem = if overridePlatform != null || overrideArch != null then {
    arch = actualArch;
    platform = actualPlatform;
    system = actualSystem;
    isDarwin = actualPlatform == "darwin";
    isLinux = actualPlatform == "linux";
    isX86_64 = actualArch == "x86_64";
    isAarch64 = actualArch == "aarch64";
    isValidPlatform = platformSystem.validate.platform actualPlatform;
    isValidArch = platformSystem.validate.arch actualArch;
    isValidSystem = platformSystem.validate.system actualSystem;
  } else platformSystem.detect.current;

in
{
  # Export detection results (with overrides if provided)
  inherit (overriddenSystem) arch platform system isDarwin isLinux isX86_64 isAarch64;
  inherit (overriddenSystem) isValidPlatform isValidArch isValidSystem;

  # Original API compatibility
  currentArch = overriddenSystem.arch;
  currentPlatform = overriddenSystem.platform;
  currentSystem = overriddenSystem.system;

  # Supported configurations
  inherit (platformSystem.detect) supportedPlatforms supportedArchs supportedSystems;

  # Build optimizations from unified system
  buildOptimizations = platformSystem.utils.getOptimizedBuildConfig overriddenSystem.platform;

  # Debug information if requested
  debugInfo = if debugMode then {
    inherit (overriddenSystem) arch platform system;
    overrides = {
      platform = overridePlatform;
      arch = overrideArch;
    };
    config = platformSystem.currentConfig;
  } else {};

in
{
  # Export detection results (with overrides if provided)
  inherit (overriddenSystem) arch platform system isDarwin isLinux isX86_64 isAarch64;
  inherit (overriddenSystem) isValidPlatform isValidArch isValidSystem;

  # Original API compatibility
  currentArch = overriddenSystem.arch;
  currentPlatform = overriddenSystem.platform;
  currentSystem = overriddenSystem.system;

  # Supported configurations
  inherit (platformSystem.detect) supportedPlatforms supportedArchs supportedSystems;

  # Build optimizations from unified system
  getCurrentOptimizations = buildOptimizations;

  # Legacy API functions for backward compatibility
  getCurrentPlatform = overriddenSystem.platform;
  getCurrentArch = overriddenSystem.arch;
  getCurrentSystem = overriddenSystem.system;

  # Boolean checks
  isPlatform = platform: overriddenSystem.platform == platform;
  isArch = arch: overriddenSystem.arch == arch;

  # Validation functions
  validatePlatform = platformSystem.validate.platform;
  validateArch = platformSystem.validate.arch;
  validateSystem = platformSystem.validate.system;

  # Build optimization
  getOptimizations = buildOptimizations;

  # Supported values
  getSupportedPlatforms = platformSystem.detect.supportedPlatforms;
  getSupportedArchs = platformSystem.detect.supportedArchs;
  getSupportedSystems = platformSystem.detect.supportedSystems;

  # Debug information
  getDebugInfo = debugInfo;

  # Utility functions
  getOtherPlatforms = builtins.filter (p: p != overriddenSystem.platform) platformSystem.detect.supportedPlatforms;
  getOtherArchs = builtins.filter (a: a != overriddenSystem.arch) platformSystem.detect.supportedArchs;
  getOtherSystems = builtins.filter (s: s != overriddenSystem.system) platformSystem.detect.supportedSystems;

  # Build target helpers
  getCurrentTarget = overriddenSystem.system;
  getAllTargets = platformSystem.detect.supportedSystems;
  getCrossTargets = builtins.filter (s: s != overriddenSystem.system) platformSystem.detect.supportedSystems;
}
