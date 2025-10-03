# External Configuration System Usage Guide

## Overview

The external configuration system provides YAML-based configuration with environment variable overrides and comprehensive validation. All configuration files are stored in the `config/` directory and follow strict schemas.

## Configuration Files

The system supports five configuration types:

- `config/platforms.yaml` - Platform-specific settings (Darwin/NixOS)
- `config/cache.yaml` - Cache management configuration
- `config/network.yaml` - Network and download settings  
- `config/performance.yaml` - Build and system performance
- `config/security.yaml` - Security policies and SSH settings

## Basic Usage

### In Nix Modules

```nix
# modules/shared/example.nix
{ lib, pkgs, ... }:

let
  # Import the flake config utilities
  utils = (import ../../lib/flake-config.nix).utils nixpkgs;
  
  # Load and validate specific config
  platformConfig = utils.getValidatedConfig ./../../config "platforms";
  
  # Merge external config with module defaults
  cacheConfig = utils.mergeExternalConfig ./../../config "cache" {
    # Module-specific defaults
    cache.local.max_size_gb = 10;
  };
in
{
  # Use configuration values
  nix.settings.max-jobs = platformConfig.platforms.platform_configs.darwin.cores or "auto";
  
  # Access nested values
  networking.timeouts.connection = cacheConfig.cache.optimization.parallel_downloads;
}
```

### Loading All Configurations

```nix
# Load all configurations at once
let
  allConfigs = utils.loadExternalConfigs ./config;
in
{
  # Check if all configurations are valid
  assertions = [
    {
      assertion = allConfigs.overall_validation.valid;
      message = "Configuration validation failed: ${lib.concatStringsSep ", " allConfigs.overall_validation.errors}";
    }
  ];
  
  # Use configurations
  programs.ssh.keyType = allConfigs.configs.security.security.ssh.key_type;
  nix.settings.substituters = map (s: s.url) allConfigs.configs.network.network.substituters;
}
```

## Environment Variable Overrides

Override any configuration value using environment variables with the pattern:
`DOTFILES_{CONFIG_TYPE}_{NESTED_PATH}`

### Examples

```bash
# Override cache settings
export DOTFILES_CACHE_LOCAL_MAX_SIZE_GB=20
export DOTFILES_CACHE_OPTIMIZATION_PARALLEL_DOWNLOADS=30

# Override network timeouts
export DOTFILES_NETWORK_TIMEOUTS_BUILD=7200
export DOTFILES_NETWORK_HTTP_CONNECTIONS=100

# Override security settings
export DOTFILES_SECURITY_SSH_KEY_TYPE=rsa
export DOTFILES_SECURITY_POLICIES_ALLOW_UNFREE=false

# Override performance settings
export DOTFILES_PERFORMANCE_BUILD_MAX_JOBS=8
export DOTFILES_PERFORMANCE_NIX_SANDBOX=false
```

### Available Environment Variables

#### Platform Configuration
- `DOTFILES_PLATFORM_SYSTEM_DETECTION_AUTO_DETECT`
- `DOTFILES_PLATFORM_SYSTEM_DETECTION_FALLBACK_ARCHITECTURE`
- `DOTFILES_PLATFORM_SYSTEM_DETECTION_FALLBACK_PLATFORM`

#### Cache Configuration
- `DOTFILES_CACHE_LOCAL_MAX_SIZE_GB`
- `DOTFILES_CACHE_LOCAL_CLEANUP_DAYS`
- `DOTFILES_CACHE_OPTIMIZATION_AUTO_OPTIMIZE`
- `DOTFILES_CACHE_OPTIMIZATION_PARALLEL_DOWNLOADS`

#### Network Configuration
- `DOTFILES_NETWORK_HTTP_CONNECTIONS`
- `DOTFILES_NETWORK_HTTP_CONNECT_TIMEOUT`
- `DOTFILES_NETWORK_TIMEOUTS_BUILD`
- `DOTFILES_NETWORK_TIMEOUTS_DOWNLOAD`

#### Performance Configuration
- `DOTFILES_PERFORMANCE_BUILD_MAX_JOBS`
- `DOTFILES_PERFORMANCE_BUILD_CORES`
- `DOTFILES_PERFORMANCE_MEMORY_MIN_FREE`
- `DOTFILES_PERFORMANCE_NIX_MAX_SUBSTITUTION_JOBS`

#### Security Configuration
- `DOTFILES_SECURITY_SSH_KEY_TYPE`
- `DOTFILES_SECURITY_SSH_KEY_SIZE`
- `DOTFILES_SECURITY_POLICIES_ALLOW_UNFREE`
- `DOTFILES_SECURITY_BUILD_REQUIRE_SIGS`

## Validation

### Schema Validation

All configurations are validated against strict schemas:

```nix
# Check if a config is valid
let
  validator = utils.configValidator;
  result = validator.validateConfig "platforms" myPlatformConfig;
in
if result.valid
then myPlatformConfig
else throw "Configuration errors: ${lib.concatStringsSep ", " result.errors}"
```

### Available Validation Functions

```nix
# Validate a single config type
validator.validateConfig "cache" cacheConfig

# Validate all configs at once
validator.validateAllConfigs {
  platforms = platformsConfig;
  cache = cacheConfig;
  network = networkConfig;
}

# Get schema for a config type
validator.getSchema "security"

# List all available types
validator.availableTypes  # ["platforms", "cache", "network", "performance", "security"]
```

## Direct Configuration Access

### Using the Config Loader

```nix
let
  loader = utils.configLoader;
  
  # Load a single config file
  cacheResult = loader.loadConfig "cache" "./config/cache.yaml";
  
  # Load all configs from directory
  allResult = loader.loadAllConfigs "./config";
in
{
  # Access configuration
  cache_size = cacheResult.config.cache.local.max_size_gb;
  
  # Check validation status
  is_valid = cacheResult.validation.valid;
  
  # View errors if any
  errors = cacheResult.validation.errors;
  
  # Check source (yaml or defaults)
  source = cacheResult.source;
}
```

### Configuration Manipulation

```nix
let
  loader = utils.configLoader;
  configs = loader.defaults;  # Start with defaults
  
  # Get a specific value
  autoDetect = loader.getConfigValue configs "platforms" ["system_detection" "auto_detect"];
  
  # Set a specific value
  updatedConfigs = loader.setConfigValue configs "platforms" ["system_detection" "auto_detect"] false;
  
  # Merge configurations
  mergedConfigs = loader.mergeConfig configs additionalConfigs;
in
{ ... }
```

## Error Handling

### Configuration Validation Errors

```nix
let
  result = utils.loadExternalConfigs ./config;
in
{
  # Add assertions for configuration validity
  assertions = [
    {
      assertion = result.overall_validation.valid;
      message = ''
        Configuration validation failed:
        ${lib.concatStringsSep "\n" result.overall_validation.errors}
      '';
    }
  ];
  
  # Graceful fallback to defaults
  cacheConfig = 
    if result.validations.cache.valid
    then result.configs.cache
    else utils.configLoader.defaults.cache;
}
```

### Environment Variable Override Information

```nix
# Get information about available environment variable overrides
let
  cacheOverrideInfo = utils.configLoader.getEnvOverrideInfo "cache";
in
{
  # cacheOverrideInfo.prefix = "DOTFILES_CACHE_"
  # cacheOverrideInfo.known_vars = [ "DOTFILES_CACHE_LOCAL_MAX_SIZE_GB" ... ]
  # cacheOverrideInfo.examples = [ { name = "..."; description = "..."; } ... ]
}
```

## Integration Examples

### Darwin Configuration

```nix
# hosts/darwin/default.nix
{ lib, pkgs, ... }:

let
  utils = (import ../../lib/flake-config.nix).utils nixpkgs;
  platformConfig = utils.getValidatedConfig ./../../config "platforms";
  performanceConfig = utils.getValidatedConfig ./../../config "performance";
in
{
  # Use platform-specific settings
  system.stateVersion = 4;
  
  # Apply performance settings
  nix.settings = {
    max-jobs = performanceConfig.performance.build.max_jobs;
    cores = performanceConfig.performance.build.cores;
    auto-optimise-store = performanceConfig.performance.nix.auto_optimise_store;
  };
  
  # Use platform configuration
  system.rebuild.command = platformConfig.platforms.platform_configs.darwin.rebuild_command;
}
```

### Home Manager Configuration

```nix
# modules/shared/programs/ssh.nix
{ lib, pkgs, ... }:

let
  utils = (import ../../../lib/flake-config.nix).utils nixpkgs;
  securityConfig = utils.getValidatedConfig ./../../../config "security";
in
{
  programs.ssh = {
    enable = true;
    
    # Use security configuration
    keyType = securityConfig.security.ssh.key_type;
    keySize = securityConfig.security.ssh.key_size;
    
    # Use configured permissions
    userKnownHostsFile = lib.mkDefault "${securityConfig.security.ssh.default_dir}/known_hosts";
  };
}
```

## Testing

The configuration system includes comprehensive tests:

- `tests/unit/test-config-validator.nix` - Unit tests for schema validation
- `tests/integration/test-config-loader.nix` - Integration tests for loading and overrides

Run tests with:
```bash
make test-config
```

## Constitutional Requirements

The external configuration system follows constitutional requirements:

✅ **External configuration files in `config/` directory**
✅ **Environment variables MUST override configuration values**  
✅ **Configuration validation MUST occur before system application**
✅ **All sensitive data MUST use environment variables**

## Troubleshooting

### Common Issues

1. **Configuration validation fails**
   - Check YAML syntax with `yamllint config/`
   - Verify required fields are present
   - Check constraints (e.g., positive numbers, valid URLs)

2. **Environment overrides not working**
   - Verify environment variable name format: `DOTFILES_{TYPE}_{PATH}`
   - Check variable is exported: `export DOTFILES_CACHE_LOCAL_MAX_SIZE_GB=10`
   - Restart Nix evaluation after setting variables

3. **Configuration not found**
   - Ensure YAML files exist in `config/` directory
   - Check file permissions are readable
   - Verify path is correct in module imports

### Debug Configuration Loading

```nix
let
  loader = utils.configLoader;
  result = loader.loadConfig "cache" "./config/cache.yaml";
in
{
  # Debug output
  debug = {
    config_source = result.source;          # "yaml" or "defaults"
    validation_valid = result.validation.valid;
    validation_errors = result.validation.errors;
    overrides_applied = result.overrides_applied;
  };
}
```