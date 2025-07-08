# Platform-Specific Utilities Library
# Helper functions for platform-specific operations and configurations

{ pkgs ? import <nixpkgs> {} }:

let
  # Internal helper functions (defined in let block to avoid recursion issues)

  # Extract architecture from system string
  getArchFromSystem = system:
    let parts = pkgs.lib.splitString "-" system;
    in if builtins.length parts >= 1 then builtins.head parts else "unknown";

  # Extract platform from system string
  getPlatformFromSystem = system:
    let parts = pkgs.lib.splitString "-" system;
    in if builtins.length parts >= 2 then builtins.elemAt parts 1 else "unknown";

  # Platform defaults function
  getPlatformDefaults = platform:
    if platform == "darwin" then {
      hasHomebrew = true;
      packageManager = "brew";
      shellPath = "/bin/zsh";
      systemPaths = [ "/usr/bin" "/usr/local/bin" "/opt/homebrew/bin" ];
      buildOptimizations = {
        parallelJobs = 8;
        useCache = true;
        extraFlags = [ "--option" "system-features" "nixos-test" ];
      };
    }
    else if platform == "linux" then {
      hasHomebrew = false;
      packageManager = "nix";
      shellPath = "/bin/bash";
      systemPaths = [ "/usr/bin" "/usr/local/bin" "/nix/var/nix/profiles/default/bin" ];
      buildOptimizations = {
        parallelJobs = 4;
        useCache = true;
        extraFlags = [ "--option" "sandbox" "true" ];
      };
    }
    else {
      hasHomebrew = false;
      packageManager = "unknown";
      shellPath = "/bin/sh";
      systemPaths = [ "/usr/bin" ];
      buildOptimizations = {
        parallelJobs = 1;
        useCache = false;
        extraFlags = [ ];
      };
    };

  # Cross-compilation targets helper
  getCrossCompileTargets = fromPlatform:
    let
      supportedArchs = [ "x86_64" "aarch64" ];
      targets = map (arch: "${arch}-${fromPlatform}") supportedArchs;
      currentArch = builtins.head (builtins.split "-" pkgs.system);
    in builtins.filter (target: target != "${currentArch}-${fromPlatform}") targets;

in
{
  # Architecture extraction utilities (expose let-defined functions)
  getArchFromSystem = getArchFromSystem;
  getPlatformFromSystem = getPlatformFromSystem;

  # System compatibility utilities

  # Check if two systems are compatible (same system)
  isCompatibleSystem = system1: system2: system1 == system2;

  # Check if cross-compilation is possible (same platform, different arch)
  canCrossCompile = fromSystem: toSystem:
    let
      fromPlatform = builtins.elemAt (builtins.split "-" fromSystem) 2;
      toPlatform = builtins.elemAt (builtins.split "-" toSystem) 2;
    in fromPlatform == toPlatform;

  # Platform-specific configuration utilities

  # Get default configuration for platform (expose internal function)
  getPlatformDefaults = getPlatformDefaults;

  # Build optimization utilities

  # Get build flags for system
  getBuildFlags = system:
    let
      platform = builtins.elemAt (builtins.split "-" system) 2;
      defaults = getPlatformDefaults platform;
    in defaults.buildOptimizations.extraFlags;

  # Get maximum parallel jobs for system
  getMaxJobs = system:
    let
      platform = builtins.elemAt (builtins.split "-" system) 2;
      defaults = getPlatformDefaults platform;
    in defaults.buildOptimizations.parallelJobs;

  # System path utilities

  # Get system paths for platform
  getSystemPaths = platform:
    let defaults = getPlatformDefaults platform;
    in defaults.systemPaths;

  # Get package manager command for platform
  getPackageManagerCommand = platform:
    let defaults = getPlatformDefaults platform;
    in defaults.packageManager;

  # Shell utilities

  # Get default shell for platform
  getDefaultShell = platform:
    let defaults = getPlatformDefaults platform;
    in defaults.shellPath;

  # Platform feature detection

  # Check if current system is Darwin/macOS
  isDarwin =
    let currentPlatform = getPlatformFromSystem pkgs.system;
    in currentPlatform == "darwin";

  # Check if current system is Linux
  isLinux =
    let currentPlatform = getPlatformFromSystem pkgs.system;
    in currentPlatform == "linux";

  # Check if platform supports Homebrew
  supportsHomebrew = platform:
    let defaults = getPlatformDefaults platform;
    in defaults.hasHomebrew;

  # Check if platform supports systemd
  supportsSystemd = platform: platform == "linux";

  # Check if platform supports launchd
  supportsLaunchd = platform: platform == "darwin";

  # Cross-compilation utilities (expose let-defined functions)
  getCrossCompileTargets = getCrossCompileTargets;

  # Check if system supports cross-compilation
  supportsCrossCompilation = system:
    let platform = getPlatformFromSystem system;
    in builtins.length (getCrossCompileTargets platform) > 0;

  # Environment utilities

  # Get environment variable prefix for platform
  getEnvPrefix = platform:
    if platform == "darwin" then "DARWIN_"
    else if platform == "linux" then "LINUX_"
    else "UNKNOWN_";

  # Get temp directory for platform
  getTempDir = platform:
    if platform == "darwin" then "/tmp"
    else if platform == "linux" then "/tmp"
    else "/tmp";
}
