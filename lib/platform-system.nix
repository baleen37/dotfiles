# Unified Platform System
#
# This module provides comprehensive platform detection, utilities, and application
# management for cross-platform Nix configurations. It combines platform detection,
# architecture utilities, and app builders into a unified interface.
#
# Key Components:
# - Platform Detection: OS and architecture detection with caching for performance
# - App Management: Platform-specific app builders (Linux, Darwin, universal)
# - Architecture Support: Multi-architecture builds with optimized detection
# - Utilities: Cross-platform helper functions and compatibility layers
#
# Functions:
# - platformDetection: Cached platform and architecture detection functions
# - apps.platformApps: Platform-specific app configurations (linux/darwin/universal)
# - apps.coreApps: Cross-platform core application definitions
# - utils: Platform utilities for conditional logic and architecture handling

{
  pkgs ? null,
  lib ? null,
  nixpkgs ? null,
  self ? null,
  system ? null,
}:

let
  # Determine pkgs and lib with fallbacks
  actualPkgs = if pkgs != null then pkgs else null;
  actualLib =
    if lib != null then
      lib
    else
      (
        if actualPkgs != null then
          actualPkgs.lib
        else
          # Basic lib functions fallback
          {
            splitString =
              sep: str:
              let
                parts = builtins.split sep str;
              in
              builtins.filter (x: builtins.isString x && x != "") parts;
            concatStringsSep = sep: list: builtins.concatStringsSep sep list;
            filter = f: list: builtins.filter f list;
            replaceStrings =
              from: to: str:
              builtins.replaceStrings from to str;
            hasPrefix = prefix: str: builtins.substring 0 (builtins.stringLength prefix) str == prefix;
            genAttrs =
              names: f:
              builtins.listToAttrs (
                map (name: {
                  inherit name;
                  value = f name;
                }) names
              );
            elemAt = list: pos: builtins.elemAt list pos;
          }
      );

  # Import error system for error handling (only if actualPkgs is available)
  errorSystem =
    if actualPkgs != null then
      import ./error-system.nix {
        pkgs = actualPkgs;
        lib = actualLib;
      }
    else
      {
        throwConfigError = msg: throw "Config Error: ${msg}";
        throwUserError = msg: throw "User Error: ${msg}";
      };

  # Import optimized platform detection utilities
  platformDetection = import ./platform-detection.nix {
    system = if system != null then system else "x86_64-linux";
    inherit pkgs lib;
  };

  # Platform detection core (now using optimized detection)
  detection = {
    # Get current system from parameter (required in flake context)
    nixSystem = platformDetection.system;

    # Use optimized platform and architecture detection (cached results)
    detectedArch = platformDetection.arch;
    detectedPlatform = platformDetection.platform;

    # Supported configurations
    inherit (platformDetection) supportedPlatforms supportedArchitectures supportedSystems;
  };

  # Current system information
  currentSystem = {
    arch = detection.detectedArch;
    platform = detection.detectedPlatform;
    system = detection.nixSystem;

    # Platform checks
    isDarwin = detection.detectedPlatform == "darwin";
    isLinux = detection.detectedPlatform == "linux";
    isX86_64 = detection.detectedArch == "x86_64";
    isAarch64 = detection.detectedArch == "aarch64";

    # Validation
    isValidPlatform = builtins.elem detection.detectedPlatform detection.supportedPlatforms;
    isValidArch = builtins.elem detection.detectedArch detection.supportedArchitectures;
    isValidSystem = builtins.elem detection.nixSystem detection.supportedSystems;
  };

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
        targetFlags = if currentSystem.isAarch64 then [ "-mcpu=apple-m1" ] else [ "-march=native" ];
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
        targetFlags = if currentSystem.isAarch64 then [ "-mcpu=native" ] else [ "-march=native" ];
      };
      preferredApps = {
        terminal = "alacritty";
        browser = "firefox";
        editor = "vim";
        fileManager = "nautilus";
      };
    };
  };

  # Get current platform configuration
  getCurrentPlatformConfig =
    if builtins.hasAttr currentSystem.platform platformConfigs then
      platformConfigs.${currentSystem.platform}
    else
      errorSystem.throwConfigError "No configuration for platform: ${currentSystem.platform}";

  # Platform utilities
  utils = {
    # Path utilities
    pathUtils = {
      # Get shell path for platform
      getShellPath = getCurrentPlatformConfig.shellPath;

      # Get system paths
      getSystemPaths = getCurrentPlatformConfig.systemPaths;

      # Join paths
      joinPath = segments: actualLib.concatStringsSep "/" (actualLib.filter (x: x != "") segments);

      # Normalize path
      normalizePath = path: actualLib.replaceStrings [ "//" ] [ "/" ] path;

      # Check if path exists
      pathExists = path: builtins.pathExists path;
    };

    # Package utilities
    packageUtils = {
      # Check if package manager is available
      hasPackageManager = getCurrentPlatformConfig.packageManager != null;

      # Get package manager name
      getPackageManager = getCurrentPlatformConfig.packageManager;

      # Check if homebrew is supported
      inherit (getCurrentPlatformConfig) hasHomebrew;

      # Platform-specific package installation
      installPackage =
        packageName:
        if currentSystem.isDarwin && getCurrentPlatformConfig.hasHomebrew then
          "brew install ${packageName}"
        else
          "nix-env -iA nixpkgs.${packageName}";
    };

    # System information utilities
    systemInfo = {
      # Get current architecture
      inherit (currentSystem) arch;

      # Get current platform
      inherit (currentSystem) platform;

      # Get full system string
      systemString = currentSystem.system;

      # Platform checks
      inherit (currentSystem) isDarwin;
      inherit (currentSystem) isLinux;
      inherit (currentSystem) isX86_64;
      inherit (currentSystem) isAarch64;

      # Build optimizations
      inherit (getCurrentPlatformConfig) buildOptimizations;

      # Get preferred applications
      inherit (getCurrentPlatformConfig) preferredApps;
    };

    # Configuration utilities
    configUtils = {
      # Get platform-specific config value
      getPlatformConfig =
        key: default:
        if builtins.hasAttr key getCurrentPlatformConfig then getCurrentPlatformConfig.${key} else default;

      # Check if feature is supported
      isFeatureSupported =
        feature: builtins.hasAttr feature getCurrentPlatformConfig && getCurrentPlatformConfig.${feature};
    };
  };

  # App management functions (only when nixpkgs and self are available)
  apps =
    if nixpkgs != null && self != null then
      let
        # Simplified path resolution without flake source dependencies

        # Standard app builder using external script files
        mkApp =
          scriptName: system:
          let
            pkg = nixpkgs.legacyPackages.${system};
            # Determine script file based on platform and script name
            scriptFile =
              if scriptName == "build-switch" then
                if currentSystem.platform == "darwin" then
                  self + "/scripts/build-switch-darwin.sh"
                else
                  self + "/scripts/build-switch-linux.sh"
              else
                null;

            # Load script content from file or provide fallback
            scriptContent =
              if scriptFile != null && builtins.pathExists scriptFile then
                builtins.readFile scriptFile
              else
                ''
                  #!/bin/bash
                  echo "Script ${scriptName} not implemented"
                  exit 1
                '';

            # Replace @SYSTEM@ placeholder with actual system
            processedContent = builtins.replaceStrings [ "@SYSTEM@" ] [ currentSystem.system ] scriptContent;
          in
          {
            type = "app";
            program = "${pkg.writeScriptBin scriptName processedContent}/bin/${scriptName}";
          };

        # Setup dev app builder
        mkSetupDevApp =
          system:
          let
            setupDevPath = self + "/scripts/setup-dev";
          in
          if builtins.pathExists setupDevPath then
            {
              type = "app";
              program = "${
                (nixpkgs.legacyPackages.${system}.writeScriptBin "setup-dev" (builtins.readFile setupDevPath))
              }/bin/setup-dev";
            }
          else
            {
              type = "app";
              program = "${
                (nixpkgs.legacyPackages.${system}.writeScriptBin "setup-dev" ''
                  #!/usr/bin/env bash
                  echo "setup-dev script not found. Please run: ./scripts/install-setup-dev"
                  exit 1
                '')
              }/bin/setup-dev";
            };

        # Auto-update app builders
        mkBlAutoUpdateApp =
          { system, commandName }:
          let
            scriptPath = self + "/scripts/bl-auto-update-${commandName}";
          in
          if builtins.pathExists scriptPath then
            {
              type = "app";
              program = "${
                (nixpkgs.legacyPackages.${system}.writeScriptBin "bl-auto-update-${commandName}" (
                  builtins.readFile scriptPath
                ))
              }/bin/bl-auto-update-${commandName}";
            }
          else
            {
              type = "app";
              program = "${
                (nixpkgs.legacyPackages.${system}.writeScriptBin "bl-auto-update-${commandName}" ''
                  #!/usr/bin/env bash
                  echo "bl-auto-update-${commandName} script not found"
                  exit 1
                '')
              }/bin/bl-auto-update-${commandName}";
            };

        # Validation app builder
        mkValidateApp = system: {
          type = "app";
          program = "${
            (nixpkgs.legacyPackages.${system}.writeScriptBin "validate-build-switch" ''
              #!/usr/bin/env bash
              set -euo pipefail

              # Run the Nix validation module
              nix-instantiate --eval --expr "
                let validate = import ./lib/validate-build-switch.nix {};
                in validate.runValidation
              "
            '')
          }/bin/validate-build-switch";
        };

        # Platform-specific app definitions
        platformApps = {
          darwin = {
            # Standard Darwin apps
            "build" = mkApp "build" currentSystem.system;
            "build-switch" = mkApp "build-switch" currentSystem.system;
            "apply" = mkApp "apply" currentSystem.system;
            "setup-dev" = mkSetupDevApp currentSystem.system;

            # Validation commands
            "validate-build-switch" = mkValidateApp currentSystem.system;

            # Auto-update commands
            "bl-auto-update-check" = mkBlAutoUpdateApp {
              inherit (currentSystem) system;
              commandName = "check";
            };
            "bl-auto-update-apply" = mkBlAutoUpdateApp {
              inherit (currentSystem) system;
              commandName = "apply";
            };
            "bl-auto-update-status" = mkBlAutoUpdateApp {
              inherit (currentSystem) system;
              commandName = "status";
            };
          };

          linux = {
            # Standard Linux apps
            "build" = mkApp "build" currentSystem.system;
            "build-switch" = mkApp "build-switch" currentSystem.system;
            "apply" = mkApp "apply" currentSystem.system;
            "setup-dev" = mkSetupDevApp currentSystem.system;

            # Validation commands
            "validate-build-switch" = mkValidateApp currentSystem.system;

            # Auto-update commands
            "bl-auto-update-check" = mkBlAutoUpdateApp {
              inherit (currentSystem) system;
              commandName = "check";
            };
            "bl-auto-update-apply" = mkBlAutoUpdateApp {
              inherit (currentSystem) system;
              commandName = "apply";
            };
            "bl-auto-update-status" = mkBlAutoUpdateApp {
              inherit (currentSystem) system;
              commandName = "status";
            };
          };
        };

        # Get current platform apps
        getCurrentPlatformApps =
          if builtins.hasAttr currentSystem.platform platformApps then
            platformApps.${currentSystem.platform}
          else
            errorSystem.throwConfigError "No apps defined for platform: ${currentSystem.platform}";

      in
      {
        inherit
          mkApp
          mkSetupDevApp
          mkBlAutoUpdateApp
          mkValidateApp
          platformApps
          getCurrentPlatformApps
          ;
      }
    else
      {
        # Minimal apps when nixpkgs/self not provided
        mkApp =
          _scriptName: _system:
          errorSystem.throwUserError "App building requires nixpkgs and self parameters";
        mkSetupDevApp =
          _system: errorSystem.throwUserError "App building requires nixpkgs and self parameters";
        mkBlAutoUpdateApp =
          _args: errorSystem.throwUserError "App building requires nixpkgs and self parameters";
        platformApps = { };
        getCurrentPlatformApps = { };
      };

in
{
  # Export core detection information
  inherit (currentSystem)
    arch
    platform
    system
    isDarwin
    isLinux
    isX86_64
    isAarch64
    ;
  inherit (currentSystem) isValidPlatform isValidArch isValidSystem;

  # Export platform configurations
  inherit platformConfigs;
  currentConfig = getCurrentPlatformConfig;

  # Export utility functions
  inherit utils;
  inherit (utils) pathUtils packageUtils systemInfo;

  # Export app management (if available)
  inherit apps;

  # Convenience functions
  detect = {
    inherit (detection)
      nixSystem
      supportedPlatforms
      supportedArchitectures
      supportedSystems
      ;
    current = currentSystem;
  };

  # Cross-platform utilities
  crossPlatform = {
    # Build for multiple platforms
    forPlatforms = platforms: f: actualLib.genAttrs platforms f;

    # Platform-specific values
    platformSpecific =
      values:
      if builtins.hasAttr currentSystem.platform values then
        values.${currentSystem.platform}
      else if builtins.hasAttr "default" values then
        values.default
      else
        errorSystem.throwConfigError "No value for platform ${currentSystem.platform} and no default provided";

    # Conditional based on platform
    whenPlatform = platform: value: if currentSystem.platform == platform then value else null;

    # Conditional based on architecture
    whenArch = arch: value: if currentSystem.arch == arch then value else null;
  };

  # Validation functions
  validate = {
    platform = platform: builtins.elem platform detection.supportedPlatforms;
    arch = arch: builtins.elem arch detection.supportedArchitectures;
    system = system: builtins.elem system detection.supportedSystems;
  };

  # Version and metadata
  version = "2.0.0-unified";
  description = "Unified platform detection, utilities, and app management system";
  inherit (detection) supportedPlatforms;
  inherit (detection) supportedArchitectures;
  inherit (detection) supportedSystems;
}
