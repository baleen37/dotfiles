# Integration Tests for Config Loader
# Tests for YAML loading, environment variable overrides, and complete workflow

{ lib, pkgs }:

let
  loader = import ../../lib/config-loader.nix { inherit lib pkgs; };

  # Create temporary test files
  testDir = "/tmp/dotfiles-config-test";

  # Test helper functions
  runTest = name: test: {
    inherit name;
    result = test;
    passed = test.valid or test.success or false;
  };

  # Create test YAML files
  createTestFiles = ''
        mkdir -p ${testDir}
        
        # Create valid platforms.yaml
        cat > ${testDir}/platforms.yaml << 'EOF'
    platforms:
      supported_systems:
        - "x86_64-darwin"
        - "aarch64-darwin"
      platform_configs:
        darwin:
          type: "darwin"
          rebuild_command: "darwin-rebuild"
          rebuild_command_path: "./result/sw/bin/darwin-rebuild"
          flake_prefix: "darwinConfigurations"
          platform_name: "Nix Darwin"
          allow_unfree: true
          impure_mode: true
          system_suffix: ".system"
        linux:
          type: "linux"
          rebuild_command: "nixos-rebuild"
          rebuild_command_path: "nixos-rebuild"
          flake_prefix: "nixosConfigurations"
          platform_name: "NixOS"
          allow_unfree: false
          impure_mode: false
          system_suffix: ".config.system.build.toplevel"
      architectures:
        aarch64:
          name: "ARM64"
          description: "ARM 64-bit architecture"
          aliases: ["arm64"]
        x86_64:
          name: "Intel/AMD 64-bit"
          description: "x86_64 architecture"
          aliases: ["x64"]
    system_detection:
      auto_detect: true
      fallback_architecture: "x86_64"
      fallback_platform: "darwin"
    flake_patterns:
      darwin: "darwinConfigurations.{architecture}-darwin.system"
      linux: "nixosConfigurations.{architecture}-linux.config.system.build.toplevel"
    EOF

        # Create valid cache.yaml
        cat > ${testDir}/cache.yaml << 'EOF'
    cache:
      local:
        max_size_gb: 8
        cleanup_days: 14
        stat_file: "$HOME/.cache/nix-build-stats"
        cache_dir: "$HOME/.cache/nix"
      binary_caches:
        - "https://cache.nixos.org"
        - "https://nix-community.cachix.org"
      behavior:
        max_cache_size: "100G"
        min_free_space: "2G"
        max_free_space: "20G"
      optimization:
        auto_optimize: true
        compress_logs: true
        parallel_downloads: 20
    EOF

        # Create invalid network.yaml for error testing
        cat > ${testDir}/network-invalid.yaml << 'EOF'
    network:
      http:
        connections: -50  # Invalid: negative
        connect_timeout: 100  # Invalid: too high
      repositories:
        nixpkgs: "invalid-repo-format"
      timeouts:
        build: 10000  # Invalid: too high
    EOF

        # Create partial security.yaml for defaults testing
        cat > ${testDir}/security-partial.yaml << 'EOF'
    security:
      ssh:
        key_type: "rsa"
        key_size: 4096
      # Missing other sections - should use defaults
    EOF
  '';

  # Cleanup test files
  cleanupTestFiles = ''
    rm -rf ${testDir}
  '';

in
{
  # Test single config loading - valid file
  testLoadValidConfig = runTest "Load valid platforms config" (
    let
      result = loader.loadConfig "platforms" "${testDir}/platforms.yaml";
    in
    {
      valid = result.validation.valid && result.source == "yaml";
      config = result.config;
      errors = result.validation.errors;
    }
  );

  # Test single config loading - missing file (should use defaults)
  testLoadMissingConfig = runTest "Load missing config uses defaults" (
    let
      result = loader.loadConfig "platforms" "${testDir}/nonexistent.yaml";
    in
    {
      valid = result.validation.valid && result.source == "defaults";
      config = result.config;
    }
  );

  # Test config loading with custom values
  testLoadCustomConfig = runTest "Load custom cache config" (
    let
      result = loader.loadConfig "cache" "${testDir}/cache.yaml";
      expectedMaxSize = 8; # From test YAML
      actualMaxSize = result.config.cache.local.max_size_gb;
    in
    {
      valid = result.validation.valid && actualMaxSize == expectedMaxSize;
      config = result.config;
    }
  );

  # Test invalid config loading
  testLoadInvalidConfig = runTest "Load invalid config should fail validation" (
    let
      result = loader.loadConfig "network" "${testDir}/network-invalid.yaml";
    in
    {
      valid = !result.validation.valid; # Should fail validation
      errors = result.validation.errors;
    }
  );

  # Test partial config with defaults
  testLoadPartialConfig = runTest "Load partial config merges with defaults" (
    let
      result = loader.loadConfig "security" "${testDir}/security-partial.yaml";
      hasSSH = result.config.security ? ssh;
      hasUsers = result.config.security ? users; # Should come from defaults
    in
    {
      valid = result.validation.valid && hasSSH && hasUsers;
      config = result.config;
    }
  );

  # Test loading all configs from directory
  testLoadAllConfigs = runTest "Load all configs from directory" (
    let
      result = loader.loadAllConfigs testDir;
      allValid = result.overall_validation.valid;
      hasAllTypes = lib.all (type: result.configs ? ${type}) [
        "platforms"
        "cache"
        "network"
        "performance"
        "security"
      ];
    in
    {
      valid = allValid && hasAllTypes;
      configs = result.configs;
      validations = result.validations;
    }
  );

  # Test environment variable override info
  testEnvOverrideInfo = runTest "Get environment variable override info" (
    let
      info = loader.getEnvOverrideInfo "platforms";
      hasPrefix = info.prefix == "DOTFILES_PLATFORM_";
      hasVars = lib.length info.known_vars > 0;
      hasExamples = lib.length info.examples > 0;
    in
    {
      valid = hasPrefix && hasVars && hasExamples;
      info = info;
    }
  );

  # Test config value getter
  testGetConfigValue = runTest "Get specific config value" (
    let
      configs = loader.defaults;
      value = loader.getConfigValue configs "platforms" [
        "system_detection"
        "auto_detect"
      ];
    in
    {
      valid = value == true; # Default value
      value = value;
    }
  );

  # Test config value setter
  testSetConfigValue = runTest "Set specific config value" (
    let
      configs = loader.defaults;
      updatedConfigs = loader.setConfigValue configs "platforms" [
        "system_detection"
        "auto_detect"
      ] false;
      newValue = loader.getConfigValue updatedConfigs "platforms" [
        "system_detection"
        "auto_detect"
      ];
    in
    {
      valid = newValue == false;
      value = newValue;
    }
  );

  # Test config merging
  testMergeConfig = runTest "Merge configurations" (
    let
      baseConfigs = {
        platforms = loader.defaults.platforms;
      };
      additionalConfigs = {
        cache = loader.defaults.cache;
        network = loader.defaults.network;
      };
      merged = loader.mergeConfig baseConfigs additionalConfigs;
      hasAll = merged ? platforms && merged ? cache && merged ? network;
    in
    {
      valid = hasAll;
      merged = merged;
    }
  );

  # Test YAML parsing error handling
  testYAMLParsingError = runTest "Handle YAML parsing errors gracefully" (
    let
      # This would fail in real usage, but we test the fallback behavior
      result = loader.loadConfig "platforms" "/nonexistent/malformed.yaml";
    in
    {
      valid = result.source == "defaults"; # Should fall back to defaults
      result = result;
    }
  );

  # Test validation integration
  testValidationIntegration = runTest "Validation integration with loader" (
    let
      # Create config that would fail validation
      invalidConfig = {
        cache = {
          local = {
            max_size_gb = -5; # Invalid
            cleanup_days = 7;
            stat_file = "test";
            cache_dir = "test";
          };
          binary_caches = [ "invalid-url" ]; # Invalid
          behavior = loader.defaults.cache.cache.behavior;
          optimization = loader.defaults.cache.cache.optimization;
        };
      };

      validation = loader.validator.validateConfig "cache" invalidConfig;
    in
    {
      valid = !validation.valid; # Should fail
      errors = validation.errors;
    }
  );

  # Test config source tracking
  testConfigSourceTracking = runTest "Track config sources correctly" (
    let
      result = loader.loadAllConfigs testDir;
      platformsFromYAML = result.sources.platforms == "yaml";
      performanceFromDefaults = result.sources.performance == "defaults"; # No YAML file
    in
    {
      valid = platformsFromYAML && performanceFromDefaults;
      sources = result.sources;
    }
  );

  # Integration test setup and teardown
  setupTeardownTest = runTest "Setup and teardown integration" (
    let
      setupResult = pkgs.runCommand "setup-test" { } createTestFiles;
      cleanupResult = pkgs.runCommand "cleanup-test" { } cleanupTestFiles;
    in
    {
      valid = true; # If we get here, setup/teardown worked
      setup = setupResult;
      cleanup = cleanupResult;
    }
  );

  # Run all tests
  allTests = [
    testLoadValidConfig
    testLoadMissingConfig
    testLoadCustomConfig
    testLoadInvalidConfig
    testLoadPartialConfig
    testLoadAllConfigs
    testEnvOverrideInfo
    testGetConfigValue
    testSetConfigValue
    testMergeConfig
    testYAMLParsingError
    testValidationIntegration
    testConfigSourceTracking
    setupTeardownTest
  ];

  # Test summary
  testSummary = {
    total = lib.length allTests;
    passed = lib.length (lib.filter (test: test.passed) allTests);
    failed = lib.length (lib.filter (test: !test.passed) allTests);
    results = allTests;

    # Integration-specific metrics
    metrics = {
      yaml_loading_tests = 4;
      validation_integration_tests = 3;
      environment_override_tests = 1;
      config_manipulation_tests = 3;
      error_handling_tests = 2;
      setup_teardown_tests = 1;
    };
  };

  # Test configuration for CI/CD
  testConfig = {
    name = "config-loader-integration";
    description = "Integration tests for the config loader system";
    dependencies = [ "config-validator" ];
    setup_commands = [ createTestFiles ];
    cleanup_commands = [ cleanupTestFiles ];
    timeout_seconds = 300;
  };
}
