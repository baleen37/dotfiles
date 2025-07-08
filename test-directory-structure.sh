#!/bin/bash

echo "🧪 Directory Structure Optimization Tests"
echo "========================================"

# Test 1: No duplication in platform lib directories
echo ""
echo "📋 Test 1: Platform Lib Deduplication"
echo "------------------------------------"

# Check that platform-specific lib directories don't have duplicated files
lib_dirs=("apps/aarch64-darwin/lib" "apps/aarch64-linux/lib" "apps/x86_64-darwin/lib" "apps/x86_64-linux/lib")

# Expected result: platform lib directories should either not exist or be minimal
duplicate_count=0
for dir in "${lib_dirs[@]}"; do
  if [[ -d "$dir" ]]; then
    file_count=$(find "$dir" -name "*.sh" | wc -l)
    if [[ $file_count -gt 2 ]]; then  # Allow max 2 platform-specific files
      echo "❌ Platform lib directory $dir has too many files: $file_count"
      duplicate_count=$((duplicate_count + file_count))
    fi
  fi
done

if [[ $duplicate_count -eq 0 ]]; then
  echo "✅ No significant duplication in platform lib directories"
else
  echo "❌ Found $duplicate_count duplicate files across platform lib directories"
  exit 1
fi

# Test 2: Centralized common library exists
echo ""
echo "📋 Test 2: Centralized Common Library"
echo "-----------------------------------"

if [[ -d "scripts/lib" ]]; then
  common_lib_files=$(find "scripts/lib" -name "*.sh" | wc -l)
  if [[ $common_lib_files -gt 5 ]]; then
    echo "✅ Common library directory exists with $common_lib_files files"
  else
    echo "❌ Common library has insufficient files: $common_lib_files"
    exit 1
  fi
else
  echo "❌ Common library directory missing"
  exit 1
fi

# Test 3: Platform-specific overrides structure
echo ""
echo "📋 Test 3: Platform Override Structure"
echo "-----------------------------------"

if [[ -d "scripts/platform" ]]; then
  override_files=$(find "scripts/platform" -name "*-overrides.sh" | wc -l)
  if [[ $override_files -gt 0 ]]; then
    echo "✅ Platform override structure exists with $override_files override files"
  else
    echo "❌ Platform overrides not found"
    exit 1
  fi
else
  echo "❌ Platform override directory missing"
  exit 1
fi

# Test 4: No backup files in optimized structure
echo ""
echo "📋 Test 4: Clean Structure (No Backup Files)"
echo "-------------------------------------------"

backup_files=$(find "apps" -name "*.backup" 2>/dev/null | wc -l)
if [[ $backup_files -eq 0 ]]; then
  echo "✅ No backup files found in optimized structure"
else
  echo "❌ Found $backup_files backup files that should be cleaned up"
  exit 1
fi

# Test 5: Logical module organization
echo ""
echo "📋 Test 5: Logical Module Organization"
echo "------------------------------------"

# Check for clear separation of concerns
modules_exist=0

if [[ -d "modules/shared" ]]; then
  echo "✅ Shared modules directory exists"
  modules_exist=$((modules_exist + 1))
fi

if [[ -d "modules/darwin" ]]; then
  echo "✅ Darwin-specific modules directory exists"
  modules_exist=$((modules_exist + 1))
fi

if [[ -d "modules/nixos" ]]; then
  echo "✅ NixOS-specific modules directory exists"
  modules_exist=$((modules_exist + 1))
fi

if [[ $modules_exist -eq 3 ]]; then
  echo "✅ Logical module organization is in place"
else
  echo "❌ Module organization incomplete: $modules_exist/3 directories found"
  exit 1
fi

echo ""
echo "🎉 All Directory Structure Optimization Tests Completed!"
echo "======================================================="
echo ""
echo "Summary:"
echo "- Platform lib deduplication: ✅"
echo "- Centralized common library: ✅"
echo "- Platform override structure: ✅"
echo "- Clean structure (no backups): ✅"
echo "- Logical module organization: ✅"
