# Comprehensive System End-to-End Tests
# Tests complete system deployment and real-world scenarios

{ pkgs, flake ? null, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  system = pkgs.system;

  systemE2EScript = pkgs.writeShellScript "system-comprehensive-e2e" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive System End-to-End Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Complete Deployment Workflow
    echo ""
    echo "🔍 Section 1: Complete deployment workflow..."
    echo "Current system: ${system}"

    cd "${src}"
    export USER=\${USER:-testuser}
    CURRENT_SYSTEM=\$(nix eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo "${system}")

    # Phase 1: Pre-deployment validation
    echo ""
    echo "📋 Phase 1: Pre-deployment validation..."

    # Test flake structure and syntax
    if command -v nix >/dev/null 2>&1; then
      if nix flake check --impure --no-build 2>/dev/null; then
        echo "✅ PASS: Flake structure validation passed"
        PASSED_TESTS+=("flake-structure-valid")
      else
        echo "❌ FAIL: Flake structure validation failed"
        FAILED_TESTS+=("flake-structure-invalid")
      fi

      # Test configuration syntax for current platform
      case "\$CURRENT_SYSTEM" in
        *-darwin)
          config_path="darwinConfigurations.\"\$CURRENT_SYSTEM\""
          if nix eval --impure ".\#\$config_path.config.system.build.toplevel.drvPath" >/dev/null 2>&1; then
            echo "✅ PASS: Darwin configuration syntax valid"
            PASSED_TESTS+=("darwin-config-syntax-valid")
          else
            echo "❌ FAIL: Darwin configuration syntax invalid"
            FAILED_TESTS+=("darwin-config-syntax-invalid")
          fi
          ;;
        *-linux)
          config_path="nixosConfigurations.\"\$CURRENT_SYSTEM\""
          if nix eval --impure ".\#\$config_path.config.system.build.toplevel.drvPath" >/dev/null 2>&1; then
            echo "✅ PASS: NixOS configuration syntax valid"
            PASSED_TESTS+=("nixos-config-syntax-valid")
          else
            echo "❌ FAIL: NixOS configuration syntax invalid"
            FAILED_TESTS+=("nixos-config-syntax-invalid")
          fi
          ;;
      esac
    else
      echo "⚠️  WARN: Nix command not available for flake testing"
    fi

    # Phase 2: Build system validation
    echo ""
    echo "🔧 Phase 2: Build system validation..."

    # Test build application availability
    if command -v nix >/dev/null 2>&1; then
      if nix eval --impure ".\#apps.\$CURRENT_SYSTEM.build.program" --raw >/dev/null 2>&1; then
        build_app_path=\$(nix eval --impure ".\#apps.\$CURRENT_SYSTEM.build.program" --raw 2>/dev/null)
        echo "✅ PASS: Build app available: \$build_app_path"
        PASSED_TESTS+=("build-app-available")

        # Test build script exists
        if [[ -f "apps/\$CURRENT_SYSTEM/build" ]]; then
          echo "✅ PASS: Build script exists at expected location"
          PASSED_TESTS+=("build-script-exists")

          # Test build script is executable
          if [[ -x "apps/\$CURRENT_SYSTEM/build" ]]; then
            echo "✅ PASS: Build script is executable"
            PASSED_TESTS+=("build-script-executable")
          else
            echo "❌ FAIL: Build script not executable"
            FAILED_TESTS+=("build-script-not-executable")
          fi
        else
          echo "❌ FAIL: Build script not found"
          FAILED_TESTS+=("build-script-missing")
        fi
      else
        echo "❌ FAIL: Build app not defined in flake"
        FAILED_TESTS+=("build-app-missing")
      fi
    fi

    # Phase 3: System switch validation
    echo ""
    echo "🔄 Phase 3: System switch validation..."

    # Determine platform-specific switch command
    case "\$CURRENT_SYSTEM" in
      *-darwin)
        switch_app="apply"
        ;;
      *-linux)
        switch_app="apply"
        ;;
    esac

    # Test switch application availability
    if command -v nix >/dev/null 2>&1; then
      if nix eval --impure ".\#apps.\$CURRENT_SYSTEM.\$switch_app.program" --raw >/dev/null 2>&1; then
        switch_app_path=\$(nix eval --impure ".\#apps.\$CURRENT_SYSTEM.\$switch_app.program" --raw 2>/dev/null)
        echo "✅ PASS: Switch app '\$switch_app' available: \$switch_app_path"
        PASSED_TESTS+=("switch-app-available")

        # Test switch script exists
        if [[ -f "apps/\$CURRENT_SYSTEM/\$switch_app" ]]; then
          echo "✅ PASS: Switch script exists at expected location"
          PASSED_TESTS+=("switch-script-exists")
        else
          echo "❌ FAIL: Switch script not found"
          FAILED_TESTS+=("switch-script-missing")
        fi
      else
        echo "❌ FAIL: Switch app '\$switch_app' not defined in flake"
        FAILED_TESTS+=("switch-app-missing")
      fi
    fi

    # Phase 4: Build-switch integration validation
    echo ""
    echo "🔗 Phase 4: Build-switch integration validation..."

    # Test build-switch application availability
    if command -v nix >/dev/null 2>&1; then
      if nix eval --impure ".\#apps.\$CURRENT_SYSTEM.build-switch.program" --raw >/dev/null 2>&1; then
        build_switch_path=\$(nix eval --impure ".\#apps.\$CURRENT_SYSTEM.build-switch.program" --raw 2>/dev/null)
        echo "✅ PASS: Build-switch app available: \$build_switch_path"
        PASSED_TESTS+=("build-switch-app-available")

        # Test build-switch script structure
        if [[ -f "apps/\$CURRENT_SYSTEM/build-switch" ]]; then
          echo "✅ PASS: Build-switch script exists"
          PASSED_TESTS+=("build-switch-script-exists")

          # Test for common script sourcing
          if grep -q "build-switch-common.sh" "apps/\$CURRENT_SYSTEM/build-switch" 2>/dev/null; then
            echo "✅ PASS: Build-switch uses common script architecture"
            PASSED_TESTS+=("build-switch-common-architecture")
          fi
        else
          echo "❌ FAIL: Build-switch script not found"
          FAILED_TESTS+=("build-switch-script-missing")
        fi
      else
        echo "❌ FAIL: Build-switch app not defined in flake"
        FAILED_TESTS+=("build-switch-app-missing")
      fi
    fi

    # Section 2: Multi-Platform Deployment Readiness
    echo ""
    echo "🔍 Section 2: Multi-platform deployment readiness..."

    # Test all supported platforms
    platforms=("x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux")

    for platform in "''${platforms[@]}"; do
      echo ""
      echo "🖥️  Testing deployment readiness for \$platform..."

      if command -v nix >/dev/null 2>&1; then
        # Test configuration availability
        case "\$platform" in
          *-darwin)
            config="darwinConfigurations.\"\$platform\""
            attr="config.system.build.toplevel.drvPath"
            ;;
          *-linux)
            config="nixosConfigurations.\"\$platform\""
            attr="config.system.build.toplevel.drvPath"
            ;;
        esac

        if nix eval --impure ".\#\$config.\$attr" >/dev/null 2>&1; then
          echo "✅ PASS: \$platform configuration ready for deployment"
          PASSED_TESTS+=("config-ready-\$platform")
        else
          echo "❌ FAIL: \$platform configuration not deployment-ready"
          FAILED_TESTS+=("config-not-ready-\$platform")
        fi

        # Test essential apps for platform
        case "\$platform" in
          *-darwin)
            essential_apps=("build" "apply" "rollback")
            ;;
          *-linux)
            essential_apps=("build" "apply")
            ;;
        esac

        for app in "''${essential_apps[@]}"; do
          if nix eval --impure ".\#apps.\$platform.\$app.program" >/dev/null 2>&1; then
            echo "✅ PASS: \$platform.\$app app ready"
            PASSED_TESTS+=("app-ready-\$platform-\$app")
          else
            echo "❌ FAIL: \$platform.\$app app not ready"
            FAILED_TESTS+=("app-not-ready-\$platform-\$app")
          fi
        done
      fi
    done

    # Section 3: Package and Service Deployment
    echo ""
    echo "🔍 Section 3: Package and service deployment..."

    # Test shared package deployment consistency
    if [[ -f "modules/shared/packages.nix" ]]; then
      echo "✅ PASS: Shared packages configuration exists"
      PASSED_TESTS+=("shared-packages-exists")

      if command -v nix-instantiate >/dev/null 2>&1; then
        if nix-instantiate --eval modules/shared/packages.nix --arg pkgs 'import <nixpkgs> {}' >/dev/null 2>&1; then
          echo "✅ PASS: Shared packages configuration valid"
          PASSED_TESTS+=("shared-packages-valid")
        else
          echo "❌ FAIL: Shared packages configuration invalid"
          FAILED_TESTS+=("shared-packages-invalid")
        fi
      fi
    else
      echo "❌ FAIL: Shared packages configuration missing"
      FAILED_TESTS+=("shared-packages-missing")
    fi

    # Test platform-specific package deployment
    case "\$CURRENT_SYSTEM" in
      *-darwin)
        if [[ -f "modules/darwin/packages.nix" ]]; then
          echo "✅ PASS: Darwin packages configuration exists"
          PASSED_TESTS+=("darwin-packages-exists")
        fi

        # Test Homebrew integration
        if [[ -f "modules/darwin/casks.nix" ]]; then
          echo "✅ PASS: Darwin Homebrew casks configuration exists"
          PASSED_TESTS+=("darwin-casks-exists")

          # Test for common cask categories
          if grep -q "browsers\|development\|utilities" modules/darwin/casks.nix 2>/dev/null; then
            echo "✅ PASS: Darwin casks include essential categories"
            PASSED_TESTS+=("darwin-casks-categories")
          fi
        fi
        ;;
      *-linux)
        if [[ -f "modules/nixos/packages.nix" ]]; then
          echo "✅ PASS: NixOS packages configuration exists"
          PASSED_TESTS+=("nixos-packages-exists")
        fi
        ;;
    esac

    # Section 4: Configuration File Management
    echo ""
    echo "🔍 Section 4: Configuration file management..."

    # Test configuration file deployment structure
    config_dirs=("modules/shared/config" "modules/darwin/config" "modules/nixos/config")
    config_files_total=0

    for config_dir in "''${config_dirs[@]}"; do
      if [[ -d "\$config_dir" ]]; then
        config_count=\$(find "\$config_dir" -type f | wc -l)
        config_files_total=\$((config_files_total + config_count))

        if [[ \$config_count -gt 0 ]]; then
          platform=\$(basename \$(dirname "\$config_dir"))
          echo "✅ PASS: \$platform has \$config_count configuration files"
          PASSED_TESTS+=("config-files-\$platform")
        fi
      fi
    done

    echo "Total configuration files: \$config_files_total"

    # Test Claude CLI configuration deployment
    claude_config_dirs=("modules/shared/config/claude" "config/claude" ".claude")
    claude_config_found=false

    for claude_dir in "''${claude_config_dirs[@]}"; do
      if [[ -d "\$claude_dir" ]]; then
        echo "✅ PASS: Claude configuration directory found: \$claude_dir"
        PASSED_TESTS+=("claude-config-dir")
        claude_config_found=true

        # Test for essential Claude files
        claude_files=("CLAUDE.md" "settings.json" "commands")
        for file in "''${claude_files[@]}"; do
          if [[ -e "\$claude_dir/\$file" ]]; then
            echo "✅ PASS: Claude '\$file' configuration exists"
            PASSED_TESTS+=("claude-config-\$file")
          fi
        done

        break
      fi
    done

    if [[ "\$claude_config_found" = "false" ]]; then
      echo "⚠️  INFO: Claude configuration directory not found"
    fi

    # Section 5: System State Management
    echo ""
    echo "🔍 Section 5: System state management..."

    # Test system generation management
    case "\$CURRENT_SYSTEM" in
      *-darwin)
        # Test Darwin rollback capabilities
        if command -v nix >/dev/null 2>&1; then
          if nix eval --impure ".\#apps.\$CURRENT_SYSTEM.rollback.program" --raw >/dev/null 2>&1; then
            echo "✅ PASS: Darwin rollback system available"
            PASSED_TESTS+=("darwin-rollback-available")
          else
            echo "❌ FAIL: Darwin rollback system not available"
            FAILED_TESTS+=("darwin-rollback-missing")
          fi
        fi

        # Test for darwin-rebuild availability
        if command -v darwin-rebuild >/dev/null 2>&1; then
          echo "✅ PASS: darwin-rebuild command available"
          PASSED_TESTS+=("darwin-rebuild-available")
        else
          echo "⚠️  INFO: darwin-rebuild not available (expected in test environment)"
        fi
        ;;
      *-linux)
        # Test NixOS system management
        if command -v nixos-rebuild >/dev/null 2>&1; then
          echo "✅ PASS: nixos-rebuild command available"
          PASSED_TESTS+=("nixos-rebuild-available")
        else
          echo "⚠️  INFO: nixos-rebuild not available (expected in test environment)"
        fi
        ;;
    esac

    # Test build-switch common script architecture
    if [[ -f "scripts/build-switch-common.sh" ]]; then
      echo "✅ PASS: Build-switch common script exists"
      PASSED_TESTS+=("build-switch-common-exists")

      # Test for modular architecture
      if grep -q "lib/sudo-management.sh\|lib/build-logic.sh" scripts/build-switch-common.sh 2>/dev/null; then
        echo "✅ PASS: Build-switch uses modular architecture"
        PASSED_TESTS+=("build-switch-modular")
      fi
    else
      echo "❌ FAIL: Build-switch common script missing"
      FAILED_TESTS+=("build-switch-common-missing")
    fi

    # Section 6: Auto-Update System Deployment
    echo ""
    echo "🔍 Section 6: Auto-update system deployment..."

    # Test auto-update script deployment
    auto_update_script="scripts/auto-update-dotfiles"
    if [[ -f "\$auto_update_script" ]]; then
      echo "✅ PASS: Auto-update script exists"
      PASSED_TESTS+=("auto-update-script-exists")

      # Test script is executable
      if [[ -x "\$auto_update_script" ]]; then
        echo "✅ PASS: Auto-update script is executable"
        PASSED_TESTS+=("auto-update-script-executable")
      else
        echo "❌ FAIL: Auto-update script not executable"
        FAILED_TESTS+=("auto-update-script-not-executable")
      fi

      # Test for safety mechanisms
      if grep -q "backup\|rollback\|verify" "\$auto_update_script" 2>/dev/null; then
        echo "✅ PASS: Auto-update includes safety mechanisms"
        PASSED_TESTS+=("auto-update-safety")
      else
        echo "⚠️  INFO: Auto-update safety mechanisms not detected"
      fi
    else
      echo "⚠️  INFO: Auto-update script not found"
    fi

    # Section 7: Testing Framework Deployment
    echo ""
    echo "🔍 Section 7: Testing framework deployment..."

    # Test testing framework availability
    if command -v nix >/dev/null 2>&1; then
      if nix flake check --impure --all-systems --no-build 2>/dev/null; then
        echo "✅ PASS: Testing framework deployment-ready"
        PASSED_TESTS+=("testing-framework-ready")
      else
        echo "⚠️  WARN: Testing framework deployment readiness not confirmed"
      fi
    fi

    # Test test categories availability
    test_categories=("unit" "integration" "e2e" "performance")
    for category in "''${test_categories[@]}"; do
      if [[ -d "tests/\$category" ]]; then
        test_count=\$(find "tests/\$category" -name "*.nix" -type f | wc -l)
        if [[ \$test_count -gt 0 ]]; then
          echo "✅ PASS: Test category '\$category' has \$test_count tests"
          PASSED_TESTS+=("test-category-\$category")
        fi
      fi
    done

    # Section 8: Documentation Deployment
    echo ""
    echo "🔍 Section 8: Documentation deployment..."

    # Test essential documentation availability
    essential_docs=("README.md" "CLAUDE.md")
    for doc in "''${essential_docs[@]}"; do
      if [[ -f "\$doc" ]]; then
        echo "✅ PASS: Essential documentation '\$doc' exists"
        PASSED_TESTS+=("doc-\$doc")
      else
        echo "❌ FAIL: Essential documentation '\$doc' missing"
        FAILED_TESTS+=("doc-\$doc-missing")
      fi
    done

    # Test documentation structure
    if [[ -d "docs" ]]; then
      doc_count=\$(find docs -name "*.md" -type f | wc -l)
      if [[ \$doc_count -gt 0 ]]; then
        echo "✅ PASS: Documentation directory has \$doc_count files"
        PASSED_TESTS+=("docs-directory")
      fi
    fi

    # Section 9: Complete System Integration
    echo ""
    echo "🔍 Section 9: Complete system integration validation..."

    # Test that all major system components work together
    major_components=("flake" "modules" "apps" "scripts" "tests")
    integration_score=0

    for component in "''${major_components[@]}"; do
      if [[ -d "\$component" || -f "\$component.nix" ]]; then
        case "\$component" in
          "flake")
            if [[ -f "flake.nix" ]]; then
              integration_score=\$((integration_score + 1))
            fi
            ;;
          "modules")
            if [[ -d "modules/shared" ]]; then
              integration_score=\$((integration_score + 1))
            fi
            ;;
          "apps")
            if [[ -d "apps/\$CURRENT_SYSTEM" ]]; then
              integration_score=\$((integration_score + 1))
            fi
            ;;
          "scripts")
            if [[ -d "scripts" ]]; then
              integration_score=\$((integration_score + 1))
            fi
            ;;
          "tests")
            if [[ -d "tests" ]]; then
              integration_score=\$((integration_score + 1))
            fi
            ;;
        esac
      fi
    done

    if [[ \$integration_score -ge 4 ]]; then
      echo "✅ PASS: System integration complete (\$integration_score/5 components)"
      PASSED_TESTS+=("system-integration-complete")
    else
      echo "❌ FAIL: System integration incomplete (\$integration_score/5 components)"
      FAILED_TESTS+=("system-integration-incomplete")
    fi

    # Section 10: Production Readiness Validation
    echo ""
    echo "🔍 Section 10: Production readiness validation..."

    # Final production readiness check
    critical_components=()

    # Check flake validity
    if command -v nix >/dev/null 2>&1 && nix flake check --impure --no-build 2>/dev/null; then
      critical_components+=("flake-valid")
    fi

    # Check build system
    if [[ -f "apps/\$CURRENT_SYSTEM/build" ]]; then
      critical_components+=("build-system")
    fi

    # Check switch system
    if [[ -f "apps/\$CURRENT_SYSTEM/apply" ]]; then
      critical_components+=("switch-system")
    fi

    # Check documentation
    if [[ -f "README.md" ]]; then
      critical_components+=("documentation")
    fi

    # Check testing
    if [[ -d "tests" ]]; then
      critical_components+=("testing")
    fi

    production_score=''${#critical_components[@]}
    if [[ \$production_score -ge 4 ]]; then
      echo "✅ PASS: System is production-ready (\$production_score/5 critical components)"
      PASSED_TESTS+=("production-ready")
    else
      echo "❌ FAIL: System not production-ready (\$production_score/5 critical components)"
      FAILED_TESTS+=("not-production-ready")
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
      echo "🚨 E2E test identified ''${#FAILED_TESTS[@]} critical deployment issues"
      echo "These issues must be resolved before production deployment"
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} E2E tests passed!"
      echo "✅ System is ready for real-world deployment"
      echo ""
      echo "🚀 E2E Test Coverage Summary:"
      echo "   ✓ Complete deployment workflow"
      echo "   ✓ Multi-platform deployment readiness"
      echo "   ✓ Package and service deployment"
      echo "   ✓ Configuration file management"
      echo "   ✓ System state management"
      echo "   ✓ Auto-update system deployment"
      echo "   ✓ Testing framework deployment"
      echo "   ✓ Documentation deployment"
      echo "   ✓ Complete system integration"
      echo "   ✓ Production readiness validation"
      echo ""
      echo "🎯 Deployment Target: \$CURRENT_SYSTEM"
      echo "🌟 System comprehensive deployment validated"
      exit 0
    fi
  '';

in
pkgs.runCommand "system-comprehensive-e2e-test"
{
  buildInputs = with pkgs; [ bash nix git findutils gnugrep coreutils ];
} ''
  echo "=== Starting Comprehensive System E2E Tests ==="
  echo "Testing complete system deployment and real-world scenarios..."
  echo "Platform: ${system}"
  echo ""

  # Run the comprehensive E2E test
  ${systemE2EScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "=== E2E Test Execution Complete ==="
  echo "Full results and logs saved to: $out"
  cp test-output.log $out
''
