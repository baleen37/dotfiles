#!/bin/bash

# Configuration Usage Examples
# ===========================

echo "🔧 Configuration System Usage Examples"
echo "======================================"

# Load the configuration system
source scripts/utils/config-loader.sh

# Example 1: Basic configuration loading
echo ""
echo "📋 Example 1: Basic Configuration Loading"
echo "----------------------------------------"

# Load all configurations
load_all_configs

# Check if configs are loaded
if is_config_loaded; then
  echo "✅ Configuration system loaded successfully"
else
  echo "❌ Failed to load configuration"
  exit 1
fi

# Example 2: Get specific configuration values
echo ""
echo "📋 Example 2: Specific Configuration Access"
echo "------------------------------------------"

# Get build timeout with default
build_timeout=$(get_config "build" "timeout" "3600")
echo "Build timeout: ${build_timeout} seconds"

# Get SSH directory for Darwin
ssh_dir=$(get_config "path" "ssh_dir_darwin" "/Users/$USER/.ssh")
echo "SSH directory: $ssh_dir"

# Get parallel job count
parallel_jobs=$(get_config "build" "parallel_jobs" "4")
echo "Parallel jobs: $parallel_jobs"

# Example 3: Unified configuration interface
echo ""
echo "📋 Example 3: Unified Configuration Interface"
echo "--------------------------------------------"

# Intelligent search across all config types
platform_name=$(get_unified_config "platform_name" "Unknown")
echo "Platform name: $platform_name"

# Cache settings with fallback
cache_size=$(get_unified_config "max_size_gb" "5")
echo "Cache size: ${cache_size}GB"

# Network timeout
timeout=$(get_unified_config "connect_timeout" "5")
echo "Connection timeout: ${timeout}s"

# Example 4: Platform-specific configuration
echo ""
echo "📋 Example 4: Platform-Specific Configuration"
echo "--------------------------------------------"

# Detect current platform
if [[ $OSTYPE == "darwin"* ]]; then
  PLATFORM="darwin"
elif [[ $OSTYPE == "linux-gnu"* ]]; then
  PLATFORM="linux"
else
  PLATFORM="unknown"
fi

# Get platform-specific rebuild command
rebuild_cmd=$(load_platform_config "$PLATFORM" "rebuild_command" "nix-rebuild")
echo "Rebuild command for $PLATFORM: $rebuild_cmd"

# Get platform-specific settings
allow_unfree=$(load_platform_config "$PLATFORM" "allow_unfree" "false")
echo "Allow unfree packages: $allow_unfree"

# Example 5: Advanced configuration functions
echo ""
echo "📋 Example 5: Advanced Configuration Functions"
echo "---------------------------------------------"

# Cache configuration
max_cache=$(load_cache_config "max_size_gb" "5")
cleanup_days=$(load_cache_config "cleanup_days" "7")
echo "Cache: ${max_cache}GB, cleanup after ${cleanup_days} days"

# Network configuration
connections=$(load_network_config "http_connections" "50")
download_attempts=$(load_network_config "download_attempts" "3")
echo "Network: ${connections} connections, ${download_attempts} retry attempts"

# Security configuration
key_type=$(load_security_config "ssh_key_type" "ed25519")
sudo_interval=$(load_security_config "sudo_refresh_interval" "240")
echo "SSH key type: $key_type, sudo refresh: ${sudo_interval}s"

# Example 6: Configuration profiles
echo ""
echo "📋 Example 6: Configuration Profiles"
echo "-----------------------------------"

# Check current profile
current_profile="${CONFIG_PROFILE:-default}"
echo "Current profile: $current_profile"

# Profile-specific settings
case "$current_profile" in
"development")
  echo "Development profile: verbose logging, longer timeouts"
  ;;
"production")
  echo "Production profile: optimized settings, minimal logging"
  ;;
*)
  echo "Default profile: balanced settings"
  ;;
esac

# Example 7: Environment variable overrides
echo ""
echo "📋 Example 7: Environment Variable Overrides"
echo "--------------------------------------------"

# Show how environment variables take precedence
echo "Cache size from config: $(get_config 'build' 'cache_size' '5')"
echo "Cache size from env: ${CACHE_MAX_SIZE_GB:-'Not set'}"

# Final unified value (env overrides config)
final_cache=$(get_unified_config "max_size_gb" "5")
echo "Final cache size: ${final_cache}GB"

echo ""
echo "🎉 Configuration examples completed!"
echo "💡 Tip: Use get_unified_config() for intelligent fallbacks"
echo "📚 See docs/CONFIGURATION-GUIDE.md for more details"
