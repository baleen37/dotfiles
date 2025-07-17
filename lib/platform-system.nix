# Unified Platform System
# Combines platform-detector.nix, platform-utils.nix, and platform-apps.nix
# Provides comprehensive platform detection, utilities, and app management

{ pkgs ? null, lib ? null, nixpkgs ? null, self ? null }:

let
  # Determine pkgs and lib
  actualPkgs = if pkgs != null then pkgs else (import <nixpkgs> {});
  actualLib = if lib != null then lib else actualPkgs.lib;

  # Import error system for error handling
  errorSystem = import ./error-system.nix { pkgs = actualPkgs; lib = actualLib; };

  # Platform detection core
  detection = {
    # Get current system from Nix
    nixSystem = builtins.currentSystem;

    # Extract platform and architecture from Nix system
    systemParts = actualLib.splitString "-" builtins.currentSystem;
    detectedArch = if builtins.length detection.systemParts >= 1 then builtins.head detection.systemParts else "unknown";
    detectedPlatform = if builtins.length detection.systemParts >= 2 then builtins.elemAt detection.systemParts 1 else "unknown";

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
      systemServices = [
        "launchd"
        "brew"
        "xcode-select"
      ];
    };

    linux = {
      hasHomebrew = false;
      packageManager = "nix";
      shellPath = "/bin/bash";
      systemPaths = [ "/usr/bin" "/usr/local/bin" "/nix/var/nix/profiles/default/bin" ];
      buildOptimizations = {
        parallelJobs = 4;
        useCache = true;
        extraFlags = [ "--option" "sandbox" "true" ];
        optimizationLevel = "-O2";
        targetFlags = if currentSystem.isAarch64 then [ "-mcpu=cortex-a72" ] else [ "-march=native" ];
      };
      preferredApps = {
        terminal = "gnome-terminal";
        browser = "firefox";
        editor = "vim";
        fileManager = "nautilus";
      };
      systemServices = [
        "systemd"
        "dbus"
        "NetworkManager"
      ];
    };
  };

  # Get current platform configuration
  getCurrentPlatformConfig =
    if builtins.hasAttr currentSystem.platform platformConfigs then
      platformConfigs.${currentSystem.platform}
    else
      errorSystem.throwConfigError "Unsupported platform: ${currentSystem.platform}";

  # Utility functions
  utils = {
    # Extract architecture from system string
    getArchFromSystem = system:
      let parts = actualLib.splitString "-" system;
      in if builtins.length parts >= 1 then builtins.head parts else "unknown";

    # Extract platform from system string
    getPlatformFromSystem = system:
      let parts = actualLib.splitString "-" system;
      in if builtins.length parts >= 2 then builtins.elemAt parts 1 else "unknown";

    # Get platform defaults
    getPlatformDefaults = platform:
      if builtins.hasAttr platform platformConfigs then
        platformConfigs.${platform}
      else
        errorSystem.throwConfigError "Unknown platform: ${platform}";

    # Check if platform supports feature
    platformSupports = platform: feature:
      let
        config = utils.getPlatformDefaults platform;
        featureMap = {
          homebrew = config.hasHomebrew or false;
          systemd = platform == "linux";
          launchd = platform == "darwin";
          containers = true; # Most platforms support containers
          virtualization = platform == "linux"; # Primarily Linux
        };
      in
      featureMap.${feature} or false;

    # Get optimized build configuration
    getOptimizedBuildConfig = platform:
      let
        config = utils.getPlatformDefaults platform;
        baseConfig = config.buildOptimizations;
      in
      baseConfig // {
        makeFlags = [
          "-j${toString baseConfig.parallelJobs}"
        ] ++ (if baseConfig.useCache then [ "--with-cache" ] else []);

        cFlags = [ baseConfig.optimizationLevel ] ++ baseConfig.targetFlags;
        cxxFlags = [ baseConfig.optimizationLevel ] ++ baseConfig.targetFlags;

        nixBuildOptions = [
          "--cores" (toString baseConfig.parallelJobs)
        ] ++ baseConfig.extraFlags;
      };

    # Cross-platform path utilities
    pathUtils = {
      # Join paths using platform-appropriate separator
      joinPath = parts: actualLib.concatStringsSep "/" (actualLib.filter (x: x != "" && x != null) parts);

      # Normalize path separators
      normalizePath = path: actualLib.replaceStrings ["\\"] ["/"] path;

      # Check if path is absolute
      isAbsolute = path: actualLib.hasPrefix "/" path || actualLib.hasPrefix "~" path;

      # Get user home directory
      getUserHome =
        let
          home = builtins.getEnv "HOME";
          user = let userEnv = builtins.getEnv "USER"; in if userEnv != "" then userEnv else "unknown";
        in if home != "" then home else (
          if currentSystem.isDarwin then "/Users/${user}"
          else "/home/${user}"
        );

      # Get system paths for current platform
      getSystemPaths = getCurrentPlatformConfig.systemPaths;
    };

    # Package management utilities
    packageUtils = {
      # Get package manager command for platform
      getPackageManager = platform:
        (utils.getPlatformDefaults platform).packageManager;

      # Install package using platform package manager
      installPackage = package: platform:
        let
          pm = utils.packageUtils.getPackageManager platform;
          commands = {
            brew = "brew install ${package}";
            nix = "nix-env -iA nixpkgs.${package}";
            apt = "sudo apt install ${package}";
            pacman = "sudo pacman -S ${package}";
          };
        in
        commands.${pm} or (errorSystem.throwConfigError "Unknown package manager: ${pm}");

      # Check if package is available
      isPackageAvailable = package:
        builtins.hasAttr package actualPkgs;
    };

    # System information gathering
    systemInfo = {
      # Get all system information
      getSystemInfo = {
        inherit (currentSystem) arch platform system isDarwin isLinux isX86_64 isAarch64;
        config = getCurrentPlatformConfig;
        paths = utils.pathUtils.getSystemPaths;
        home = utils.pathUtils.getUserHome;
        packageManager = utils.packageUtils.getPackageManager currentSystem.platform;
        supported = {
          inherit (currentSystem) isValidPlatform isValidArch isValidSystem;
        };
        capabilities = {
          homebrew = utils.platformSupports currentSystem.platform "homebrew";
          systemd = utils.platformSupports currentSystem.platform "systemd";
          launchd = utils.platformSupports currentSystem.platform "launchd";
          containers = utils.platformSupports currentSystem.platform "containers";
          virtualization = utils.platformSupports currentSystem.platform "virtualization";
        };
      };

      # Get build environment info
      getBuildInfo = {
        inherit (currentSystem) system;
        config = utils.getOptimizedBuildConfig currentSystem.platform;
        parallelJobs = getCurrentPlatformConfig.buildOptimizations.parallelJobs;
        useCache = getCurrentPlatformConfig.buildOptimizations.useCache;
      };
    };
  };

  # App management system
  apps = if nixpkgs != null && self != null then {
    # Generic app builder
    mkApp = scriptName: system: {
      type = "app";
      program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
        #!/usr/bin/env bash
        PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
        echo "Running ${scriptName} for ${system}"
        exec ${self}/apps/${system}/${scriptName} "$@"
      '')}/bin/${scriptName}";
    };

    # Setup-dev app builder with fallback
    mkSetupDevApp = system:
      if builtins.pathExists (self + "/scripts/setup-dev")
      then {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "setup-dev"
          (builtins.readFile (self + "/scripts/setup-dev"))
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
        "build" = apps.mkApp "build" currentSystem.system;
        "build-switch" = apps.mkApp "build-switch" currentSystem.system;
        "apply" = apps.mkApp "apply" currentSystem.system;
        "setup-dev" = apps.mkSetupDevApp currentSystem.system;

        # Auto-update commands
        "bl-auto-update-check" = apps.mkBlAutoUpdateApp {
          system = currentSystem.system;
          commandName = "check";
        };
        "bl-auto-update-apply" = apps.mkBlAutoUpdateApp {
          system = currentSystem.system;
          commandName = "apply";
        };
        "bl-auto-update-status" = apps.mkBlAutoUpdateApp {
          system = currentSystem.system;
          commandName = "status";
        };
      };

      linux = {
        # Standard Linux apps
        "build" = apps.mkApp "build" currentSystem.system;
        "build-switch" = apps.mkApp "build-switch" currentSystem.system;
        "apply" = apps.mkApp "apply" currentSystem.system;
        "setup-dev" = apps.mkSetupDevApp currentSystem.system;

        # Auto-update commands
        "bl-auto-update-check" = apps.mkBlAutoUpdateApp {
          system = currentSystem.system;
          commandName = "check";
        };
        "bl-auto-update-apply" = apps.mkBlAutoUpdateApp {
          system = currentSystem.system;
          commandName = "apply";
        };
        "bl-auto-update-status" = apps.mkBlAutoUpdateApp {
          system = currentSystem.system;
          commandName = "status";
        };
      };
    };

    # Get current platform apps
    getCurrentPlatformApps =
      if builtins.hasAttr currentSystem.platform apps.platformApps then
        apps.platformApps.${currentSystem.platform}
      else
        errorSystem.throwConfigError "No apps defined for platform: ${currentSystem.platform}";

  } else {
    # Minimal apps when nixpkgs/self not provided
    mkApp = scriptName: system:
      errorSystem.throwUserError "App building requires nixpkgs and self parameters";
    mkSetupDevApp = system:
      errorSystem.throwUserError "App building requires nixpkgs and self parameters";
    mkBlAutoUpdateApp = args:
      errorSystem.throwUserError "App building requires nixpkgs and self parameters";
    platformApps = {};
    getCurrentPlatformApps = {};
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
