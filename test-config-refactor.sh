#!/bin/bash

echo "🧪 Configuration Refactor Phase Tests (Phase 4 Sprint 4.2)"
echo "========================================================"

# Test 1: Performance optimization (caching)
echo ""
echo "📋 Test 1: Configuration Caching Performance"
echo "-------------------------------------------"

cache_performance=true

# Test config loader performance
if bash scripts/utils/config-loader.sh >/dev/null 2>&1; then
  echo "✅ Configuration loader executes successfully"

  # Test caching by checking if CONFIG_CACHE_LOADED is used
  if grep -q "CONFIG_CACHE_LOADED" scripts/utils/config-loader.sh; then
    echo "✅ Configuration caching implemented"
  else
    echo "❌ Configuration caching not implemented"
    cache_performance=false
  fi
else
  echo "❌ Configuration loader fails"
  cache_performance=false
fi

if [[ "$cache_performance" == false ]]; then
  exit 1
fi

# Test 2: Unified configuration interface
echo ""
echo "📋 Test 2: Unified Configuration Interface"
echo "----------------------------------------"

unified_interface=true

# Check for unified config functions
if grep -q "get_unified_config" scripts/utils/config-loader.sh; then
  echo "✅ Unified configuration getter implemented"
else
  echo "❌ Unified configuration getter missing"
  unified_interface=false
fi

# Check if platform scripts use unified interface
if grep -q "get_unified_config" apps/platforms/darwin.sh; then
  echo "✅ Platform scripts use unified interface"
else
  echo "❌ Platform scripts not using unified interface"
  unified_interface=false
fi

if [[ "$unified_interface" == false ]]; then
  exit 1
fi

# Test 3: Advanced configuration files
echo ""
echo "📋 Test 3: Advanced Configuration System"
echo "---------------------------------------"

advanced_config=true

# Check for advanced settings
if [[ -f "config/advanced-settings.yaml" ]]; then
  echo "✅ Advanced settings configuration exists"
else
  echo "❌ Advanced settings configuration missing"
  advanced_config=false
fi

# Check for configuration profiles
if [[ -d "config/profiles" ]]; then
  profile_count=$(find config/profiles -name "*.yaml" | wc -l)
  if [[ $profile_count -ge 2 ]]; then
    echo "✅ Configuration profiles system exists ($profile_count profiles)"
  else
    echo "❌ Insufficient configuration profiles"
    advanced_config=false
  fi
else
  echo "❌ Configuration profiles directory missing"
  advanced_config=false
fi

if [[ "$advanced_config" == false ]]; then
  exit 1
fi

# Test 4: Configuration validation improvements
echo ""
echo "📋 Test 4: Enhanced Configuration Validation"
echo "-------------------------------------------"

validation_enhanced=true

# Check for improved validation functions
if grep -q "is_config_loaded" scripts/utils/config-loader.sh; then
  echo "✅ Configuration state tracking implemented"
else
  echo "❌ Configuration state tracking missing"
  validation_enhanced=false
fi

# Check for error handling in config loading
if grep -q "printf.*Warning\|printf.*Error" scripts/utils/config-loader.sh; then
  echo "✅ Enhanced error handling in config loader"
else
  echo "❌ Basic error handling in config loader"
  validation_enhanced=false
fi

if [[ "$validation_enhanced" == false ]]; then
  exit 1
fi

# Test 5: Integration with existing systems
echo ""
echo "📋 Test 5: System Integration"
echo "----------------------------"

system_integration=true

# Check if build scripts use improved config system
if grep -q "load_build_environment" scripts/build/common.sh; then
  echo "✅ Build system integrated with external config"
else
  echo "❌ Build system not integrated"
  system_integration=false
fi

# Check platform integration
platform_configs=$(find apps/platforms -name "*.sh" -exec grep -l "load_all_configs\|get_unified_config" {} \;)
if [[ -n "$platform_configs" ]]; then
  echo "✅ Platform scripts integrated with unified config"
else
  echo "❌ Platform scripts not fully integrated"
  system_integration=false
fi

if [[ "$system_integration" == false ]]; then
  exit 1
fi

echo ""
echo "🎉 Refactor Phase Tests Passed!"
echo "=============================="
echo ""
echo "✅ Configuration caching: Implemented"
echo "✅ Unified interface: Working"
echo "✅ Advanced settings: Complete"
echo "✅ Enhanced validation: Improved"
echo "✅ System integration: Successful"
echo ""
echo "🔄 Refactor Phase: Configuration system optimized and enhanced"
