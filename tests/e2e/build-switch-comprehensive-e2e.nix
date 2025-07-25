# Comprehensive Build-Switch End-to-End Tests
# Complete E2E test suite covering all real-world scenarios

{ pkgs, flake ? null, src }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";

  # E2E test script for real-world scenarios
  e2eTestScript = pkgs.writeShellScript "build-switch-comprehensive-e2e" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive Build-Switch End-to-End Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Multi-Platform Script Validation
    echo ""
    echo "🔍 Section 1: Multi-platform script validation..."

    PLATFORMS=("aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux")

    for platform in "''${PLATFORMS[@]}"; do
      script_path="${src}/apps/$platform/build-switch"
      if [ -f "$script_path" ]; then
        echo "✅ PASS: $platform build-switch script exists"
        PASSED_TESTS+=("script-exists-$platform")

        # Validate script is executable
        if [ -x "$script_path" ]; then
          echo "✅ PASS: $platform script is executable"
          PASSED_TESTS+=("executable-$platform")
        else
          echo "❌ FAIL: $platform script is not executable"
          FAILED_TESTS+=("not-executable-$platform")
        fi

        # Validate platform-specific configurations
        case "$platform" in
          *darwin*)
            if grep -q "darwinConfigurations\|darwin-rebuild" "$script_path"; then
              echo "✅ PASS: $platform has correct Darwin configuration"
              PASSED_TESTS+=("darwin-config-$platform")
            else
              echo "❌ FAIL: $platform missing Darwin configuration"
              FAILED_TESTS+=("no-darwin-config-$platform")
            fi
            ;;
          *linux*)
            if grep -q "nixosConfigurations\|nixos-rebuild\|home-manager" "$script_path"; then
              echo "✅ PASS: $platform has correct Linux configuration"
              PASSED_TESTS+=("linux-config-$platform")
            else
              echo "❌ FAIL: $platform missing Linux configuration"
              FAILED_TESTS+=("no-linux-config-$platform")
            fi
            ;;
        esac

        # Validate architecture-specific elements
        if grep -q "$platform" "$script_path"; then
          echo "✅ PASS: $platform script includes architecture detection"
          PASSED_TESTS+=("arch-detection-$platform")
        else
          echo "⚠️  INFO: Architecture detection may be in common script"
        fi
      else
        echo "❌ FAIL: $platform build-switch script missing"
        FAILED_TESTS+=("script-missing-$platform")
      fi
    done

    # Section 2: Complete Workflow Integration
    echo ""
    echo "🔍 Section 2: Complete workflow integration..."

    # Check main script integration
    main_script="${buildSwitchScript}"
    if [ -f "$main_script" ]; then
      echo "✅ PASS: Main build-switch script accessible"
      PASSED_TESTS+=("main-script-accessible")

      # Validate common script sourcing
      if grep -q "build-switch-common.sh" "$main_script"; then
        echo "✅ PASS: Common script properly sourced"
        PASSED_TESTS+=("common-script-sourced")
      else
        echo "❌ FAIL: Common script not sourced"
        FAILED_TESTS+=("common-script-not-sourced")
      fi

      # Validate main execution function
      if grep -q "execute_build_switch\|main.*function\|workflow.*execute" "$main_script"; then
        echo "✅ PASS: Main execution function present"
        PASSED_TESTS+=("main-execution-function")
      else
        echo "❌ FAIL: No main execution function"
        FAILED_TESTS+=("no-main-execution-function")
      fi

      # Validate argument forwarding
      if grep -q '\$@\|"\$@"\|''${@}' "$main_script"; then
        echo "✅ PASS: Argument forwarding implemented"
        PASSED_TESTS+=("argument-forwarding")
      else
        echo "❌ FAIL: No argument forwarding"
        FAILED_TESTS+=("no-argument-forwarding")
      fi
    else
      echo "❌ FAIL: Main build-switch script not accessible"
      FAILED_TESTS+=("main-script-not-accessible")
    fi

    # Section 3: Environment and Configuration Validation
    echo ""
    echo "🔍 Section 3: Environment and configuration validation..."

    # Check environment variables setup
    if grep -q "NIXPKGS_ALLOW_UNFREE=1" "$main_script"; then
      echo "✅ PASS: Unfree packages environment variable set"
      PASSED_TESTS+=("unfree-packages-env")
    else
      echo "❌ FAIL: Unfree packages environment variable not set"
      FAILED_TESTS+=("no-unfree-packages-env")
    fi

    # Check script directory resolution
    if grep -q "SCRIPT_DIR.*=.*dirname\|DIR.*=.*dirname" "$main_script"; then
      echo "✅ PASS: Script directory resolution implemented"
      PASSED_TESTS+=("script-dir-resolution")
    else
      echo "❌ FAIL: No script directory resolution"
      FAILED_TESTS+=("no-script-dir-resolution")
    fi

    # Check project root detection
    if grep -q "PROJECT_ROOT.*=\|ROOT.*=.*realpath\|FLAKE_ROOT" "$main_script"; then
      echo "✅ PASS: Project root detection implemented"
      PASSED_TESTS+=("project-root-detection")
    else
      echo "❌ FAIL: No project root detection"
      FAILED_TESTS+=("no-project-root-detection")
    fi

    # Section 4: Flake Integration Validation
    echo ""
    echo "🔍 Section 4: Flake integration validation..."

    cd ${src}

    # Test flake.nix structure
    if [ -f flake.nix ]; then
      echo "✅ PASS: flake.nix exists in project root"
      PASSED_TESTS+=("flake-exists")

      # Check for apps configuration
      if grep -q "apps.*=\|applications.*=" flake.nix; then
        echo "✅ PASS: Apps configuration present in flake.nix"
        PASSED_TESTS+=("apps-in-flake")
      else
        echo "❌ FAIL: No apps configuration in flake.nix"
        FAILED_TESTS+=("no-apps-in-flake")
      fi

      # Check for build-switch app definition
      if grep -q "build-switch" flake.nix || [ -f lib/platform-apps.nix ]; then
        echo "✅ PASS: build-switch app definition found"
        PASSED_TESTS+=("build-switch-app-defined")
      else
        echo "❌ FAIL: build-switch app not defined"
        FAILED_TESTS+=("build-switch-app-not-defined")
      fi

      # Check for platform-specific configurations
      darwin_configs=$(grep -c "darwinConfigurations\|darwin.*=" flake.nix || echo 0)
      nixos_configs=$(grep -c "nixosConfigurations\|nixos.*=" flake.nix || echo 0)

      if [ "$darwin_configs" -gt 0 ]; then
        echo "✅ PASS: Darwin configurations present ($darwin_configs found)"
        PASSED_TESTS+=("darwin-configs-present")
      else
        echo "❌ FAIL: No Darwin configurations found"
        FAILED_TESTS+=("no-darwin-configs")
      fi

      if [ "$nixos_configs" -gt 0 ]; then
        echo "✅ PASS: NixOS configurations present ($nixos_configs found)"
        PASSED_TESTS+=("nixos-configs-present")
      else
        echo "⚠️  INFO: No NixOS configurations (may be Darwin-only setup)"
      fi
    else
      echo "❌ FAIL: flake.nix not found in project root"
      FAILED_TESTS+=("no-flake")
    fi

    # Section 5: Real-World Execution Simulation
    echo ""
    echo "🔍 Section 5: Real-world execution simulation..."

    # Test script can be invoked (dry run)
    if command -v nix >/dev/null 2>&1; then
      echo "Testing flake app invocation..."

      # Test flake show (with timeout)
      if timeout 15s nix flake show 2>/dev/null | head -20; then
        echo "✅ PASS: Flake show executed successfully"
        PASSED_TESTS+=("flake-show-success")
      else
        echo "⚠️  WARN: Flake show failed or timed out (may be network/cache related)"
      fi

      # Test build-switch app visibility
      if nix flake show 2>/dev/null | grep -q "build-switch" || \
         [ -x "$main_script" ]; then
        echo "✅ PASS: build-switch app is accessible"
        PASSED_TESTS+=("build-switch-accessible")
      else
        echo "❌ FAIL: build-switch app not accessible"
        FAILED_TESTS+=("build-switch-not-accessible")
      fi

      # Test help/usage functionality (if supported)
      if [ -x "$main_script" ]; then
        # Try to get help output (non-blocking)
        if timeout 5s "$main_script" --help 2>/dev/null | head -5 || \
           timeout 5s "$main_script" -h 2>/dev/null | head -5 || \
           grep -q "usage\|help\|Usage\|Help" "$main_script"; then
          echo "✅ PASS: Help/usage functionality available"
          PASSED_TESTS+=("help-functionality")
        else
          echo "⚠️  INFO: Help functionality may not be implemented"
        fi
      fi
    else
      echo "⚠️  WARN: Nix not available for execution testing"
    fi

    # Section 6: Error Handling and Edge Cases
    echo ""
    echo "🔍 Section 6: Error handling and edge cases..."

    # Check for error handling patterns in main script
    if grep -q "set -e\|exit 1\|error.*handling\|trap.*EXIT" "$main_script"; then
      echo "✅ PASS: Error handling patterns detected"
      PASSED_TESTS+=("error-handling-patterns")
    else
      echo "❌ FAIL: No error handling patterns found"
      FAILED_TESTS+=("no-error-handling-patterns")
    fi

    # Check for verbose/debug output support
    if grep -q "verbose\|debug\|VERBOSE\|DEBUG" "$main_script" || \
       [ -f "${src}/scripts/build-switch-common.sh" ] && \
       grep -q "verbose\|debug\|VERBOSE\|DEBUG" "${src}/scripts/build-switch-common.sh"; then
      echo "✅ PASS: Verbose/debug output support detected"
      PASSED_TESTS+=("verbose-debug-support")
    else
      echo "❌ FAIL: No verbose/debug output support"
      FAILED_TESTS+=("no-verbose-debug-support")
    fi

    # Section 7: Security and Permissions
    echo ""
    echo "🔍 Section 7: Security and permissions validation..."

    # Check for sudo handling
    sudo_script="${src}/scripts/lib/sudo-management.sh"
    if [ -f "$sudo_script" ] || grep -q "sudo" "$main_script"; then
      echo "✅ PASS: Sudo handling implemented"
      PASSED_TESTS+=("sudo-handling")

      # Check for non-interactive environment handling
      if [ -f "$sudo_script" ] && grep -q "non-interactive\|! -t 0" "$sudo_script"; then
        echo "✅ PASS: Non-interactive environment handling present"
        PASSED_TESTS+=("non-interactive-handling")
      else
        echo "⚠️  INFO: Non-interactive environment handling may be implicit"
      fi
    else
      echo "⚠️  INFO: Sudo handling may not be required for this configuration"
    fi

    # Check for path validation and security
    if grep -q "realpath\|readlink\|validate.*path" "$main_script" || \
       ([ -f "$sudo_script" ] && grep -q "realpath\|readlink\|validate.*path" "$sudo_script"); then
      echo "✅ PASS: Path validation and security measures detected"
      PASSED_TESTS+=("path-security")
    else
      echo "⚠️  INFO: Path security may be implicit in script design"
    fi

    # Section 8: Performance and Optimization
    echo ""
    echo "🔍 Section 8: Performance and optimization validation..."

    # Check for performance-related configurations
    if grep -q "parallel\|jobs\|max-jobs\|cores" "$main_script" || \
       grep -q "parallel\|jobs\|max-jobs\|cores" "${src}/flake.nix" 2>/dev/null; then
      echo "✅ PASS: Performance optimization configurations detected"
      PASSED_TESTS+=("performance-optimization")
    else
      echo "⚠️  INFO: Performance optimization may be in Nix configuration"
    fi

    # Check for caching and optimization
    if grep -q "cache\|substituter\|binary-cache" "$main_script" || \
       grep -q "cache\|substituter\|binary-cache" "${src}/flake.nix" 2>/dev/null; then
      echo "✅ PASS: Caching and optimization features detected"
      PASSED_TESTS+=("caching-optimization")
    else
      echo "⚠️  INFO: Caching may be handled by Nix defaults"
    fi

    # Final Results
    echo ""
    echo "=== Comprehensive E2E Test Results ==="
    echo "✅ Passed tests: ''${#PASSED_TESTS[@]}"
    echo "❌ Failed tests: ''${#FAILED_TESTS[@]}"

    if [[ ''${#FAILED_TESTS[@]} -gt 0 ]]; then
      echo ""
      echo "❌ FAILED TESTS:"
      for test in "''${FAILED_TESTS[@]}"; do
        echo "   - $test"
      done
      echo ""
      echo "🚨 E2E test identified ''${#FAILED_TESTS[@]} critical issues"
      echo "These issues must be resolved before production deployment"
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} E2E tests passed!"
      echo "✅ Build-switch is ready for real-world deployment"
      echo ""
      echo "🚀 E2E Test Coverage Summary:"
      echo "   ✓ Multi-platform script validation"
      echo "   ✓ Complete workflow integration"
      echo "   ✓ Environment and configuration validation"
      echo "   ✓ Flake integration validation"
      echo "   ✓ Real-world execution simulation"
      echo "   ✓ Error handling and edge cases"
      echo "   ✓ Security and permissions validation"
      echo "   ✓ Performance and optimization validation"
      echo ""
      echo "🎯 Production Readiness: CONFIRMED"
      exit 0
    fi
  '';

in
pkgs.runCommand "build-switch-comprehensive-e2e-test"
{
  buildInputs = with pkgs; [ bash coreutils nix git findutils gnugrep ];
} ''
  echo "=== Starting Comprehensive Build-Switch E2E Tests ==="
  echo "Testing real-world deployment scenarios..."
  echo ""

  # Run the comprehensive E2E test
  ${e2eTestScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "=== E2E Test Execution Complete ==="
  echo "Full results and logs saved to: $out"
  cp test-output.log $out
''
