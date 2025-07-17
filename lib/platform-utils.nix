# Platform-Specific Utilities Library - Legacy Compatibility Wrapper
# Redirects to unified platform-system.nix
# Helper functions for platform-specific operations and configurations

{ pkgs ? import <nixpkgs> {} }:

let
  # Import unified platform system
  platformSystem = import ./platform-system.nix { inherit pkgs; lib = pkgs.lib; };

in
{
  # Re-export platform system utilities with legacy API
  inherit (platformSystem.utils) pathUtils packageUtils systemInfo;
  inherit (platformSystem) arch platform system isDarwin isLinux isX86_64 isAarch64;
  inherit (platformSystem) platformConfigs currentConfig;

  # Legacy function names for backward compatibility
  getArchFromSystem = platformSystem.utils.getArchFromSystem;
  getPlatformFromSystem = platformSystem.utils.getPlatformFromSystem;
  getPlatformDefaults = platformSystem.utils.getPlatformDefaults;

  # Path utilities
  inherit (platformSystem.utils.pathUtils) joinPath normalizePath isAbsolute getUserHome getSystemPaths;

  # Package utilities
  inherit (platformSystem.utils.packageUtils) getPackageManager installPackage isPackageAvailable;

  # Platform feature support
  platformSupports = platformSystem.utils.platformSupports;

  # Build configuration
  getOptimizedBuildConfig = platformSystem.utils.getOptimizedBuildConfig;

  # Cross-platform utilities
  inherit (platformSystem.crossPlatform) forPlatforms platformSpecific whenPlatform whenArch;

  # System information
  getSystemInfo = platformSystem.utils.systemInfo.getSystemInfo;
  getBuildInfo = platformSystem.utils.systemInfo.getBuildInfo;

  # Legacy environment utilities
  getEnvPrefix = platform:
    if platform == "darwin" then "DARWIN_"
    else if platform == "linux" then "LINUX_"
    else "UNKNOWN_";

  getTempDir = platform:
    if platform == "darwin" then "/tmp"
    else if platform == "linux" then "/tmp"
    else "/tmp";

  # Cross-compilation support
  getCrossCompileTargets = platform:
    let
      allTargets = platformSystem.supportedSystems;
      currentTarget = "${platformSystem.arch}-${platform}";
    in
    builtins.filter (target: target != currentTarget) allTargets;

  supportsCrossCompilation = system:
    let platform = platformSystem.utils.getPlatformFromSystem system;
    in builtins.length (getCrossCompileTargets platform) > 0;

  # Version and metadata
  version = "2.0.0-unified";
  description = "Platform utilities with unified backend";
}
