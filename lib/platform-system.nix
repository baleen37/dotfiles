# Unified Platform System
# Combines platform-detector.nix, platform-utils.nix, and platform-apps.nix
# Provides comprehensive platform detection, utilities, and app management

{ pkgs ? null, lib ? null, nixpkgs ? null, self ? null, system ? null }:

let
  # Determine pkgs and lib with fallbacks
  actualPkgs = if pkgs != null then pkgs else null;
  actualLib = if lib != null then lib else
  (if actualPkgs != null then actualPkgs.lib else
    # Basic lib functions fallback
  {
    splitString = sep: str:
      let parts = builtins.split sep str;
      in builtins.filter (x: builtins.isString x && x != "") parts;
    concatStringsSep = sep: list: builtins.concatStringsSep sep list;
    filter = f: list: builtins.filter f list;
    replaceStrings = from: to: str: builtins.replaceStrings from to str;
    hasPrefix = prefix: str: builtins.substring 0 (builtins.stringLength prefix) str == prefix;
    genAttrs = names: f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) names);
    elemAt = list: pos: builtins.elemAt list pos;
  });

  # Import error system for error handling (only if actualPkgs is available)
  errorSystem =
    if actualPkgs != null then
      import ./error-system.nix { pkgs = actualPkgs; lib = actualLib; }
    else {
      throwConfigError = msg: throw "Config Error: ${msg}";
      throwUserError = msg: throw "User Error: ${msg}";
    };

  # Platform detection core
  detection =
    let
      currentSystem = if system != null then system else "x86_64-linux";
    in
    {
      # Get current system from parameter (required in flake context)
      nixSystem = currentSystem;

      # Extract platform and architecture from Nix system using manual parsing
      detectedArch =
        if builtins.match "x86_64-.*" currentSystem != null then "x86_64"
        else if builtins.match "aarch64-.*" currentSystem != null then "aarch64"
        else "unknown";
      detectedPlatform =
        if builtins.match ".*-darwin" currentSystem != null then "darwin"
        else if builtins.match ".*-linux" currentSystem != null then "linux"
        else "unknown";

      # Supported configurations
      supportedPlatforms = [ "darwin" "linux" ];
      supportedArchs = [ "x86_64" "aarch64" ];
      supportedSystems = [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
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
    isValidArch = builtins.elem detection.detectedArch detection.supportedArchs;
    isValidSystem = builtins.elem detection.nixSystem detection.supportedSystems;
  };

  # Platform-specific configurations
  platformConfigs = {
    darwin = {
      hasHomebrew = true;
      packageManager = "brew";
      shellPath = "/bin/zsh";
      systemPaths = [ "/usr/bin" "/usr/local/bin" "/opt/homebrew/bin" ];
      buildOptimizations = {
        parallelJobs = 8;
        useCache = true;
        extraFlags = [ "--option" "system-features" "nixos-test" ];
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
      systemPaths = [ "/run/current-system/sw/bin" "/usr/bin" "/bin" ];
      buildOptimizations = {
        parallelJobs = 8;
        useCache = true;
        extraFlags = [ "--option" "system-features" "nixos-test" ];
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
      hasHomebrew = getCurrentPlatformConfig.hasHomebrew;

      # Platform-specific package installation
      installPackage = packageName:
        if currentSystem.isDarwin && getCurrentPlatformConfig.hasHomebrew then
          "brew install ${packageName}"
        else
          "nix-env -iA nixpkgs.${packageName}";
    };

    # System information utilities
    systemInfo = {
      # Get current architecture
      arch = currentSystem.arch;

      # Get current platform
      platform = currentSystem.platform;

      # Get full system string
      systemString = currentSystem.system;

      # Platform checks
      isDarwin = currentSystem.isDarwin;
      isLinux = currentSystem.isLinux;
      isX86_64 = currentSystem.isX86_64;
      isAarch64 = currentSystem.isAarch64;

      # Build optimizations
      buildOptimizations = getCurrentPlatformConfig.buildOptimizations;

      # Get preferred applications
      preferredApps = getCurrentPlatformConfig.preferredApps;
    };

    # Configuration utilities
    configUtils = {
      # Get platform-specific config value
      getPlatformConfig = key: default:
        if builtins.hasAttr key getCurrentPlatformConfig then
          getCurrentPlatformConfig.${key}
        else
          default;

      # Check if feature is supported
      isFeatureSupported = feature:
        builtins.hasAttr feature getCurrentPlatformConfig &&
        getCurrentPlatformConfig.${feature} == true;
    };
  };

  # App management functions (only when nixpkgs and self are available)
  apps =
    if nixpkgs != null && self != null then
      let
        # Simplified path resolution without flake source dependencies
        pathResolutionWithFallback = target_command:
          let
            # Get PWD or fall back to a reasonable default
            basePath =
              if (builtins.getEnv "PWD") != ""
              then builtins.getEnv "PWD"
              else "/Users/baleen/dev/dotfiles";
            appPath = "${basePath}/apps/${currentSystem.system}/${target_command}";
          in
          builtins.toString appPath;

        # Standard app builder using writeScript to avoid source dependencies
        mkApp = scriptName: system: {
          type = "app";
          program =
            let
              pkg = nixpkgs.legacyPackages.${system};
              scriptContent =
                if scriptName == "build-switch" then ''
                  #!/bin/bash -e

                  # Check for help flag
                  if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
                      echo "build-switch - Build and switch Darwin system configuration"
                      echo ""
                      echo "Usage: nix run .#build-switch [OPTIONS]"
                      echo ""
                      echo "Options:"
                      echo "  --help, -h    Show this help message"
                      echo "  --verbose     Enable verbose logging"
                      echo ""
                      echo "Description:"
                      echo "  Builds and applies user-level configuration using Home Manager."
                      echo "  No root privileges required - safe for Claude Code execution."
                      echo ""
                      echo "Examples:"
                      echo "  nix run .#build-switch"
                      echo "  nix run .#build-switch -- --verbose"
                      echo ""
                      exit 0
                  fi

                  # Environment setup - minimize export usage
                  USER=''${USER:-$(whoami)}

                  # Simple logging
                  log_info() {
                      echo "ℹ️  $1"
                  }

                  # TDD: Minimal implementation for Green phase
                  log_info "Running user-level configuration (no root privileges required)"
                  log_info "Using Home Manager for all configurations"
                  log_info "Running: nix run github:nix-community/home-manager/release-24.05 -- switch --flake .#''${USER} --impure"

                  # 기존 방식으로 복귀 - make 명령어 사용 권장
                  echo "❌ nix run .#build-switch는 사용자명 하드코딩 이슈로 현재 제한됨"
                  echo "✅ 대신 다음 명령어 사용을 권장:"
                  echo "   • ./apps/aarch64-darwin/build-switch"
                  echo "   • make switch"
                  echo ""
                  exit 1
                '' else ''
                  #!/bin/bash
                  echo "Script ${scriptName} not implemented in flake apps"
                  exit 1
                '';
            in
            "${pkg.writeScriptBin scriptName scriptContent}/bin/${scriptName}";
        };

        # Setup dev app builder
        mkSetupDevApp = system:
          let
            setupDevPath = self + "/scripts/setup-dev";
          in
          if builtins.pathExists setupDevPath
          then {
            type = "app";
            program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "setup-dev"
          (builtins.readFile setupDevPath)
        )}/bin/setup-dev";
          }
          else {
            type = "app";
            program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "setup-dev" ''
          #!/usr/bin/env bash
          echo "setup-dev script not found. Please run: ./scripts/install-setup-dev"
          exit 1
        '')}/bin/setup-dev";
          };

        # Auto-update app builders
        mkBlAutoUpdateApp = { system, commandName }:
          let
            scriptPath = self + "/scripts/bl-auto-update-${commandName}";
          in
          if builtins.pathExists scriptPath
          then {
            type = "app";
            program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "bl-auto-update-${commandName}"
          (builtins.readFile scriptPath)
        )}/bin/bl-auto-update-${commandName}";
          }
          else {
            type = "app";
            program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "bl-auto-update-${commandName}" ''
          #!/usr/bin/env bash
          echo "bl-auto-update-${commandName} script not found"
          exit 1
        '')}/bin/bl-auto-update-${commandName}";
          };

        # Platform-specific app definitions
        platformApps = {
          darwin = {
            # Standard Darwin apps
            "build" = mkApp "build" currentSystem.system;
            "build-switch" = mkApp "build-switch" currentSystem.system;
            "apply" = mkApp "apply" currentSystem.system;
            "setup-dev" = mkSetupDevApp currentSystem.system;

            # Auto-update commands
            "bl-auto-update-check" = mkBlAutoUpdateApp {
              system = currentSystem.system;
              commandName = "check";
            };
            "bl-auto-update-apply" = mkBlAutoUpdateApp {
              system = currentSystem.system;
              commandName = "apply";
            };
            "bl-auto-update-status" = mkBlAutoUpdateApp {
              system = currentSystem.system;
              commandName = "status";
            };
          };

          linux = {
            # Standard Linux apps
            "build" = mkApp "build" currentSystem.system;
            "build-switch" = mkApp "build-switch" currentSystem.system;
            "apply" = mkApp "apply" currentSystem.system;
            "setup-dev" = mkSetupDevApp currentSystem.system;

            # Auto-update commands
            "bl-auto-update-check" = mkBlAutoUpdateApp {
              system = currentSystem.system;
              commandName = "check";
            };
            "bl-auto-update-apply" = mkBlAutoUpdateApp {
              system = currentSystem.system;
              commandName = "apply";
            };
            "bl-auto-update-status" = mkBlAutoUpdateApp {
              system = currentSystem.system;
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
        inherit mkApp mkSetupDevApp mkBlAutoUpdateApp platformApps getCurrentPlatformApps;
      }
    else {
      # Minimal apps when nixpkgs/self not provided
      mkApp = scriptName: system:
        errorSystem.throwUserError "App building requires nixpkgs and self parameters";
      mkSetupDevApp = system:
        errorSystem.throwUserError "App building requires nixpkgs and self parameters";
      mkBlAutoUpdateApp = args:
        errorSystem.throwUserError "App building requires nixpkgs and self parameters";
      platformApps = { };
      getCurrentPlatformApps = { };
    };

in
{
  # Export core detection information
  inherit (currentSystem) arch platform system isDarwin isLinux isX86_64 isAarch64;
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
    inherit (detection) nixSystem supportedPlatforms supportedArchs supportedSystems;
    current = currentSystem;
  };

  # Cross-platform utilities
  crossPlatform = {
    # Build for multiple platforms
    forPlatforms = platforms: f: actualLib.genAttrs platforms f;

    # Platform-specific values
    platformSpecific = values:
      if builtins.hasAttr currentSystem.platform values then
        values.${currentSystem.platform}
      else if builtins.hasAttr "default" values then
        values.default
      else
        errorSystem.throwConfigError "No value for platform ${currentSystem.platform} and no default provided";

    # Conditional based on platform
    whenPlatform = platform: value:
      if currentSystem.platform == platform then value else null;

    # Conditional based on architecture
    whenArch = arch: value:
      if currentSystem.arch == arch then value else null;
  };

  # Validation functions
  validate = {
    platform = platform: builtins.elem platform detection.supportedPlatforms;
    arch = arch: builtins.elem arch detection.supportedArchs;
    system = system: builtins.elem system detection.supportedSystems;
  };

  # Version and metadata
  version = "2.0.0-unified";
  description = "Unified platform detection, utilities, and app management system";
  supportedPlatforms = detection.supportedPlatforms;
  supportedArchitectures = detection.supportedArchs;
  supportedSystems = detection.supportedSystems;
}
