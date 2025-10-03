# Unit Tests for Config Validator
# Tests for YAML schema validation, type checking, and constraint validation

{ lib, pkgs }:

let
  validator = import ../../lib/config-validator.nix { inherit lib; };

  # Test helper functions
  runTest = name: test: {
    inherit name;
    result = test;
    passed = test.valid or false;
  };

  # Test data - valid configurations
  validPlatformsConfig = {
    platforms = {
      supported_systems = [
        "x86_64-darwin"
        "aarch64-darwin"
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

  validCacheConfig = {
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

  validNetworkConfig = {
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
      ];
      timeouts = {
        build = 3600;
        download = 300;
        connection = 30;
      };
    };
  };

  validPerformanceConfig = {
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

  validSecurityConfig = {
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

  # Test data - invalid configurations
  invalidPlatformsConfig = {
    platforms = {
      supported_systems = "not a list"; # Should be list
      platform_configs = {
        darwin = {
          type = "darwin";
          # Missing required fields
        };
      };
    };
    # Missing required system_detection
  };

  invalidCacheConfig = {
    cache = {
      local = {
        max_size_gb = -5; # Should be positive
        cleanup_days = 50; # Should be <= 30
      };
      binary_caches = [ "invalid-url" ]; # Should start with https://
    };
  };

  invalidNetworkConfig = {
    network = {
      http = {
        connections = -10; # Should be positive
        connect_timeout = 100; # Should be <= 30
      };
      timeouts = {
        build = 10000; # Should be <= 7200
      };
    };
  };

  invalidSecurityConfig = {
    security = {
      ssh = {
        key_type = "invalid"; # Should be ed25519, rsa, or ecdsa
      };
      permissions = {
        config_files = "777"; # Should be 644, 640, or 600
      };
    };
  };

in
{
  # Test individual config validation
  testValidPlatformsConfig = runTest "Valid platforms config" (
    validator.validateConfig "platforms" validPlatformsConfig
  );

  testValidCacheConfig = runTest "Valid cache config" (
    validator.validateConfig "cache" validCacheConfig
  );

  testValidNetworkConfig = runTest "Valid network config" (
    validator.validateConfig "network" validNetworkConfig
  );

  testValidPerformanceConfig = runTest "Valid performance config" (
    validator.validateConfig "performance" validPerformanceConfig
  );

  testValidSecurityConfig = runTest "Valid security config" (
    validator.validateConfig "security" validSecurityConfig
  );

  # Test invalid configurations
  testInvalidPlatformsConfig = runTest "Invalid platforms config should fail" (
    let
      result = validator.validateConfig "platforms" invalidPlatformsConfig;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testInvalidCacheConfig = runTest "Invalid cache config should fail" (
    let
      result = validator.validateConfig "cache" invalidCacheConfig;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testInvalidNetworkConfig = runTest "Invalid network config should fail" (
    let
      result = validator.validateConfig "network" invalidNetworkConfig;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  testInvalidSecurityConfig = runTest "Invalid security config should fail" (
    let
      result = validator.validateConfig "security" invalidSecurityConfig;
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  # Test unknown config type
  testUnknownConfigType = runTest "Unknown config type should fail" (
    let
      result = validator.validateConfig "unknown" { };
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  # Test all configs validation
  testValidateAllConfigs = runTest "Validate all configs" (
    validator.validateAllConfigs {
      platforms = validPlatformsConfig;
      cache = validCacheConfig;
      network = validNetworkConfig;
      performance = validPerformanceConfig;
      security = validSecurityConfig;
    }
  );

  # Test mixed valid/invalid configs
  testMixedValidation = runTest "Mixed valid/invalid configs should fail" (
    let
      result = validator.validateAllConfigs {
        platforms = validPlatformsConfig;
        cache = invalidCacheConfig;
        network = validNetworkConfig;
      };
    in
    {
      valid = !result.valid;
      errors = result.errors;
    }
  );

  # Test schema retrieval
  testGetSchema = runTest "Get schema for platforms" (
    let
      schema = validator.getSchema "platforms";
    in
    {
      valid = schema != null;
    }
  );

  testGetInvalidSchema = runTest "Get schema for invalid type" (
    let
      schema = validator.getSchema "invalid";
    in
    {
      valid = schema == null;
    }
  );

  # Test available types
  testAvailableTypes = runTest "Available types should include known types" (
    let
      types = validator.availableTypes;
    in
    {
      valid = lib.all (type: lib.elem type types) [
        "platforms"
        "cache"
        "network"
        "performance"
        "security"
      ];
    }
  );

  # Type validation edge cases
  testTypeValidationEdgeCases = runTest "Type validation edge cases" (
    let
      # Test string validation
      stringTest = validator.validateConfig "platforms" {
        platforms.supported_systems = [ "x86_64-darwin" ];
        platforms.platform_configs.darwin.type = 123; # Should be string
        platforms.platform_configs.darwin.rebuild_command = "test";
        platforms.platform_configs.darwin.rebuild_command_path = "test";
        platforms.platform_configs.darwin.flake_prefix = "test";
        platforms.platform_configs.darwin.platform_name = "test";
        platforms.platform_configs.darwin.allow_unfree = true;
        platforms.platform_configs.darwin.impure_mode = true;
        platforms.platform_configs.darwin.system_suffix = "test";
        platforms.platform_configs.linux = validPlatformsConfig.platforms.platform_configs.linux;
        platforms.architectures = validPlatformsConfig.platforms.architectures;
        system_detection = validPlatformsConfig.system_detection;
        flake_patterns = validPlatformsConfig.flake_patterns;
      };
    in
    {
      valid = !stringTest.valid;
    }
  );

  # Constraint validation edge cases
  testConstraintValidation = runTest "Constraint validation" (
    let
      # Test cache size constraint
      cacheTest = validator.validateConfig "cache" {
        cache = {
          local = {
            max_size_gb = 0; # Should be > 0
            cleanup_days = 7;
            stat_file = "test";
            cache_dir = "test";
          };
          binary_caches = [ "https://cache.nixos.org" ];
          behavior = validCacheConfig.cache.behavior;
          optimization = validCacheConfig.cache.optimization;
        };
      };
    in
    {
      valid = !cacheTest.valid;
    }
  );

  # Run all tests
  allTests = [
    testValidPlatformsConfig
    testValidCacheConfig
    testValidNetworkConfig
    testValidPerformanceConfig
    testValidSecurityConfig
    testInvalidPlatformsConfig
    testInvalidCacheConfig
    testInvalidNetworkConfig
    testInvalidSecurityConfig
    testUnknownConfigType
    testValidateAllConfigs
    testMixedValidation
    testGetSchema
    testGetInvalidSchema
    testAvailableTypes
    testTypeValidationEdgeCases
    testConstraintValidation
  ];

  # Test summary
  testSummary = {
    total = lib.length allTests;
    passed = lib.length (lib.filter (test: test.passed) allTests);
    failed = lib.length (lib.filter (test: !test.passed) allTests);
    results = allTests;
  };
}
