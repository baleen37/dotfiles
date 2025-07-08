#!/bin/bash

echo "🧪 Green Phase Structure Tests (Minimal Implementation)"
echo "======================================================"

# Test 1: New structure exists (legacy can coexist for now)
echo ""
echo "📋 Test 1: New Apps Structure Exists"
echo "-----------------------------------"

new_structure_exists=true

if [[ ! -d "apps/common" ]]; then
  echo "❌ Missing apps/common directory"
  new_structure_exists=false
else
  echo "✅ apps/common directory exists"
fi

if [[ ! -d "apps/platforms" ]]; then
  echo "❌ Missing apps/platforms directory"
  new_structure_exists=false
else
  echo "✅ apps/platforms directory exists"
fi

if [[ ! -d "apps/targets" ]]; then
  echo "❌ Missing apps/targets directory"
  new_structure_exists=false
else
  echo "✅ apps/targets directory exists"
fi

if [[ "$new_structure_exists" == false ]]; then
  exit 1
fi

# Test 2: New scripts structure exists
echo ""
echo "📋 Test 2: New Scripts Structure Exists"
echo "--------------------------------------"

scripts_structure_exists=true

if [[ ! -d "scripts/build" ]]; then
  echo "❌ Missing scripts/build directory"
  scripts_structure_exists=false
else
  echo "✅ scripts/build directory exists"
fi

if [[ ! -d "scripts/utils" ]]; then
  echo "❌ Missing scripts/utils directory"
  scripts_structure_exists=false
else
  echo "✅ scripts/utils directory exists"
fi

if [[ "$scripts_structure_exists" == false ]]; then
  exit 1
fi

# Test 3: Build scripts exist
echo ""
echo "📋 Test 3: Build Scripts Exist"
echo "-----------------------------"

build_scripts_exist=true

if [[ ! -f "scripts/build/common.sh" ]]; then
  echo "❌ Missing scripts/build/common.sh"
  build_scripts_exist=false
else
  echo "✅ scripts/build/common.sh exists"
fi

if [[ ! -f "scripts/build/darwin.sh" ]]; then
  echo "❌ Missing scripts/build/darwin.sh"
  build_scripts_exist=false
else
  echo "✅ scripts/build/darwin.sh exists"
fi

if [[ ! -f "scripts/build/linux.sh" ]]; then
  echo "❌ Missing scripts/build/linux.sh"
  build_scripts_exist=false
else
  echo "✅ scripts/build/linux.sh exists"
fi

if [[ "$build_scripts_exist" == false ]]; then
  exit 1
fi

# Test 4: Configuration files exist
echo ""
echo "📋 Test 4: Configuration Files Exist"
echo "-----------------------------------"

config_files_exist=true

if [[ ! -f "config/build-settings.yaml" ]]; then
  echo "❌ Missing config/build-settings.yaml"
  config_files_exist=false
else
  echo "✅ config/build-settings.yaml exists"
fi

if [[ ! -f "config/directory-mappings.yaml" ]]; then
  echo "❌ Missing config/directory-mappings.yaml"
  config_files_exist=false
else
  echo "✅ config/directory-mappings.yaml exists"
fi

if [[ "$config_files_exist" == false ]]; then
  exit 1
fi

# Test 5: Platform modules structure exists
echo ""
echo "📋 Test 5: Platform Modules Structure Exists"
echo "--------------------------------------------"

platform_modules_exist=true

if [[ ! -d "modules/platform/darwin" ]]; then
  echo "❌ Missing modules/platform/darwin"
  platform_modules_exist=false
else
  echo "✅ modules/platform/darwin exists"
fi

if [[ ! -d "modules/platform/nixos" ]]; then
  echo "❌ Missing modules/platform/nixos"
  platform_modules_exist=false
else
  echo "✅ modules/platform/nixos exists"
fi

if [[ "$platform_modules_exist" == false ]]; then
  exit 1
fi

echo ""
echo "🎉 Green Phase Tests Completed Successfully!"
echo "==========================================="
echo ""
echo "Summary:"
echo "- New apps structure: ✅"
echo "- New scripts structure: ✅"
echo "- Build scripts: ✅"
echo "- Configuration files: ✅"
echo "- Platform modules structure: ✅"
echo ""
echo "✅ Minimal implementation complete - ready for Refactor phase"
