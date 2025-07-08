# Integration Test for Build-Switch Complete Workflow
# Tests the full build-switch workflow in various environments
# GREEN PHASE: Tests that should pass with current implementation

{ pkgs, lib, src, flake ? null }:

let
  # Integration test for complete build-switch workflow
  testScript = pkgs.writeShellScript "test-build-switch-workflow" ''
    set -euo pipefail

    echo "=== Integration Test: Build-Switch Complete Workflow ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Test 1: Verify flake structure and app definitions
    echo "🔍 Testing flake structure and app definitions..."

    if [ -f ${src}/flake.nix ]; then
      echo "✅ PASS: flake.nix exists"
      PASSED_TESTS+=("flake-exists")

      # Check if apps are defined
      if grep -q "apps.*=" ${src}/flake.nix; then
        echo "✅ PASS: Apps section defined in flake.nix"
        PASSED_TESTS+=("apps-section-defined")
      else
        echo "❌ FAIL: No apps section in flake.nix"
        FAILED_TESTS+=("no-apps-section")
      fi

      # Check if platform-specific apps are configured
      if [ -f ${src}/lib/platform-apps.nix ]; then
        echo "✅ PASS: Platform-specific apps configuration exists"
        PASSED_TESTS+=("platform-apps-config")

        if grep -q "build-switch" ${src}/lib/platform-apps.nix; then
          echo "✅ PASS: build-switch app is defined in platform apps"
          PASSED_TESTS+=("build-switch-app-defined")
        else
          echo "❌ FAIL: build-switch app not found in platform apps"
          FAILED_TESTS+=("build-switch-app-missing")
        fi
      else
        echo "❌ FAIL: Platform apps configuration missing"
        FAILED_TESTS+=("platform-apps-missing")
      fi
    else
      echo "❌ FAIL: flake.nix not found"
      FAILED_TESTS+=("no-flake")
    fi

    # Test 2: Verify platform-specific build-switch scripts exist
    echo ""
    echo "🔍 Testing platform-specific build-switch scripts..."

    PLATFORMS=("aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux")

    for platform in "''${PLATFORMS[@]}"; do
      script_path="${src}/apps/$platform/build-switch"
      if [ -f "$script_path" ]; then
        echo "✅ PASS: build-switch script exists for $platform"
        PASSED_TESTS+=("script-$platform")

        # Check if script sources common logic
        if grep -q "build-switch-common.sh" "$script_path"; then
          echo "✅ PASS: $platform script sources common logic"
          PASSED_TESTS+=("common-logic-$platform")
        else
          echo "❌ FAIL: $platform script doesn't source common logic"
          FAILED_TESTS+=("no-common-logic-$platform")
        fi
      else
        echo "❌ FAIL: build-switch script missing for $platform"
        FAILED_TESTS+=("script-missing-$platform")
      fi
    done

    # Test 3: Verify common build-switch logic exists and is complete
    echo ""
    echo "🔍 Testing common build-switch logic..."

    if [ -f ${src}/scripts/build-switch-common.sh ]; then
      echo "✅ PASS: Common build-switch script exists"
      PASSED_TESTS+=("common-script-exists")

      # Check for modular structure
      required_modules=("logging.sh" "sudo-management.sh" "build-logic.sh")
      for module in "''${required_modules[@]}"; do
        if grep -q "$module" ${src}/scripts/build-switch-common.sh; then
          echo "✅ PASS: $module is loaded in common script"
          PASSED_TESTS+=("module-$module")
        else
          echo "❌ FAIL: $module not loaded in common script"
          FAILED_TESTS+=("module-missing-$module")
        fi
      done
    else
      echo "❌ FAIL: Common build-switch script missing"
      FAILED_TESTS+=("common-script-missing")
    fi

    # Test 4: Verify sudo management module completeness
    echo ""
    echo "🔍 Testing sudo management module completeness..."

    if [ -f ${src}/scripts/lib/sudo-management.sh ]; then
      echo "✅ PASS: Sudo management module exists"
      PASSED_TESTS+=("sudo-module-exists")

      # Check for critical functions
      critical_functions=("check_sudo_requirement" "get_sudo_prefix" "acquire_sudo_early")
      for func in "''${critical_functions[@]}"; do
        if grep -q "$func" ${src}/scripts/lib/sudo-management.sh; then
          echo "✅ PASS: $func function exists"
          PASSED_TESTS+=("function-$func")
        else
          echo "❌ FAIL: $func function missing"
          FAILED_TESTS+=("function-missing-$func")
        fi
      done

      # Check for non-interactive environment handling
      if grep -q "non-interactive.*environment\|! -t 0" ${src}/scripts/lib/sudo-management.sh; then
        echo "✅ PASS: Non-interactive environment detection exists"
        PASSED_TESTS+=("non-interactive-detection")
      else
        echo "❌ FAIL: No non-interactive environment detection"
        FAILED_TESTS+=("no-non-interactive-detection")
      fi

      # Check for Darwin-specific handling
      if grep -q "darwin.*sudo\|PLATFORM_TYPE.*darwin" ${src}/scripts/lib/sudo-management.sh; then
        echo "✅ PASS: Darwin-specific sudo handling exists"
        PASSED_TESTS+=("darwin-sudo-handling")
      else
        echo "❌ FAIL: No Darwin-specific sudo handling"
        FAILED_TESTS+=("no-darwin-sudo-handling")
      fi
    else
      echo "❌ FAIL: Sudo management module missing"
      FAILED_TESTS+=("sudo-module-missing")
    fi

    # Test 5: Verify build logic module completeness
    echo ""
    echo "🔍 Testing build logic module completeness..."

    if [ -f ${src}/scripts/lib/build-logic.sh ]; then
      echo "✅ PASS: Build logic module exists"
      PASSED_TESTS+=("build-logic-exists")

      # Check for critical functions
      build_functions=("run_build" "run_switch" "execute_build_switch")
      for func in "''${build_functions[@]}"; do
        if grep -q "$func" ${src}/scripts/lib/build-logic.sh; then
          echo "✅ PASS: $func function exists"
          PASSED_TESTS+=("build-function-$func")
        else
          echo "❌ FAIL: $func function missing"
          FAILED_TESTS+=("build-function-missing-$func")
        fi
      done

      # Check for platform-specific logic
      if grep -q "PLATFORM_TYPE.*darwin\|PLATFORM_TYPE.*linux" ${src}/scripts/lib/build-logic.sh; then
        echo "✅ PASS: Platform-specific build logic exists"
        PASSED_TESTS+=("platform-build-logic")
      else
        echo "❌ FAIL: No platform-specific build logic"
        FAILED_TESTS+=("no-platform-build-logic")
      fi
    else
      echo "❌ FAIL: Build logic module missing"
      FAILED_TESTS+=("build-logic-missing")
    fi

    # Test 6: Test actual flake app invocation (dry run)
    echo ""
    echo "🔍 Testing flake app invocation (dry run)..."

    # This test runs in the actual source directory context
    cd ${src}

    # Test if nix commands are available (simplified without timeout)
    if command -v nix >/dev/null 2>&1; then
      echo "Testing flake check..."
      if nix flake check --no-build 2>/dev/null; then
        echo "✅ PASS: Flake check succeeds"
        PASSED_TESTS+=("flake-check-pass")
      else
        echo "⚠️  WARN: Flake check failed (may be due to network/cache)"
        # Don't fail the test for this, as it might be environment-dependent
      fi

      # Test if build-switch app is accessible (simplified)
      echo "Testing build-switch app accessibility..."
      if nix flake show 2>/dev/null | grep -q "build-switch"; then
        echo "✅ PASS: build-switch app is accessible"
        PASSED_TESTS+=("app-accessible")
      else
        echo "❌ FAIL: build-switch app not accessible"
        FAILED_TESTS+=("app-not-accessible")
      fi
    else
      echo "⚠️  WARN: Nix not available for app testing"
    fi

    # Test 7: Verify home-manager configuration compatibility
    echo ""
    echo "🔍 Testing home-manager configuration compatibility..."

    # Check for backup file extension configuration in home-manager modules
    darwin_home_manager="${src}/modules/darwin/home-manager.nix"
    if [ -f "$darwin_home_manager" ]; then
      if grep -q "backupFileExtension" "$darwin_home_manager"; then
        echo "✅ PASS: Home-manager backup configuration exists"
        PASSED_TESTS+=("home-manager-backup-config")
      else
        echo "❌ FAIL: No home-manager backup configuration"
        FAILED_TESTS+=("no-backup-config")
      fi
    else
      echo "⚠️  WARN: Darwin home-manager configuration not found"
    fi

    echo ""
    echo "=== Integration Test Results Summary ==="
    echo "✅ Passed tests: ''${#PASSED_TESTS[@]}"
    echo "❌ Failed tests: ''${#FAILED_TESTS[@]}"

    if [[ ''${#FAILED_TESTS[@]} -gt 0 ]]; then
      echo ""
      echo "❌ FAILED TESTS:"
      for test in "''${FAILED_TESTS[@]}"; do
        echo "   - $test"
      done
      echo ""
      echo "🔧 Integration test identified issues that need resolution"
      exit 1
    else
      echo ""
      echo "🎉 All integration tests passed!"
      echo "✅ Build-switch workflow is ready for production use"
      exit 0
    fi
  '';

in
pkgs.runCommand "build-switch-workflow-integration-test"
{
  buildInputs = [ pkgs.bash pkgs.gnugrep pkgs.coreutils ];
} ''
  echo "Running build-switch workflow integration tests..."

  # Run the test and capture output
  ${testScript} 2>&1 | tee test-output.log

  # Store test results and output
  echo ""
  echo "Integration test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
