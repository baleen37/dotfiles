# Config Loader System
# Provides YAML config loading with environment variable overrides and validation
{
  lib,
}:

let
  inherit (lib)
    getAttr
    mapAttrs
    ;
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.strings) hasPrefix removePrefix;

  # Import the validator
  validator = import ./config-validator-simple.nix { inherit lib; };

  # Environment variable override patterns
  envPrefixes = {
    platforms = "DOTFILES_PLATFORM_";
    cache = "DOTFILES_CACHE_";
    network = "DOTFILES_NETWORK_";
    performance = "DOTFILES_PERFORMANCE_";
    security = "DOTFILES_SECURITY_";
  };

  # Convert environment variable names to config paths
  envVarToPath =
    prefix: envVar:
    if hasPrefix prefix envVar then
      let
        suffix = removePrefix prefix envVar;
        # Convert UPPER_SNAKE_CASE to nested path
        # E.g., "BUILD_MAX_JOBS" -> ["build", "max_jobs"]
        parts = lib.splitString "_" (lib.toLower suffix);
      in
      parts
    else
      null;

  # Apply environment variable overrides (simplified for now)
  applyEnvOverrides =
    _configType: config:
    # For now, just return the config as-is
    # Environment variable override functionality can be added later
    config;

  # Known environment variables for each config type
  knownEnvVars =
    configType:
    if configType == "platforms" then
      [
        "DOTFILES_PLATFORM_SYSTEM_DETECTION_AUTO_DETECT"
        "DOTFILES_PLATFORM_SYSTEM_DETECTION_FALLBACK_ARCHITECTURE"
        "DOTFILES_PLATFORM_SYSTEM_DETECTION_FALLBACK_PLATFORM"
      ]
    else if configType == "cache" then
      [
        "DOTFILES_CACHE_LOCAL_MAX_SIZE_GB"
        "DOTFILES_CACHE_LOCAL_CLEANUP_DAYS"
        "DOTFILES_CACHE_LOCAL_STAT_FILE"
        "DOTFILES_CACHE_LOCAL_CACHE_DIR"
        "DOTFILES_CACHE_OPTIMIZATION_AUTO_OPTIMIZE"
        "DOTFILES_CACHE_OPTIMIZATION_COMPRESS_LOGS"
        "DOTFILES_CACHE_OPTIMIZATION_PARALLEL_DOWNLOADS"
      ]
    else if configType == "network" then
      [
        "DOTFILES_NETWORK_HTTP_CONNECTIONS"
        "DOTFILES_NETWORK_HTTP_CONNECT_TIMEOUT"
        "DOTFILES_NETWORK_HTTP_DOWNLOAD_ATTEMPTS"
        "DOTFILES_NETWORK_TIMEOUTS_BUILD"
        "DOTFILES_NETWORK_TIMEOUTS_DOWNLOAD"
        "DOTFILES_NETWORK_TIMEOUTS_CONNECTION"
      ]
    else if configType == "performance" then
      [
        "DOTFILES_PERFORMANCE_BUILD_MAX_JOBS"
        "DOTFILES_PERFORMANCE_BUILD_CORES"
        "DOTFILES_PERFORMANCE_BUILD_PARALLEL_BUILDS"
        "DOTFILES_PERFORMANCE_MEMORY_MIN_FREE"
        "DOTFILES_PERFORMANCE_MEMORY_MAX_FREE"
        "DOTFILES_PERFORMANCE_NIX_SANDBOX"
        "DOTFILES_PERFORMANCE_NIX_AUTO_OPTIMISE_STORE"
        "DOTFILES_PERFORMANCE_NIX_MAX_SUBSTITUTION_JOBS"
      ]
    else if configType == "security" then
      [
        "DOTFILES_SECURITY_SSH_KEY_TYPE"
        "DOTFILES_SECURITY_SSH_KEY_SIZE"
        "DOTFILES_SECURITY_SSH_DEFAULT_DIR"
        "DOTFILES_SECURITY_SUDO_REFRESH_INTERVAL"
        "DOTFILES_SECURITY_SUDO_SESSION_TIMEOUT"
        "DOTFILES_SECURITY_SUDO_REQUIRE_TTY"
        "DOTFILES_SECURITY_POLICIES_ALLOW_UNFREE"
        "DOTFILES_SECURITY_POLICIES_ALLOW_BROKEN"
        "DOTFILES_SECURITY_BUILD_REQUIRE_SIGS"
      ]
    else
      [ ];

  # Default configurations for each type
  defaults = {
    platforms = {
      platforms = {
        supported_systems = [
          "x86_64-darwin"
          "aarch64-darwin"
          "x86_64-linux"
          "aarch64-linux"
        ];
        platform_configs = {
          darwin = {
            type = "darwin";
            rebuild_command = "darwin-rebuild";
            rebuild_command_path = "./result/sw/bin/darwin-rebuild";
            flake_prefix = "darwinConfigurations";
            platform_name = "Nix Darwin";
            allow_unfree = true;
            impure_mode = true;
            system_suffix = ".system";
          };
          linux = {
            type = "linux";
            rebuild_command = "nixos-rebuild";
            rebuild_command_path = "nixos-rebuild";
            flake_prefix = "nixosConfigurations";
            platform_name = "NixOS";
            allow_unfree = false;
            impure_mode = false;
            system_suffix = ".config.system.build.toplevel";
          };
        };
        architectures = {
          aarch64 = {
            name = "ARM64";
            description = "ARM 64-bit architecture";
            aliases = [ "arm64" ];
          };
          x86_64 = {
            name = "Intel/AMD 64-bit";
            description = "x86_64 architecture";
            aliases = [ "x64" ];
          };
        };
      };
      system_detection = {
        auto_detect = true;
        fallback_architecture = "x86_64";
        fallback_platform = "darwin";
      };
      flake_patterns = {
        darwin = "darwinConfigurations.{architecture}-darwin.system";
        linux = "nixosConfigurations.{architecture}-linux.config.system.build.toplevel";
      };
    };

    cache = {
      cache = {
        local = {
          max_size_gb = 5;
          cleanup_days = 7;
          stat_file = "$HOME/.cache/nix-build-stats";
          cache_dir = "$HOME/.cache/nix";
        };
        binary_caches = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
        behavior = {
          max_cache_size = "50G";
          min_free_space = "1G";
          max_free_space = "10G";
        };
        optimization = {
          auto_optimize = true;
          compress_logs = true;
          parallel_downloads = 10;
        };
      };
    };

    network = {
      network = {
        http = {
          connections = 50;
          connect_timeout = 5;
          download_attempts = 3;
        };
        repositories = {
          nixpkgs = "github:nixos/nixpkgs/nixos-unstable";
          home_manager = "github:nix-community/home-manager";
          nix_darwin = "github:LnL7/nix-darwin/master";
        };
        substituters = [
          {
            url = "https://cache.nixos.org";
            public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
          }
          {
            url = "https://nix-community.cachix.org";
            public_key = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
          }
        ];
        timeouts = {
          build = 3600;
          download = 300;
          connection = 30;
        };
      };
    };

    performance = {
      performance = {
        build = {
          max_jobs = "auto";
          cores = 0;
          parallel_builds = true;
        };
        memory = {
          min_free = 1073741824;
          max_free = 10737418240;
        };
        system = {
          file_descriptors = 4096;
          max_user_processes = 2048;
        };
        nix = {
          sandbox = true;
          build_users_group = "nixbld";
          auto_optimise_store = true;
          max_substitution_jobs = 16;
        };
        cache = {
          narinfo_cache_positive_ttl = 3600;
          narinfo_cache_negative_ttl = 60;
        };
      };
    };

    security = {
      security = {
        ssh = {
          key_type = "ed25519";
          key_size = 256;
          default_dir = "$HOME/.ssh";
        };
        users = {
          allowed_users = [
            "@wheel"
            "@admin"
          ];
          trusted_users = [
            "root"
            "@wheel"
            "@admin"
          ];
        };
        sudo = {
          refresh_interval = 240;
          session_timeout = 900;
          require_tty = false;
        };
        permissions = {
          config_files = "644";
          script_files = "755";
          ssh_keys = "600";
          ssh_dir = "700";
        };
        policies = {
          allow_unfree = true;
          allow_broken = false;
          allow_unsupported = false;
        };
        build = {
          require_sigs = true;
          trusted_substituters_only = false;
        };
      };
    };
  };

  # Load config file with error handling
  # For now, we'll focus on the structure and validation
  # YAML parsing can be added later when the feature is needed
  loadConfigFile =
    _configPath:
    # Return null for now - will use defaults
    # This allows the rest of the system to work with validation and structure
    null;

in
{
  # Load a single config file with validation and overrides
  loadConfig =
    configType: configPath:
    let
      # Load config file
      configFile = loadConfigFile configPath;

      # Use defaults if file loading failed
      baseConfig = if configFile != null then configFile else getAttr configType defaults;

      # Apply environment variable overrides
      configWithOverrides = applyEnvOverrides configType baseConfig;

      # Validate the final configuration
      validation = validator.validateConfig configType configWithOverrides;
    in
    {
      config = configWithOverrides;
      inherit validation;
      source = if configFile != null then "file" else "defaults";
      overrides_applied = configWithOverrides != baseConfig;
    };

  # Load all config files from a directory
  loadAllConfigs =
    configDir:
    let
      configFiles = {
        platforms = "${configDir}/platforms.yaml";
        cache = "${configDir}/cache.yaml";
        network = "${configDir}/network.yaml";
        performance = "${configDir}/performance.yaml";
        security = "${configDir}/security.yaml";
      };

      # Use our own loadConfig function
      loadConfigLocal =
        configType: configPath:
        let
          # Load config file
          configFile = loadConfigFile configPath;

          # Use defaults if file loading failed
          baseConfig = if configFile != null then configFile else getAttr configType defaults;

          # Apply environment variable overrides
          configWithOverrides = applyEnvOverrides configType baseConfig;

          # Validate the final configuration
          validation = validator.validateConfig configType configWithOverrides;
        in
        {
          config = configWithOverrides;
          inherit validation;
          source = if configFile != null then "file" else "defaults";
          overrides_applied = configWithOverrides != baseConfig;
        };

      loadedConfigs = mapAttrs loadConfigLocal configFiles;

      # Extract just the config values
      configs = mapAttrs (_: result: result.config) loadedConfigs;

      # Combine all validation results
      allValidations = mapAttrs (_: result: result.validation) loadedConfigs;
      overallValidation = validator.validateAllConfigs configs;
    in
    {
      inherit configs;
      validations = allValidations;
      overall_validation = overallValidation;
      sources = mapAttrs (_: result: result.source) loadedConfigs;
      overrides_applied = mapAttrs (_: result: result.overrides_applied) loadedConfigs;
    };

  # Get a specific config value with path
  getConfigValue =
    configs: configType: path:
    let
      config = getAttr configType configs;
    in
    lib.getAttrFromPath path config;

  # Set a config value (for runtime overrides)
  setConfigValue =
    configs: configType: path: value:
    let
      config = getAttr configType configs;
      updatedConfig = lib.setAttrByPath path value config;
    in
    configs // { ${configType} = updatedConfig; };

  # Merge configuration with additional values
  mergeConfig = baseConfigs: additionalConfigs: recursiveUpdate baseConfigs additionalConfigs;

  # Get environment variable override information
  getEnvOverrideInfo = configType: {
    prefix = getAttr configType envPrefixes;
    known_vars = knownEnvVars configType;
    examples = map (var: {
      name = var;
      description = "Override ${lib.concatStringsSep "." (envVarToPath (getAttr configType envPrefixes) var)}";
    }) (lib.take 3 (knownEnvVars configType));
  };

  # Export defaults for external use
  inherit defaults;

  # Export validator for external use
  inherit validator;
}
