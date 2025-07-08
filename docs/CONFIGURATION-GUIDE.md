# Configuration Guide

> **Complete guide to external configuration system and customization**

This guide covers the external configuration system implemented in Phase 4, including YAML-based settings, configuration profiles, and advanced customization options.

## Overview

The dotfiles system uses a sophisticated external configuration system that allows for:

- **YAML-based configuration**: Human-readable configuration files
- **Environment profiles**: Different settings for development/production
- **Intelligent fallbacks**: Graceful degradation with default values
- **Performance optimization**: Configuration caching and unified access
- **Platform-specific settings**: Tailored configurations per platform

## 📁 Configuration File Structure

```
config/
├── build-settings.yaml      # Build system configuration
├── platforms.yaml          # Platform-specific settings
├── paths.yaml              # Directory and path mappings
├── advanced-settings.yaml  # Advanced configuration options
└── profiles/               # Environment-specific profiles
    ├── development.yaml    # Development environment settings
    └── production.yaml     # Production environment settings
```

## 🔧 Core Configuration Files

### build-settings.yaml
Controls build system behavior and performance settings.

```yaml
# Build configuration settings
build:
  timeout: 3600  # Build timeout in seconds
  parallel_jobs: 4  # Number of parallel build jobs
  experimental_features:
    - nix-command
    - flakes

  darwin:
    allow_unfree: true
    impure_mode: true

  linux:
    allow_unfree: false
    impure_mode: false
```

### platforms.yaml
Defines platform-specific configurations and supported architectures.

```yaml
platforms:
  supported_systems:
    - "x86_64-darwin"
    - "aarch64-darwin"
    - "x86_64-linux"
    - "aarch64-linux"

  platform_configs:
    darwin:
      rebuild_command: "darwin-rebuild"
      flake_prefix: "darwinConfigurations"
      allow_unfree: true
    linux:
      rebuild_command: "nixos-rebuild"
      flake_prefix: "nixosConfigurations"
      allow_unfree: false
```

### paths.yaml
Manages directory paths and system-specific locations.

```yaml
# SSH directory paths by platform
ssh_directories:
  darwin: "/Users/${USER}/.ssh"
  linux: "/home/${USER}/.ssh"

# Base directories
base_directories:
  config_dir: "config"
  scripts_dir: "scripts"
  modules_dir: "modules"
```

## 🚀 Using the Configuration System

### Loading Configuration

The configuration system automatically loads when needed:

```bash
# Load all configurations
source scripts/utils/config-loader.sh
load_all_configs

# Get specific configuration values
timeout=$(get_config build timeout)
ssh_dir=$(get_config path ssh_dir_darwin)
```

### Unified Configuration Access

Use the unified interface for intelligent configuration access:

```bash
# Searches across all config types with fallback
value=$(get_unified_config "setting_name" "default_value")

# Examples
build_timeout=$(get_unified_config timeout "3600")
platform_name=$(get_unified_config platform_name "Unknown")
```

### Configuration Profiles

Switch between different environment profiles:

```bash
# Development profile (more verbose, longer timeouts)
export CONFIG_PROFILE="development"

# Production profile (conservative, optimized)
export CONFIG_PROFILE="production"
```

## 🛠️ Advanced Configuration

### Advanced Settings (advanced-settings.yaml)

```yaml
# Development environment settings
development:
  debug_mode: false
  verbose_logging: false
  performance_monitoring: true

# Build optimization settings
build_optimization:
  enable_ccache: true
  parallel_builds: true
  memory_limit: "8G"

# Security settings
security:
  strict_permissions: true
  verify_signatures: true
  sandbox_mode: true
```

### Profile System

#### Development Profile (config/profiles/development.yaml)
```yaml
build:
  timeout: 7200  # Longer timeout for dev builds
  parallel_jobs: 8  # More parallel jobs
  experimental_features: "nix-command flakes ca-derivations"

development:
  debug_mode: true
  verbose_logging: true
  performance_monitoring: true
```

#### Production Profile (config/profiles/production.yaml)
```yaml
build:
  timeout: 3600  # Standard timeout
  parallel_jobs: 4  # Conservative parallel jobs
  experimental_features: "nix-command flakes"

security:
  strict_permissions: true
  sandbox_mode: true
```

## 🔍 Configuration Functions Reference

### Core Functions

- `load_all_configs()`: Load all configuration files
- `get_config(type, key, default)`: Get specific configuration value
- `get_unified_config(key, default)`: Intelligent cross-type config search
- `is_config_loaded()`: Check if configuration is already loaded

### Performance Features

- **Configuration Caching**: Prevents redundant loading
- **Lazy Loading**: Configurations loaded only when needed
- **State Tracking**: Monitors configuration loading status

## 🔧 Customization Examples

### Custom Build Settings
```yaml
# Override default build behavior
build:
  parallel_jobs: 16  # Use more cores
  timeout: 10800     # Extend timeout for large builds

# Platform-specific overrides
darwin:
  allow_unfree: true
  use_xcode_tools: true
```

### Custom Path Mappings
```yaml
# Override default SSH directory
ssh_directories:
  darwin: "/custom/ssh/path"

# Add custom cache locations
cache_directories:
  build_cache: ".cache/custom-build"
  nix_cache: "/tmp/custom-nix-cache"
```

### Environment Variables

Configuration values are automatically exported as environment variables:

- `BUILD_TIMEOUT`: Build timeout setting
- `PARALLEL_JOBS`: Number of parallel jobs
- `SSH_BASE_DIR`: Platform-specific SSH directory
- `NIXPKGS_ALLOW_UNFREE`: Allow unfree packages setting

## 🐛 Troubleshooting

### Configuration Not Loading
1. Check file syntax: `yamllint config/*.yaml`
2. Verify file permissions
3. Check config loader output: `bash scripts/utils/config-loader.sh`

### Missing Configuration Values
1. Use unified config with fallbacks: `get_unified_config key default`
2. Check profile loading: `echo $CONFIG_PROFILE`
3. Verify default configuration loading

### Performance Issues
1. Configuration caching enabled: Check `CONFIG_CACHE_LOADED`
2. Avoid redundant loading calls
3. Use `is_config_loaded()` before loading

## 🔄 Migration from Legacy System

For users upgrading from the pre-Phase 4 system:

1. **Hardcoded values**: Now externalized to YAML files
2. **Platform detection**: Improved with fallback mechanisms
3. **Build settings**: Configurable via external files
4. **Path management**: Centralized in paths.yaml

Legacy scripts continue to work with automatic fallback to default values.
