#!/bin/bash

echo "🧪 Configuration Externalization Tests (Phase 4 Sprint 4.2 - Red Phase)"
echo "======================================================================="

# Test 1: Configuration loader utility should exist
echo ""
echo "📋 Test 1: Configuration Loader Utility"
echo "--------------------------------------"

config_loader_exists=false

if [[ -f "scripts/utils/config-loader.sh" ]]; then
  echo "✅ Configuration loader utility exists"
  config_loader_exists=true
else
  echo "❌ Missing configuration loader utility: scripts/utils/config-loader.sh"
fi

# Test 2: Platform configuration should be externalized
echo ""
echo "📋 Test 2: Platform Configuration Externalization"
echo "------------------------------------------------"

platform_config_external=true

# Check for platform configuration file
if [[ ! -f "config/platforms.yaml" ]]; then
  echo "❌ Missing external platform config: config/platforms.yaml"
  platform_config_external=false
fi

# Check that hardcoded values are removed from scripts
hardcoded_platforms=$(grep -r "aarch64-darwin\|x86_64-linux" scripts/build/ --include="*.sh" | grep -v "config" | wc -l)
if [[ $hardcoded_platforms -gt 0 ]]; then
  echo "❌ Found $hardcoded_platforms hardcoded platform references in build scripts"
  platform_config_external=false
fi

if [[ "$platform_config_external" == true ]]; then
  echo "✅ Platform configuration is externalized"
else
  exit 1
fi

# Test 3: Build settings should be centralized and loaded
echo ""
echo "📋 Test 3: Build Settings Centralization"
echo "---------------------------------------"

build_settings_centralized=true

# Check for environment loading function
if ! grep -q "load_build_environment" scripts/build/common.sh 2>/dev/null; then
  echo "❌ Missing load_build_environment function in common.sh"
  build_settings_centralized=false
fi

# Check for timeout configuration loading
if ! grep -q "BUILD_TIMEOUT" scripts/build/common.sh 2>/dev/null; then
  echo "❌ Build timeout not configurable from external config"
  build_settings_centralized=false
fi

# Check for parallel jobs configuration
if ! grep -q "PARALLEL_JOBS" scripts/build/common.sh 2>/dev/null; then
  echo "❌ Parallel jobs not configurable from external config"
  build_settings_centralized=false
fi

if [[ "$build_settings_centralized" == true ]]; then
  echo "✅ Build settings are centralized and configurable"
else
  exit 1
fi

# Test 4: Path mappings should be externalized
echo ""
echo "📋 Test 4: Path Mappings Externalization"
echo "---------------------------------------"

path_mappings_external=true

# Check for path configuration
if [[ ! -f "config/paths.yaml" ]]; then
  echo "❌ Missing external path config: config/paths.yaml"
  path_mappings_external=false
fi

# Check for SSH directory configuration
if ! grep -q "SSH_BASE_DIR" apps/platforms/ -r 2>/dev/null; then
  echo "❌ SSH directory paths not externalized"
  path_mappings_external=false
fi

if [[ "$path_mappings_external" == true ]]; then
  echo "✅ Path mappings are externalized"
else
  exit 1
fi

# Test 5: Default values and validation
echo ""
echo "📋 Test 5: Configuration Validation"
echo "----------------------------------"

config_validation=true

# Check for config validation utility
if [[ ! -f "scripts/utils/validate-config.sh" ]]; then
  echo "❌ Missing config validation utility"
  config_validation=false
fi

# Check for default config loading
if ! grep -q "load_default_config" scripts/utils/config-loader.sh 2>/dev/null; then
  echo "❌ Missing default configuration loading"
  config_validation=false
fi

if [[ "$config_validation" == true ]]; then
  echo "✅ Configuration validation is implemented"
else
  exit 1
fi

echo ""
echo "❌ Configuration Externalization Tests Failed (Expected for Red Phase)"
echo "==================================================================="
echo ""
echo "Summary of missing components:"
echo "- Configuration loader utility"
echo "- Externalized platform settings"
echo "- Centralized build environment loading"
echo "- External path mappings"
echo "- Configuration validation system"
echo ""
echo "🔴 Red Phase: Tests properly failing - ready for Green Phase implementation"
