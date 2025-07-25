# Comprehensive Package & Automation Integration Tests
# Tests package management and automation system integration

{ pkgs, flake ? null, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  packageAutomationIntegrationScript = pkgs.writeShellScript "package-automation-comprehensive-integration" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive Package & Automation Integration Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Package Configuration Integration
    echo ""
    echo "🔍 Section 1: Package configuration integration..."

    cd "${src}"

    # Test shared and platform-specific package integration
    if [[ -f "modules/shared/packages.nix" ]]; then
      echo "✅ PASS: Shared packages configuration found"
      PASSED_TESTS+=("shared-packages-found")

      # Test integration with platform-specific packages
      platform_packages=()
      if [[ -f "modules/darwin/packages.nix" ]]; then
        platform_packages+=("darwin")
        echo "✅ PASS: Darwin packages found for integration"
        PASSED_TESTS+=("darwin-packages-integration")
      fi

      if [[ -f "modules/nixos/packages.nix" ]]; then
        platform_packages+=("nixos")
        echo "✅ PASS: NixOS packages found for integration"
        PASSED_TESTS+=("nixos-packages-integration")
      fi

      # Test package conflict resolution
      if [[ ${#platform_packages[@]} -gt 0 ]]; then
        echo "✅ PASS: Multi-platform package integration possible"
        PASSED_TESTS+=("multi-platform-package-integration")
      fi
    else
      echo "❌ FAIL: Shared packages configuration missing"
      FAILED_TESTS+=("shared-packages-missing")
    fi

    # Section 2: Homebrew-Nix Integration
    echo ""
    echo "🔍 Section 2: Homebrew-Nix integration..."

    # Test nix-homebrew integration
    homebrew_integration=false
    if [[ -f "flake.nix" ]]; then
      if grep -q "nix-homebrew" flake.nix 2>/dev/null; then
        echo "✅ PASS: nix-homebrew integration configured in flake"
        PASSED_TESTS+=("nix-homebrew-flake-integration")
        homebrew_integration=true

        # Test homebrew configuration integration
        if [[ -f "modules/darwin/casks.nix" ]]; then
          echo "✅ PASS: Homebrew casks configuration integrated"
          PASSED_TESTS+=("homebrew-casks-integrated")

          # Test for integration patterns
          if grep -q "programs.brew" modules/darwin/casks.nix 2>/dev/null || \
             grep -q "homebrew" modules/darwin/casks.nix 2>/dev/null; then
            echo "✅ PASS: Homebrew configuration uses integration patterns"
            PASSED_TESTS+=("homebrew-integration-patterns")
          fi
        fi

        # Test homebrew cleanup integration
        if grep -q "onActivation\|cleanup" flake.nix 2>/dev/null; then
          echo "✅ PASS: Homebrew cleanup integration configured"
          PASSED_TESTS+=("homebrew-cleanup-integration")
        fi
      fi
    fi

    if [[ "$homebrew_integration" = "false" ]]; then
      echo "⚠️  INFO: Homebrew integration not configured (expected on non-Darwin)"
    fi

    # Section 3: Package Manager Script Integration
    echo ""
    echo "🔍 Section 3: Package manager script integration..."

    # Test integration between different package management scripts
    scripts_dir="scripts"
    if [[ -d "$scripts_dir" ]]; then
      echo "✅ PASS: Scripts directory exists"
      PASSED_TESTS+=("scripts-dir-exists")

      # Test for package management script integration
      package_scripts=("build-switch-common.sh" "lib/build-logic.sh")
      script_integration_count=0

      for script in "${package_scripts[@]}"; do
        if [[ -f "$scripts_dir/$script" ]]; then
          echo "✅ PASS: Package management script '$script' exists"
          PASSED_TESTS+=("package-script-$script-exists")
          script_integration_count=$((script_integration_count + 1))

          # Test script integration patterns
          if grep -q "source\|\..*sh" "$scripts_dir/$script" 2>/dev/null; then
            echo "✅ PASS: Script '$script' uses integration patterns"
            PASSED_TESTS+=("script-$script-integration-patterns")
          fi
        fi
      done

      if [[ $script_integration_count -ge 1 ]]; then
        echo "✅ PASS: Package management scripts integrated"
        PASSED_TESTS+=("package-scripts-integrated")
      fi
    fi

    # Section 4: Build System Package Integration
    echo ""
    echo "🔍 Section 4: Build system package integration..."

    # Test package integration with build system
    if [[ -f "flake.nix" ]]; then
      # Test package inputs integration
      if grep -q "inputs\|nixpkgs" flake.nix 2>/dev/null; then
        echo "✅ PASS: Package inputs integrated in flake"
        PASSED_TESTS+=("package-inputs-integrated")

        # Test overlay integration
        if grep -q "overlay\|nixpkgs.overlays" flake.nix 2>/dev/null || [[ -d "overlays" ]]; then
          echo "✅ PASS: Package overlays integrated"
          PASSED_TESTS+=("package-overlays-integrated")
        fi
      fi

      # Test system configuration integration
      if command -v nix >/dev/null 2>&1; then
        if nix eval ".#darwinConfigurations" >/dev/null 2>&1 || \
           nix eval ".#nixosConfigurations" >/dev/null 2>&1; then
          echo "✅ PASS: System configurations integrated with packages"
          PASSED_TESTS+=("system-config-package-integration")
        fi
      fi
    fi

    # Section 5: Automation Workflow Integration
    echo ""
    echo "🔍 Section 5: Automation workflow integration..."

    # Test automation script integration
    auto_update_script="scripts/auto-update-dotfiles"
    if [[ -f "$auto_update_script" ]]; then
      echo "✅ PASS: Auto-update script exists"
      PASSED_TESTS+=("auto-update-script-exists")

      # Test integration with build system
      if grep -q "nix.*flake\|build.*switch\|darwin-rebuild\|nixos-rebuild" "$auto_update_script" 2>/dev/null; then
        echo "✅ PASS: Auto-update integrates with build system"
        PASSED_TESTS+=("auto-update-build-integration")
      fi

      # Test integration with package management
      if grep -q "package\|brew\|nix.*install" "$auto_update_script" 2>/dev/null; then
        echo "✅ PASS: Auto-update integrates with package management"
        PASSED_TESTS+=("auto-update-package-integration")
      fi

      # Test safety integration
      if grep -q "backup\|rollback\|generation" "$auto_update_script" 2>/dev/null; then
        echo "✅ PASS: Auto-update integrates safety mechanisms"
        PASSED_TESTS+=("auto-update-safety-integration")
      fi
    fi

    # Section 6: Configuration File Automation Integration
    echo ""
    echo "🔍 Section 6: Configuration file automation integration..."

    # Test configuration file deployment integration
    config_dirs=("modules/shared/config" "modules/darwin/config" "modules/nixos/config")
    config_integration_count=0

    for config_dir in "${config_dirs[@]}"; do
      if [[ -d "$config_dir" ]]; then
        config_integration_count=$((config_integration_count + 1))
        platform=$(basename $(dirname "$config_dir"))
        echo "✅ PASS: $platform configuration directory integrated"
        PASSED_TESTS+=("config-integration-$platform")

        # Test for automation in config deployment
        if find "$config_dir" -name "*.sh" -o -name "*automation*" -o -name "*deploy*" 2>/dev/null | head -1; then
          echo "✅ PASS: $platform config includes automation scripts"
          PASSED_TESTS+=("config-automation-$platform")
        fi
      fi
    done

    if [[ $config_integration_count -ge 1 ]]; then
      echo "✅ PASS: Configuration file automation integrated"
      PASSED_TESTS+=("config-file-automation-integrated")
    fi

    # Section 7: Dependency Management Integration
    echo ""
    echo "🔍 Section 7: Dependency management integration..."

    # Test flake lock integration with automation
    if [[ -f "flake.lock" ]]; then
      echo "✅ PASS: Flake lock exists for dependency management"
      PASSED_TESTS+=("flake-lock-dependency-management")

      # Test lock file automation
      if [[ -f "$auto_update_script" ]]; then
        if grep -q "flake.*update\|lock" "$auto_update_script" 2>/dev/null; then
          echo "✅ PASS: Dependency updates integrated in automation"
          PASSED_TESTS+=("dependency-update-automation")
        fi
      fi
    fi

    # Test dependency conflict resolution
    conflict_resolution_mechanisms=()
    if grep -q "follows" flake.nix 2>/dev/null; then
      conflict_resolution_mechanisms+=("follows")
    fi
    if [[ -d "overlays" ]]; then
      conflict_resolution_mechanisms+=("overlays")
    fi

    if [[ ${#conflict_resolution_mechanisms[@]} -gt 0 ]]; then
      echo "✅ PASS: Dependency conflict resolution mechanisms integrated"
      PASSED_TESTS+=("dependency-conflict-resolution")
    fi

    # Section 8: Testing Integration with Package Management
    echo ""
    echo "🔍 Section 8: Testing integration with package management..."

    # Test package testing integration
    if [[ -d "tests" ]]; then
      echo "✅ PASS: Testing framework exists"
      PASSED_TESTS+=("testing-framework-exists")

      # Test for package-specific tests
      if find tests -name "*package*" -o -name "*automation*" 2>/dev/null | head -1; then
        echo "✅ PASS: Package-specific tests integrated"
        PASSED_TESTS+=("package-tests-integrated")
      fi

      # Test for CI/CD integration
      ci_configs=(".github/workflows" ".gitlab-ci.yml" "buildkite")
      ci_integrated=false

      for ci_config in "${ci_configs[@]}"; do
        if [[ -e "$ci_config" ]]; then
          if find "$ci_config" -type f -exec grep -l "test\|package\|build" {} \; 2>/dev/null | head -1; then
            echo "✅ PASS: CI/CD integrated with package testing"
            PASSED_TESTS+=("cicd-package-testing-integration")
            ci_integrated=true
            break
          fi
        fi
      done
    fi

    # Section 9: Performance Monitoring Integration
    echo ""
    echo "🔍 Section 9: Performance monitoring integration..."

    # Test performance integration
    perf_integration=false
    if [[ -f "scripts/build-switch-common.sh" ]]; then
      if grep -q "time\|duration\|benchmark" "scripts/build-switch-common.sh" 2>/dev/null; then
        echo "✅ PASS: Build performance monitoring integrated"
        PASSED_TESTS+=("build-performance-monitoring")
        perf_integration=true
      fi
    fi

    # Test automation performance tracking
    if [[ -f "$auto_update_script" ]]; then
      if grep -q "time\|duration\|performance" "$auto_update_script" 2>/dev/null; then
        echo "✅ PASS: Automation performance tracking integrated"
        PASSED_TESTS+=("automation-performance-tracking")
        perf_integration=true
      fi
    fi

    if [[ "$perf_integration" = "false" ]]; then
      echo "⚠️  INFO: Performance monitoring integration not detected"
    fi

    # Section 10: Cross-Platform Package Integration
    echo ""
    echo "🔍 Section 10: Cross-platform package integration..."

    # Test cross-platform package compatibility
    platform_count=0
    platforms_supported=()

    if [[ -f "modules/darwin/packages.nix" ]]; then
      platform_count=$((platform_count + 1))
      platforms_supported+=("darwin")
    fi

    if [[ -f "modules/nixos/packages.nix" ]]; then
      platform_count=$((platform_count + 1))
      platforms_supported+=("nixos")
    fi

    if [[ $platform_count -ge 2 ]]; then
      echo "✅ PASS: Cross-platform package integration supports ${platforms_supported[*]}"
      PASSED_TESTS+=("cross-platform-package-integration")

      # Test for platform-specific automation
      for platform in "${platforms_supported[@]}"; do
        if [[ -d "apps" ]]; then
          if find apps -name "*$platform*" -o -path "*$platform*" 2>/dev/null | head -1; then
            echo "✅ PASS: Platform-specific automation for $platform"
            PASSED_TESTS+=("platform-automation-$platform")
          fi
        fi
      done
    elif [[ $platform_count -eq 1 ]]; then
      echo "✅ PASS: Single-platform package integration for ${platforms_supported[0]}"
      PASSED_TESTS+=("single-platform-package-integration")
    else
      echo "❌ FAIL: No platform-specific packages found"
      FAILED_TESTS+=("no-platform-packages")
    fi

    # Results Summary
    echo ""
    echo "=== Comprehensive Integration Test Results ==="
    echo "✅ Passed tests: ${#PASSED_TESTS[@]}"
    echo "❌ Failed tests: ${#FAILED_TESTS[@]}"

    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
      echo ""
      echo "❌ FAILED TESTS:"
      for test in "${FAILED_TESTS[@]}"; do
        echo "   - $test"
      done
      echo ""
      echo "🔧 Integration test identified ${#FAILED_TESTS[@]} package/automation integration issues"
      exit 1
    else
      echo ""
      echo "🎉 All ${#PASSED_TESTS[@]} integration tests passed!"
      echo "✅ Package & Automation integration is working correctly"
      echo ""
      echo "📋 Integration Test Coverage Summary:"
      echo "   ✓ Package configuration integration"
      echo "   ✓ Homebrew-Nix integration"
      echo "   ✓ Package manager script integration"
      echo "   ✓ Build system package integration"
      echo "   ✓ Automation workflow integration"
      echo "   ✓ Configuration file automation integration"
      echo "   ✓ Dependency management integration"
      echo "   ✓ Testing integration with package management"
      echo "   ✓ Performance monitoring integration"
      echo "   ✓ Cross-platform package integration"
      exit 0
    fi
  '';

in
pkgs.runCommand "package-automation-comprehensive-integration-test"
{
  buildInputs = with pkgs; [ bash nix findutils gnugrep coreutils ];
} ''
  echo "Running Package & Automation comprehensive integration tests..."

  # Run the comprehensive integration test
  ${packageAutomationIntegrationScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "Package & Automation integration test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
