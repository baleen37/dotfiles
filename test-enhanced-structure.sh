#!/bin/bash

echo "🧪 Enhanced Directory Structure Tests (Phase 4 Sprint 4.1)"
echo "=========================================================="

# Test 1: Apps directory should have common/platforms/targets structure
echo ""
echo "📋 Test 1: Apps Directory Enhanced Structure"
echo "-------------------------------------------"

apps_structure_optimal=true

# Check for proposed structure
if [[ ! -d "apps/common" ]]; then
  echo "❌ Missing apps/common directory"
  apps_structure_optimal=false
fi

if [[ ! -d "apps/platforms" ]]; then
  echo "❌ Missing apps/platforms directory"
  apps_structure_optimal=false
fi

if [[ ! -d "apps/targets" ]]; then
  echo "❌ Missing apps/targets directory"
  apps_structure_optimal=false
fi

# Check if old structure still exists (should be migrated)
old_structure_exists=false
for arch in aarch64-darwin aarch64-linux x86_64-darwin x86_64-linux; do
  if [[ -d "apps/$arch" ]]; then
    echo "⚠️  Legacy structure still exists: apps/$arch"
    old_structure_exists=true
  fi
done

if [[ "$apps_structure_optimal" == true && "$old_structure_exists" == false ]]; then
  echo "✅ Apps directory has optimal structure"
else
  echo "❌ Apps directory structure needs improvement"
  exit 1
fi

# Test 2: Scripts directory should have build/utils separation
echo ""
echo "📋 Test 2: Scripts Directory Enhanced Structure"
echo "---------------------------------------------"

scripts_structure_optimal=true

# Check for build directory
if [[ ! -d "scripts/build" ]]; then
  echo "❌ Missing scripts/build directory"
  scripts_structure_optimal=false
fi

# Check for utils directory
if [[ ! -d "scripts/utils" ]]; then
  echo "❌ Missing scripts/utils directory"
  scripts_structure_optimal=false
fi

# Check for build-related scripts in build directory
if [[ -d "scripts/build" ]]; then
  build_scripts=$(find "scripts/build" -name "*.sh" | wc -l)
  if [[ $build_scripts -lt 2 ]]; then
    echo "❌ Insufficient build scripts in scripts/build: $build_scripts"
    scripts_structure_optimal=false
  fi
fi

# Check for utility scripts in utils directory
if [[ -d "scripts/utils" ]]; then
  util_scripts=$(find "scripts/utils" -name "*.sh" | wc -l)
  if [[ $util_scripts -lt 2 ]]; then
    echo "❌ Insufficient utility scripts in scripts/utils: $util_scripts"
    scripts_structure_optimal=false
  fi
fi

if [[ "$scripts_structure_optimal" == true ]]; then
  echo "✅ Scripts directory has optimal structure"
else
  echo "❌ Scripts directory structure needs improvement"
  exit 1
fi

# Test 3: Build scripts should be properly separated
echo ""
echo "📋 Test 3: Build Scripts Separation"
echo "-----------------------------------"

build_separation_optimal=true

# Check for common build logic
if [[ ! -f "scripts/build/common.sh" ]]; then
  echo "❌ Missing common build logic: scripts/build/common.sh"
  build_separation_optimal=false
fi

# Check for platform-specific build scripts
if [[ ! -f "scripts/build/darwin.sh" ]]; then
  echo "❌ Missing Darwin build script: scripts/build/darwin.sh"
  build_separation_optimal=false
fi

if [[ ! -f "scripts/build/linux.sh" ]]; then
  echo "❌ Missing Linux build script: scripts/build/linux.sh"
  build_separation_optimal=false
fi

if [[ "$build_separation_optimal" == true ]]; then
  echo "✅ Build scripts are properly separated"
else
  echo "❌ Build scripts need proper separation"
  exit 1
fi

# Test 4: Configuration externalization
echo ""
echo "📋 Test 4: Configuration Externalization"
echo "---------------------------------------"

config_externalization=true

# Check for build settings configuration
if [[ ! -f "config/build-settings.yaml" ]]; then
  echo "❌ Missing build configuration: config/build-settings.yaml"
  config_externalization=false
fi

# Check for directory mappings configuration
if [[ ! -f "config/directory-mappings.yaml" ]]; then
  echo "❌ Missing directory mappings: config/directory-mappings.yaml"
  config_externalization=false
fi

if [[ "$config_externalization" == true ]]; then
  echo "✅ Configuration is properly externalized"
else
  echo "❌ Configuration needs externalization"
  exit 1
fi

# Test 5: Module structure optimization
echo ""
echo "📋 Test 5: Module Structure Optimization"
echo "---------------------------------------"

module_structure_optimal=true

# Check for platform modules under modules/platform
if [[ ! -d "modules/platform/darwin" ]]; then
  echo "❌ Missing modules/platform/darwin directory"
  module_structure_optimal=false
fi

if [[ ! -d "modules/platform/nixos" ]]; then
  echo "❌ Missing modules/platform/nixos directory"
  module_structure_optimal=false
fi

# Check that old structure is moved
if [[ -d "modules/darwin" && -d "modules/platform/darwin" ]]; then
  echo "⚠️  Duplicate module structure detected"
  module_structure_optimal=false
fi

if [[ "$module_structure_optimal" == true ]]; then
  echo "✅ Module structure is optimized"
else
  echo "❌ Module structure needs optimization"
  exit 1
fi

echo ""
echo "🎉 All Enhanced Directory Structure Tests Completed!"
echo "====================================================="
echo ""
echo "Summary:"
echo "- Apps directory enhanced structure: ✅"
echo "- Scripts directory enhanced structure: ✅"
echo "- Build scripts separation: ✅"
echo "- Configuration externalization: ✅"
echo "- Module structure optimization: ✅"
