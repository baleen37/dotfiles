# Platform-Specific Configurations
#
# Provides platform-specific settings and preferences for darwin and linux systems.
# Includes build optimizations, system paths, and preferred applications.
#
# Usage:
#   platformConfigs = import ./platform-configs.nix { system = "aarch64-darwin"; };
#   darwinConfig = platformConfigs.darwin;

{
  system ? "x86_64-linux",
  pkgs ? null,
  lib ? null,
}:

let
  # Determine lib with fallback
  actualLib =
    if lib != null then
      lib
    else if pkgs != null then
      pkgs.lib
    else
      null;

  # Import error system for error handling
  errorSystem =
    if pkgs != null then
      import ./error-system.nix { inherit pkgs lib; }
    else
      {
        throwConfigError = msg: builtins.throw "Config Error: ${msg}";
      };

  # Import platform detection for current system info
  platformDetection = import ./platform-detection.nix { inherit system pkgs lib; };

  # Current system information
  currentArch = platformDetection.arch;
  isAarch64 = currentArch == "aarch64";

  # Platform-specific configurations
  platformConfigs = {
    darwin = {
      hasHomebrew = true;
      packageManager = "brew";
      shellPath = "/bin/zsh";
      systemPaths = [
        "/usr/bin"
        "/usr/local/bin"
        "/opt/homebrew/bin"
      ];
      buildOptimizations = {
        parallelJobs = 8;
        useCache = true;
        extraFlags = [
          "--option"
          "system-features"
          "nixos-test"
        ];
        optimizationLevel = "-O2";
        targetFlags = if isAarch64 then [ "-mcpu=apple-m1" ] else [ "-march=native" ];
      };
      preferredApps = {
        terminal = "iterm2";
        browser = "safari";
        editor = "vim";
        fileManager = "finder";
      };
    };

    linux = {
      hasHomebrew = false;
      packageManager = "nix";
      shellPath = "/run/current-system/sw/bin/zsh";
      systemPaths = [
        "/run/current-system/sw/bin"
        "/usr/bin"
        "/bin"
      ];
      buildOptimizations = {
        parallelJobs = 8;
        useCache = true;
        extraFlags = [
          "--option"
          "system-features"
          "nixos-test"
        ];
        optimizationLevel = "-O2";
        targetFlags = if isAarch64 then [ "-mcpu=native" ] else [ "-march=native" ];
      };
      preferredApps = {
        terminal = "alacritty";
        browser = "firefox";
        editor = "vim";
        fileManager = "nautilus";
      };
    };
  };

  # Get configuration for current platform
  currentPlatform = platformDetection.platform;
  getCurrentConfig =
    if builtins.hasAttr currentPlatform platformConfigs then
      platformConfigs.${currentPlatform}
    else
      errorSystem.throwConfigError "No configuration for platform: ${currentPlatform}";

in
{
  # Export all platform configurations
  inherit platformConfigs;

  # Export current platform configuration
  current = getCurrentConfig;

  # Convenience accessors for current platform
  inherit (getCurrentConfig)
    hasHomebrew
    packageManager
    shellPath
    systemPaths
    buildOptimizations
    preferredApps
    ;

  # Platform-specific helpers
  getPlatformConfig =
    platform:
    if builtins.hasAttr platform platformConfigs then
      platformConfigs.${platform}
    else
      errorSystem.throwConfigError "No configuration for platform: ${platform}";

  # Feature support checks
  isFeatureSupported =
    feature: builtins.hasAttr feature getCurrentConfig && getCurrentConfig.${feature};

  # Version and metadata
  version = "1.0.0";
  description = "Platform-specific configurations for darwin and linux systems";
}
