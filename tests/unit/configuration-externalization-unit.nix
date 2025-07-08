# Configuration Externalization Tests
# TDD for Phase 4 Sprint 4.2 - Configuration externalization

{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "configuration-externalization-test"
{
  buildInputs = with pkgs; [ bash yq jq coreutils findutils ];
} ''
  echo "🧪 Configuration Externalization Tests"
  echo "===================================="

  # Test 1: Configuration files structure exists
  echo ""
  echo "📋 Test 1: Configuration Files Structure"
  echo "---------------------------------------"

  config_dir="${src}/config"
  config_files_found=0

  # Check for expected configuration files
  expected_configs=(
    "platforms.yaml"
    "cache.yaml"
    "network.yaml"
    "performance.yaml"
    "security.yaml"
  )

  if [[ -d "$config_dir" ]]; then
    echo "✅ Configuration directory exists"
    for config_file in "''${expected_configs[@]}"; do
      if [[ -f "$config_dir/$config_file" ]]; then
        echo "✅ Found: $config_file"
        config_files_found=$((config_files_found + 1))
      else
        echo "❌ Missing: $config_file"
      fi
    done
  else
    echo "❌ Configuration directory missing"
    exit 1
  fi

  if [[ $config_files_found -ge 3 ]]; then
    echo "✅ Sufficient configuration files found: $config_files_found/''${#expected_configs[@]}"
  else
    echo "❌ Insufficient configuration files: $config_files_found/''${#expected_configs[@]}"
    exit 1
  fi

  # Test 2: No hardcoded cache values in scripts
  echo ""
  echo "📋 Test 2: Cache Configuration Externalization"
  echo "--------------------------------------------"

  # Check that cache-management.sh uses externalized config
  cache_script="${src}/scripts/lib/cache-management.sh"
  if [[ -f "$cache_script" ]]; then
    # Should not have hardcoded CACHE_MAX_SIZE_GB=5
    if ! grep -q "CACHE_MAX_SIZE_GB=5" "$cache_script"; then
      echo "✅ Cache size not hardcoded in cache-management.sh"
    else
      echo "❌ Cache size still hardcoded in cache-management.sh"
      exit 1
    fi

    # Should not have hardcoded CACHE_CLEANUP_DAYS=7
    if ! grep -q "CACHE_CLEANUP_DAYS=7" "$cache_script"; then
      echo "✅ Cache cleanup days not hardcoded"
    else
      echo "❌ Cache cleanup days still hardcoded"
      exit 1
    fi
  else
    echo "⚠️  cache-management.sh not found, skipping test"
  fi

  # Test 3: Configuration loading mechanism
  echo ""
  echo "📋 Test 3: Configuration Loading Mechanism"
  echo "----------------------------------------"

  # Check for configuration loader utility
  config_loader="${src}/scripts/lib/config-loader.sh"
  if [[ -f "$config_loader" ]]; then
    echo "✅ Configuration loader exists"

    # Check for key functions
    if grep -q "load_config" "$config_loader"; then
      echo "✅ load_config function found"
    else
      echo "❌ load_config function missing"
      exit 1
    fi
  else
    echo "❌ Configuration loader missing"
    exit 1
  fi

  # Test 4: Environment variable defaults
  echo ""
  echo "📋 Test 4: Environment Variable Defaults"
  echo "---------------------------------------"

  # Check that scripts use environment variables with defaults
  scripts_using_env=0

  # Check cache management
  if [[ -f "$cache_script" ]]; then
    if grep -q ':-' "$cache_script"; then
      echo "✅ cache-management.sh uses environment variable defaults"
      scripts_using_env=$((scripts_using_env + 1))
    fi
  fi

  # Check platform config
  platform_configs=($(find "${src}/apps" -name "config.sh" 2>/dev/null))
  if [[ ''${#platform_configs[@]} -gt 0 ]]; then
    for config in "''${platform_configs[@]}"; do
      if grep -q ':-' "$config"; then
        scripts_using_env=$((scripts_using_env + 1))
        break
      fi
    done
    if [[ $scripts_using_env -gt 1 ]]; then
      echo "✅ Platform configs use environment variable defaults"
    fi
  fi

  if [[ $scripts_using_env -ge 2 ]]; then
    echo "✅ Scripts properly use environment variable defaults"
  else
    echo "❌ Scripts not using environment variable defaults: $scripts_using_env found"
    exit 1
  fi

  # Test 5: Configuration validation
  echo ""
  echo "📋 Test 5: Configuration Validation"
  echo "----------------------------------"

  # Check for configuration validation script
  config_validator="${src}/scripts/validate-config"
  if [[ -f "$config_validator" ]]; then
    echo "✅ Configuration validator exists"

    # Check if it's executable
    if [[ -x "$config_validator" ]]; then
      echo "✅ Configuration validator is executable"
    else
      echo "❌ Configuration validator not executable"
      exit 1
    fi
  else
    echo "❌ Configuration validator missing"
    exit 1
  fi

  echo ""
  echo "🎉 All Configuration Externalization Tests Completed!"
  echo "===================================================="
  echo ""
  echo "Summary:"
  echo "- Configuration files structure: ✅"
  echo "- Cache configuration externalization: ✅"
  echo "- Configuration loading mechanism: ✅"
  echo "- Environment variable defaults: ✅"
  echo "- Configuration validation: ✅"

  touch $out
''
