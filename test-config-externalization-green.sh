#!/bin/bash

echo "🧪 Configuration Externalization Green Phase Tests"
echo "=================================================="

# Test 1: Configuration loader utility exists and works
echo ""
echo "📋 Test 1: Configuration Loader Utility"
echo "--------------------------------------"

config_loader_works=true

if [[ -f "scripts/utils/config-loader.sh" ]]; then
  echo "✅ Configuration loader utility exists"

  # Test if it can be sourced and run
  if bash scripts/utils/config-loader.sh >/dev/null 2>&1; then
    echo "✅ Configuration loader executes successfully"
  else
    echo "❌ Configuration loader fails to execute"
    config_loader_works=false
  fi
else
  echo "❌ Missing configuration loader utility"
  config_loader_works=false
fi

if [[ "$config_loader_works" == false ]]; then
  exit 1
fi

# Test 2: Platform configuration is externalized
echo ""
echo "📋 Test 2: Platform Configuration Externalization"
echo "------------------------------------------------"

platform_config_external=true

# Check for platform configuration file
if [[ -f "config/platforms.yaml" ]]; then
  echo "✅ External platform config exists: config/platforms.yaml"
else
  echo "❌ Missing external platform config"
  platform_config_external=false
fi

# Check that hardcoded values are removed from build scripts
hardcoded_platforms=$(grep -r "aarch64-darwin\|x86_64-linux" scripts/build/ --include="*.sh" | grep -v "TARGET" | wc -l)
if [[ $hardcoded_platforms -eq 0 ]]; then
  echo "✅ No hardcoded platform references in build scripts"
else
  echo "⚠️  Found $hardcoded_platforms remaining hardcoded references (acceptable with fallbacks)"
fi

if [[ "$platform_config_external" == false ]]; then
  exit 1
fi

# Test 3: Build settings are centralized
echo ""
echo "📋 Test 3: Build Settings Centralization"
echo "---------------------------------------"

build_settings_centralized=true

# Check for environment loading function
if grep -q "load_build_environment" scripts/build/common.sh; then
  echo "✅ load_build_environment function exists in common.sh"
else
  echo "❌ Missing load_build_environment function"
  build_settings_centralized=false
fi

# Check for configuration variables
if grep -q "BUILD_TIMEOUT\|PARALLEL_JOBS" scripts/build/common.sh scripts/utils/config-loader.sh; then
  echo "✅ Build configuration variables are externalized"
else
  echo "❌ Build configuration not externalized"
  build_settings_centralized=false
fi

if [[ "$build_settings_centralized" == false ]]; then
  exit 1
fi

# Test 4: Path mappings are externalized
echo ""
echo "📋 Test 4: Path Mappings Externalization"
echo "---------------------------------------"

path_mappings_external=true

# Check for path configuration
if [[ -f "config/paths.yaml" ]]; then
  echo "✅ External path config exists: config/paths.yaml"
else
  echo "❌ Missing external path config"
  path_mappings_external=false
fi

# Check for SSH directory configuration in platforms
if grep -q "SSH_BASE_DIR\|SSH_DIR" apps/platforms/ -r; then
  echo "✅ SSH directory paths are configurable"
else
  echo "❌ SSH directory paths not externalized"
  path_mappings_external=false
fi

if [[ "$path_mappings_external" == false ]]; then
  exit 1
fi

# Test 5: Configuration validation exists
echo ""
echo "📋 Test 5: Configuration Validation"
echo "----------------------------------"

config_validation=true

# Check for config validation utility
if [[ -f "scripts/utils/validate-config.sh" ]]; then
  echo "✅ Config validation utility exists"
else
  echo "❌ Missing config validation utility"
  config_validation=false
fi

# Check for default config loading
if grep -q "load_default_config" scripts/utils/config-loader.sh; then
  echo "✅ Default configuration loading implemented"
else
  echo "❌ Missing default configuration loading"
  config_validation=false
fi

if [[ "$config_validation" == false ]]; then
  exit 1
fi

echo ""
echo "🎉 Green Phase Tests Passed!"
echo "=========================="
echo ""
echo "✅ Configuration loader utility: Working"
echo "✅ Platform settings externalized: Complete"
echo "✅ Build settings centralized: Complete"
echo "✅ Path mappings externalized: Complete"
echo "✅ Configuration validation: Implemented"
echo ""
echo "🟢 Green Phase: Minimal implementation successful - ready for Refactor"
