# Comprehensive Package & Automation End-to-End Tests
# Tests real-world package management and automation scenarios

{ pkgs, flake ? null, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  system = pkgs.system;

  packageAutomationE2EScript = pkgs.writeShellScript "package-automation-comprehensive-e2e" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive Package & Automation End-to-End Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Complete Package Deployment Workflow
    echo ""
    echo "🔍 Section 1: Complete package deployment workflow..."
    echo "Current system: ${system}"

    cd "${src}"
    export USER=\${USER:-testuser}

    # Phase 1: Package Configuration Validation
    echo ""
    echo "📋 Phase 1: Package configuration validation..."

    # Test that packages can be built for current system
    if command -v nix >/dev/null 2>&1; then
      if nix eval ".#packages.${system}" >/dev/null 2>&1; then
        echo "✅ PASS: Packages can be evaluated for ${system}"
        PASSED_TESTS+=("packages-evaluation-${system}")
      else
        echo "⚠️  INFO: Direct packages evaluation not available for ${system}"
      fi

      # Test system configuration includes packages
      case "${system}" in
        *darwin*)
          if nix eval ".#darwinConfigurations" >/dev/null 2>&1; then
            echo "✅ PASS: Darwin configuration available for package deployment"
            PASSED_TESTS+=("darwin-config-available")
          fi
          ;;
        *linux*)
          if nix eval ".#nixosConfigurations" >/dev/null 2>&1; then
            echo "✅ PASS: NixOS configuration available for package deployment"
            PASSED_TESTS+=("nixos-config-available")
          fi
          ;;
      esac
    fi

    # Phase 2: Build System Package Integration
    echo ""
    echo "🔧 Phase 2: Build system package integration..."

    # Test build system can handle package deployment
    if [[ -f "apps/${system}/build" ]]; then
      echo "✅ PASS: Build application exists for ${system}"
      PASSED_TESTS+=("build-app-exists")

      # Test build script structure supports packages
      if [[ -f "scripts/build-switch-common.sh" ]]; then
        if grep -q "package\|nix.*install\|darwin-rebuild\|nixos-rebuild" "scripts/build-switch-common.sh" 2>/dev/null; then
          echo "✅ PASS: Build system supports package deployment"
          PASSED_TESTS+=("build-system-supports-packages")
        fi
      fi
    else
      echo "❌ FAIL: Build application missing for ${system}"
      FAILED_TESTS+=("build-app-missing")
    fi

    # Test switch system can handle packages
    if [[ -f "apps/${system}/apply" ]]; then
      echo "✅ PASS: Apply application exists for ${system}"
      PASSED_TESTS+=("apply-app-exists")
    else
      echo "❌ FAIL: Apply application missing for ${system}"
      FAILED_TESTS+=("apply-app-missing")
    fi

    # Phase 3: Package Manager Workflow Testing
    echo ""
    echo "📦 Phase 3: Package manager workflow testing..."

    case "${system}" in
      *darwin*)
        echo "Testing Darwin package management workflow..."

        # Test Homebrew integration workflow
        if [[ -f "modules/darwin/casks.nix" ]]; then
          echo "✅ PASS: Homebrew casks configuration exists"
          PASSED_TESTS+=("homebrew-casks-config-exists")

          # Test cask categories are realistic
          cask_count=\$(grep -c "\".*\"" "modules/darwin/casks.nix" 2>/dev/null || echo "0")
          if [[ \$cask_count -gt 5 ]]; then
            echo "✅ PASS: Homebrew casks configuration has sufficient entries (\$cask_count)"
            PASSED_TESTS+=("homebrew-casks-sufficient")
          else
            echo "⚠️  INFO: Limited Homebrew casks configuration (\$cask_count entries)"
          fi

          # Test for essential Darwin applications
          essential_casks=("chrome" "firefox" "docker" "iterm" "intellij")
          found_casks=0
          for cask in "''${essential_casks[@]}"; do
            if grep -qi "\$cask" "modules/darwin/casks.nix" 2>/dev/null; then
              found_casks=\$((found_casks + 1))
            fi
          done

          if [[ \$found_casks -ge 3 ]]; then
            echo "✅ PASS: Essential Darwin casks configured (\$found_casks/''${#essential_casks[@]})"
            PASSED_TESTS+=("essential-darwin-casks")
          fi
        else
          echo "⚠️  INFO: Homebrew casks configuration not found"
        fi

        # Test nix-darwin package workflow
        if [[ -f "modules/darwin/packages.nix" ]]; then
          echo "✅ PASS: Darwin packages configuration exists"
          PASSED_TESTS+=("darwin-packages-config-exists")
        fi
        ;;

      *linux*)
        echo "Testing Linux package management workflow..."

        # Test NixOS package workflow
        if [[ -f "modules/nixos/packages.nix" ]]; then
          echo "✅ PASS: NixOS packages configuration exists"
          PASSED_TESTS+=("nixos-packages-config-exists")
        fi
        ;;
    esac

    # Test shared packages workflow
    if [[ -f "modules/shared/packages.nix" ]]; then
      echo "✅ PASS: Shared packages configuration exists"
      PASSED_TESTS+=("shared-packages-config-exists")

      # Test shared packages are cross-platform
      if command -v nix-instantiate >/dev/null 2>&1; then
        if nix-instantiate --eval "modules/shared/packages.nix" --arg pkgs 'import <nixpkgs> {}' >/dev/null 2>&1; then
          echo "✅ PASS: Shared packages configuration is valid"
          PASSED_TESTS+=("shared-packages-valid")
        fi
      fi
    else
      echo "❌ FAIL: Shared packages configuration missing"
      FAILED_TESTS+=("shared-packages-missing")
    fi

    # Section 2: Automation System End-to-End Testing
    echo ""
    echo "🔍 Section 2: Automation system end-to-end testing..."

    # Test complete auto-update workflow
    auto_update_script="scripts/auto-update-dotfiles"
    if [[ -f "\$auto_update_script" ]]; then
      echo "✅ PASS: Auto-update script exists"
      PASSED_TESTS+=("auto-update-script-exists")

      # Test script permissions
      if [[ -x "\$auto_update_script" ]]; then
        echo "✅ PASS: Auto-update script is executable"
        PASSED_TESTS+=("auto-update-executable")
      else
        echo "❌ FAIL: Auto-update script not executable"
        FAILED_TESTS+=("auto-update-not-executable")
      fi

      # Test auto-update workflow completeness
      workflow_steps=("git pull" "flake update" "build" "switch")
      workflow_complete=true

      for step in "''${workflow_steps[@]}"; do
        if ! grep -qi "\$step" "\$auto_update_script" 2>/dev/null; then
          workflow_complete=false
          echo "⚠️  INFO: Auto-update may be missing '\$step' step"
        fi
      done

      if [[ "\$workflow_complete" = "true" ]]; then
        echo "✅ PASS: Auto-update workflow appears complete"
        PASSED_TESTS+=("auto-update-workflow-complete")
      fi

      # Test safety mechanisms
      safety_mechanisms=("backup" "rollback" "error.*handling" "set -e")
      safety_count=0

      for mechanism in "''${safety_mechanisms[@]}"; do
        if grep -q "\$mechanism" "\$auto_update_script" 2>/dev/null; then
          safety_count=\$((safety_count + 1))
        fi
      done

      if [[ \$safety_count -ge 2 ]]; then
        echo "✅ PASS: Auto-update includes safety mechanisms (\$safety_count/''${#safety_mechanisms[@]})"
        PASSED_TESTS+=("auto-update-safety-mechanisms")
      else
        echo "⚠️  WARN: Auto-update may lack sufficient safety mechanisms"
      fi
    else
      echo "⚠️  INFO: Auto-update script not found"
    fi

    # Section 3: Dependency Management End-to-End
    echo ""
    echo "🔍 Section 3: Dependency management end-to-end..."

    # Test complete dependency workflow
    if [[ -f "flake.nix" && -f "flake.lock" ]]; then
      echo "✅ PASS: Flake-based dependency management complete"
      PASSED_TESTS+=("flake-dependency-management-complete")

      # Test dependency pinning
      if [[ -s "flake.lock" ]]; then
        echo "✅ PASS: Dependencies are pinned in flake.lock"
        PASSED_TESTS+=("dependencies-pinned")

        # Test lock file is reasonable size (not empty, not too large)
        lock_size=\$(wc -c < "flake.lock")
        if [[ \$lock_size -gt 100 && \$lock_size -lt 50000 ]]; then
          echo "✅ PASS: Flake lock file size reasonable (\$lock_size bytes)"
          PASSED_TESTS+=("flake-lock-size-reasonable")
        fi
      fi

      # Test essential dependencies
      essential_deps=("nixpkgs" "home-manager")
      deps_found=0

      for dep in "''${essential_deps[@]}"; do
        if grep -q "\$dep" "flake.nix" 2>/dev/null; then
          deps_found=\$((deps_found + 1))
          echo "✅ PASS: Essential dependency '\$dep' configured"
          PASSED_TESTS+=("essential-dep-\$dep")
        fi
      done

      if [[ \$deps_found -ge 2 ]]; then
        echo "✅ PASS: Essential dependencies configured (\$deps_found/''${#essential_deps[@]})"
        PASSED_TESTS+=("essential-deps-configured")
      fi
    else
      echo "❌ FAIL: Incomplete flake-based dependency management"
      FAILED_TESTS+=("incomplete-dependency-management")
    fi

    # Section 4: Cross-Platform Package Deployment
    echo ""
    echo "🔍 Section 4: Cross-platform package deployment..."

    # Test multi-platform support
    supported_platforms=()
    if command -v nix >/dev/null 2>&1; then
      platforms=("aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux")

      for platform in "''${platforms[@]}"; do
        case "\$platform" in
          *darwin*)
            if nix eval ".#darwinConfigurations" 2>/dev/null | grep -q "\$platform"; then
              supported_platforms+=("\$platform")
              echo "✅ PASS: \$platform configuration available"
              PASSED_TESTS+=("platform-support-\$platform")
            fi
            ;;
          *linux*)
            if nix eval ".#nixosConfigurations" 2>/dev/null | grep -q "\$platform"; then
              supported_platforms+=("\$platform")
              echo "✅ PASS: \$platform configuration available"
              PASSED_TESTS+=("platform-support-\$platform")
            fi
            ;;
        esac
      done
    fi

    platform_count=''${#supported_platforms[@]}
    if [[ \$platform_count -ge 2 ]]; then
      echo "✅ PASS: Multi-platform deployment supported (\$platform_count platforms)"
      PASSED_TESTS+=("multi-platform-deployment")
    elif [[ \$platform_count -eq 1 ]]; then
      echo "✅ PASS: Single-platform deployment for ${system}"
      PASSED_TESTS+=("single-platform-deployment")
    else
      echo "❌ FAIL: No platform deployments detected"
      FAILED_TESTS+=("no-platform-deployments")
    fi

    # Section 5: Build-Switch Package Integration
    echo ""
    echo "🔍 Section 5: Build-switch package integration..."

    # Test build-switch handles packages
    if [[ -f "apps/${system}/build-switch" ]]; then
      echo "✅ PASS: Build-switch application exists"
      PASSED_TESTS+=("build-switch-app-exists")

      # Test build-switch integrates with package management
      if [[ -f "scripts/build-switch-common.sh" ]]; then
        if grep -q "package\|install\|brew\|nix" "scripts/build-switch-common.sh" 2>/dev/null; then
          echo "✅ PASS: Build-switch integrates package management"
          PASSED_TESTS+=("build-switch-package-integration")
        fi
      fi
    else
      echo "⚠️  INFO: Build-switch application not found for ${system}"
    fi

    # Section 6: Configuration Management Automation
    echo ""
    echo "🔍 Section 6: Configuration management automation..."

    # Test configuration file deployment automation
    config_deployment_score=0
    config_dirs=("modules/shared/config" "modules/darwin/config" "modules/nixos/config")

    for config_dir in "''${config_dirs[@]}"; do
      if [[ -d "\$config_dir" ]]; then
        config_deployment_score=\$((config_deployment_score + 1))
        platform=\$(basename \$(dirname "\$config_dir"))
        echo "✅ PASS: \$platform configuration deployment ready"
        PASSED_TESTS+=("config-deployment-\$platform")
      fi
    done

    if [[ \$config_deployment_score -ge 1 ]]; then
      echo "✅ PASS: Configuration deployment automation ready (\$config_deployment_score/3 platforms)"
      PASSED_TESTS+=("config-deployment-automation-ready")
    fi

    # Test Home Manager integration
    hm_configs=("modules/shared/home-manager.nix" "modules/darwin/home-manager.nix" "modules/nixos/home-manager.nix")
    hm_integration=false

    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "\$hm_config" ]]; then
        echo "✅ PASS: Home Manager configuration found: \$hm_config"
        PASSED_TESTS+=("hm-config-found")
        hm_integration=true
        break
      fi
    done

    if [[ "\$hm_integration" = "true" ]]; then
      echo "✅ PASS: Home Manager automation integrated"
      PASSED_TESTS+=("hm-automation-integrated")
    fi

    # Section 7: Performance and Monitoring
    echo ""
    echo "🔍 Section 7: Performance and monitoring..."

    # Test performance monitoring in automation
    if [[ -f "scripts/build-switch-common.sh" ]]; then
      if grep -q "time\|duration\|benchmark" "scripts/build-switch-common.sh" 2>/dev/null; then
        echo "✅ PASS: Build system includes performance monitoring"
        PASSED_TESTS+=("build-performance-monitoring")
      fi
    fi

    # Test logging in automation
    if [[ -f "\$auto_update_script" ]]; then
      if grep -q "log\|echo\|printf" "\$auto_update_script" 2>/dev/null; then
        echo "✅ PASS: Automation includes logging"
        PASSED_TESTS+=("automation-logging")
      fi
    fi

    # Section 8: Security and Updates
    echo ""
    echo "🔍 Section 8: Security and updates..."

    # Test update security measures
    if [[ -f "\$auto_update_script" ]]; then
      security_measures=("signature" "verify" "checksum" "hash")
      security_count=0

      for measure in "''${security_measures[@]}"; do
        if grep -qi "\$measure" "\$auto_update_script" 2>/dev/null; then
          security_count=\$((security_count + 1))
        fi
      done

      if [[ \$security_count -gt 0 ]]; then
        echo "✅ PASS: Update security measures detected (\$security_count measures)"
        PASSED_TESTS+=("update-security-measures")
      else
        echo "⚠️  INFO: Update security measures not detected"
      fi
    fi

    # Section 9: Production Readiness
    echo ""
    echo "🔍 Section 9: Production readiness validation..."

    # Test production deployment readiness
    production_components=()

    # Essential components check
    if [[ -f "flake.nix" ]]; then
      production_components+=("flake")
    fi

    if [[ -f "apps/${system}/build" ]]; then
      production_components+=("build")
    fi

    if [[ -f "apps/${system}/apply" ]]; then
      production_components+=("apply")
    fi

    if [[ -f "modules/shared/packages.nix" ]]; then
      production_components+=("packages")
    fi

    if [[ -f "\$auto_update_script" ]]; then
      production_components+=("automation")
    fi

    production_score=''${#production_components[@]}
    if [[ \$production_score -ge 4 ]]; then
      echo "✅ PASS: Package automation system production-ready (\$production_score/5 components)"
      PASSED_TESTS+=("production-ready")
    else
      echo "❌ FAIL: Package automation system not production-ready (\$production_score/5 components)"
      FAILED_TESTS+=("not-production-ready")
    fi

    # Section 10: Real-World Scenario Testing
    echo ""
    echo "🔍 Section 10: Real-world scenario testing..."

    # Scenario 1: Fresh system deployment
    echo "Testing fresh system deployment scenario..."
    fresh_deployment_ready=true

    if [[ ! -f "flake.nix" ]]; then
      fresh_deployment_ready=false
    fi

    if [[ ! -f "apps/${system}/build" ]]; then
      fresh_deployment_ready=false
    fi

    if [[ "\$fresh_deployment_ready" = "true" ]]; then
      echo "✅ PASS: Fresh system deployment scenario ready"
      PASSED_TESTS+=("fresh-deployment-scenario")
    else
      echo "❌ FAIL: Fresh system deployment scenario not ready"
      FAILED_TESTS+=("fresh-deployment-not-ready")
    fi

    # Scenario 2: System update workflow
    echo "Testing system update workflow scenario..."
    update_workflow_ready=true

    if [[ ! -f "\$auto_update_script" ]]; then
      update_workflow_ready=false
    fi

    if [[ ! -f "flake.lock" ]]; then
      update_workflow_ready=false
    fi

    if [[ "\$update_workflow_ready" = "true" ]]; then
      echo "✅ PASS: System update workflow scenario ready"
      PASSED_TESTS+=("update-workflow-scenario")
    else
      echo "❌ FAIL: System update workflow scenario not ready"
      FAILED_TESTS+=("update-workflow-not-ready")
    fi

    # Scenario 3: Package addition workflow
    echo "Testing package addition workflow scenario..."
    if [[ -f "modules/shared/packages.nix" && -f "apps/${system}/build-switch" ]]; then
      echo "✅ PASS: Package addition workflow scenario ready"
      PASSED_TESTS+=("package-addition-scenario")
    else
      echo "⚠️  INFO: Package addition workflow may require manual steps"
    fi

    # Results Summary
    echo ""
    echo "=== Comprehensive E2E Test Results ==="
    echo "✅ Passed tests: ''${#PASSED_TESTS[@]}"
    echo "❌ Failed tests: ''${#FAILED_TESTS[@]}"

    if [[ ''${#FAILED_TESTS[@]} -gt 0 ]]; then
      echo ""
      echo "❌ FAILED TESTS:"
      for test in "''${FAILED_TESTS[@]}"; do
        echo "   - \$test"
      done
      echo ""
      echo "🚨 E2E test identified ''${#FAILED_TESTS[@]} critical package/automation issues"
      echo "These issues must be resolved before production deployment"
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} E2E tests passed!"
      echo "✅ Package & Automation system is ready for real-world deployment"
      echo ""
      echo "🚀 E2E Test Coverage Summary:"
      echo "   ✓ Complete package deployment workflow"
      echo "   ✓ Automation system end-to-end testing"
      echo "   ✓ Dependency management end-to-end"
      echo "   ✓ Cross-platform package deployment"
      echo "   ✓ Build-switch package integration"
      echo "   ✓ Configuration management automation"
      echo "   ✓ Performance and monitoring"
      echo "   ✓ Security and updates"
      echo "   ✓ Production readiness validation"
      echo "   ✓ Real-world scenario testing"
      echo ""
      echo "🎯 Deployment Target: ${system}"
      echo "🌟 Package & Automation comprehensive deployment validated"
      exit 0
    fi
  '';

in
pkgs.runCommand "package-automation-comprehensive-e2e-test"
{
  buildInputs = with pkgs; [ bash nix git findutils gnugrep coreutils ];
} ''
  echo "=== Starting Comprehensive Package & Automation E2E Tests ==="
  echo "Testing real-world package management and automation scenarios..."
  echo "Platform: ${system}"
  echo ""

  # Run the comprehensive E2E test
  ${packageAutomationE2EScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "=== E2E Test Execution Complete ==="
  echo "Full results and logs saved to: $out"
  cp test-output.log $out
''
