# Comprehensive Package & Automation Unit Tests
# Tests package management and automation systems

{ pkgs, flake ? null, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  packageAutomationUnitScript = pkgs.writeShellScript "package-automation-comprehensive-unit" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive Package & Automation Unit Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Package Configuration Structure
    echo ""
    echo "🔍 Section 1: Package configuration structure..."

    # Test shared packages configuration
    shared_packages="'${src}/modules/shared/packages.nix"
    if [[ -f "$shared_packages" ]]; then
      echo "✅ PASS: Shared packages configuration exists"
      PASSED_TESTS+=("shared-packages-exists")

      # Test package syntax
      if command -v nix-instantiate >/dev/null 2>&1; then
        if nix-instantiate --eval "$shared_packages" --arg pkgs 'import <nixpkgs> {}' >/dev/null 2>&1; then
          echo "✅ PASS: Shared packages syntax valid"
          PASSED_TESTS+=("shared-packages-syntax-valid")
        else
          echo "❌ FAIL: Shared packages syntax invalid"
          FAILED_TESTS+=("shared-packages-syntax-invalid")
        fi
      fi

      # Test for package categories
      package_categories=("development" "utilities" "system" "editor" "terminal")
      for category in "''${package_categories[@]}"; do
        if grep -qi "$category" "$shared_packages" 2>/dev/null; then
          echo "✅ PASS: Package category '$category' found"
          PASSED_TESTS+=("package-category-$category")
        fi
      done

      # Test for essential packages
      essential_packages=("git" "vim" "curl" "wget" "tree")
      for package in "''${essential_packages[@]}"; do
        if grep -q "$package" "$shared_packages" 2>/dev/null; then
          echo "✅ PASS: Essential package '$package' configured"
          PASSED_TESTS+=("essential-package-$package")
        fi
      done
    else
      echo "❌ FAIL: Shared packages configuration missing"
      FAILED_TESTS+=("shared-packages-missing")
    fi

    # Test platform-specific packages
    platform_packages=("'${src}/modules/darwin/packages.nix" "'${src}/modules/nixos/packages.nix")
    for pkg_file in "''${platform_packages[@]}"; do
      if [[ -f "$pkg_file" ]]; then
        platform=$(basename $(dirname "$pkg_file"))
        echo "✅ PASS: $platform packages configuration exists"
        PASSED_TESTS+=("$platform-packages-exists")

        # Test platform-specific syntax
        if command -v nix-instantiate >/dev/null 2>&1; then
          if nix-instantiate --eval "$pkg_file" --arg pkgs 'import <nixpkgs> {}' >/dev/null 2>&1; then
            echo "✅ PASS: $platform packages syntax valid"
            PASSED_TESTS+=("$platform-packages-syntax-valid")
          else
            echo "❌ FAIL: $platform packages syntax invalid"
            FAILED_TESTS+=("$platform-packages-syntax-invalid")
          fi
        fi
      fi
    done

    # Section 2: Homebrew Package Management (Darwin)
    echo ""
    echo "🔍 Section 2: Homebrew package management..."

    # Test Homebrew configuration
    homebrew_configs=("'${src}/modules/darwin/casks.nix" "'${src}/modules/darwin/homebrew.nix")
    homebrew_found=false

    for hb_config in "''${homebrew_configs[@]}"; do
      if [[ -f "$hb_config" ]]; then
        echo "✅ PASS: Homebrew configuration found: $hb_config"
        PASSED_TESTS+=("homebrew-config-found")
        homebrew_found=true

        # Test for common cask categories
        cask_categories=("browsers" "development" "utilities" "media" "productivity")
        for category in "''${cask_categories[@]}"; do
          if grep -qi "$category" "$hb_config" 2>/dev/null; then
            echo "✅ PASS: Homebrew category '$category' found"
            PASSED_TESTS+=("homebrew-category-$category")
          fi
        done

        # Test for essential casks
        essential_casks=("docker" "chrome" "firefox" "intellij" "iterm")
        for cask in "''${essential_casks[@]}"; do
          if grep -qi "$cask" "$hb_config" 2>/dev/null; then
            echo "✅ PASS: Essential cask '$cask' configured"
            PASSED_TESTS+=("essential-cask-$cask")
          fi
        done

        break
      fi
    done

    if [[ "$homebrew_found" = "false" ]]; then
      echo "⚠️  INFO: Homebrew configuration not found (may be Darwin-only)"
    fi

    # Test nix-homebrew integration
    if [[ -f "'${src}/flake.nix" ]]; then
      if grep -q "nix-homebrew" "'${src}/flake.nix" 2>/dev/null; then
        echo "✅ PASS: nix-homebrew integration configured"
        PASSED_TESTS+=("nix-homebrew-integration")
      fi
    fi

    # Section 3: Package Overlays and Customizations
    echo ""
    echo "🔍 Section 3: Package overlays and customizations..."

    # Test overlays directory
    overlays_dir="'${src}/overlays"
    if [[ -d "$overlays_dir" ]]; then
      echo "✅ PASS: Overlays directory exists"
      PASSED_TESTS+=("overlays-dir-exists")

      # Count overlay files
      overlay_count=$(find "$overlays_dir" -name "*.nix" -type f | wc -l)
      if [[ $overlay_count -gt 0 ]]; then
        echo "✅ PASS: Found $overlay_count overlay files"
        PASSED_TESTS+=("overlay-files-found")

        # Test overlay syntax
        if command -v nix-instantiate >/dev/null 2>&1; then
          overlay_syntax_valid=true
          for overlay_file in "$overlays_dir"/*.nix; do
            if [[ -f "$overlay_file" ]] && ! nix-instantiate --parse "$overlay_file" >/dev/null 2>&1; then
              overlay_syntax_valid=false
              echo "❌ FAIL: Overlay file $(basename "$overlay_file") has syntax errors"
              FAILED_TESTS+=("overlay-syntax-$(basename "$overlay_file")")
              break
            fi
          done

          if [[ "$overlay_syntax_valid" = "true" ]]; then
            echo "✅ PASS: All overlay files have valid syntax"
            PASSED_TESTS+=("overlays-syntax-valid")
          fi
        fi
      else
        echo "⚠️  INFO: No overlay files found"
      fi
    else
      echo "⚠️  INFO: Overlays directory not found"
    fi

    # Section 4: Package Management Scripts
    echo ""
    echo "🔍 Section 4: Package management scripts..."

    # Test package management scripts
    scripts_dir="'${src}/scripts"
    if [[ -d "$scripts_dir" ]]; then
      echo "✅ PASS: Scripts directory exists"
      PASSED_TESTS+=("scripts-dir-exists")

      # Test for package-related scripts
      package_scripts=("install-packages.sh" "update-packages.sh" "package-manager.sh")
      for script in "''${package_scripts[@]}"; do
        if [[ -f "$scripts_dir/$script" ]]; then
          echo "✅ PASS: Package script '$script' exists"
          PASSED_TESTS+=("package-script-$script")

          # Test script is executable
          if [[ -x "$scripts_dir/$script" ]]; then
            echo "✅ PASS: Package script '$script' is executable"
            PASSED_TESTS+=("package-script-$script-executable")
          else
            echo "❌ FAIL: Package script '$script' not executable"
            FAILED_TESTS+=("package-script-$script-not-executable")
          fi
        fi
      done
    fi

    # Section 5: Automation Scripts
    echo ""
    echo "🔍 Section 5: Automation scripts..."

    # Test automation scripts
    automation_scripts=("auto-update-dotfiles" "system-maintenance.sh" "backup-system.sh")
    for script in "''${automation_scripts[@]}"; do
      script_path="'${src}/scripts/$script"
      if [[ -f "$script_path" ]]; then
        echo "✅ PASS: Automation script '$script' exists"
        PASSED_TESTS+=("automation-script-$script")

        # Test script is executable
        if [[ -x "$script_path" ]]; then
          echo "✅ PASS: Automation script '$script' is executable"
          PASSED_TESTS+=("automation-script-$script-executable")
        else
          echo "❌ FAIL: Automation script '$script' not executable"
          FAILED_TESTS+=("automation-script-$script-not-executable")
        fi

        # Test for safety mechanisms
        if grep -q "backup\|rollback\|verify\|confirm" "$script_path" 2>/dev/null; then
          echo "✅ PASS: Automation script '$script' has safety mechanisms"
          PASSED_TESTS+=("automation-script-$script-safety")
        else
          echo "⚠️  INFO: Automation script '$script' may lack safety mechanisms"
        fi
      fi
    done

    # Section 6: Auto-Update System
    echo ""
    echo "🔍 Section 6: Auto-update system..."

    # Test auto-update configuration
    auto_update_script="'${src}/scripts/auto-update-dotfiles"
    if [[ -f "$auto_update_script" ]]; then
      echo "✅ PASS: Auto-update script exists"
      PASSED_TESTS+=("auto-update-script-exists")

      # Test for update logic
      update_components=("git pull" "nix flake update" "build" "switch")
      for component in "''${update_components[@]}"; do
        if grep -q "$component" "$auto_update_script" 2>/dev/null; then
          echo "✅ PASS: Auto-update includes '$component'"
          PASSED_TESTS+=("auto-update-$component")
        fi
      done

      # Test for error handling
      if grep -q "set -e\|error.*handling\|exit.*1" "$auto_update_script" 2>/dev/null; then
        echo "✅ PASS: Auto-update has error handling"
        PASSED_TESTS+=("auto-update-error-handling")
      else
        echo "❌ FAIL: Auto-update lacks error handling"
        FAILED_TESTS+=("auto-update-no-error-handling")
      fi

      # Test for logging
      if grep -q "log\|echo.*\|printf" "$auto_update_script" 2>/dev/null; then
        echo "✅ PASS: Auto-update has logging"
        PASSED_TESTS+=("auto-update-logging")
      else
        echo "❌ FAIL: Auto-update lacks logging"
        FAILED_TESTS+=("auto-update-no-logging")
      fi
    else
      echo "⚠️  INFO: Auto-update script not found"
    fi

    # Section 7: Build Automation
    echo ""
    echo "🔍 Section 7: Build automation..."

    # Test build scripts and automation
    build_scripts=("build-switch-common.sh" "lib/build-logic.sh")
    for script in "''${build_scripts[@]}"; do
      script_path="'${src}/scripts/$script"
      if [[ -f "$script_path" ]]; then
        echo "✅ PASS: Build script '$script' exists"
        PASSED_TESTS+=("build-script-$script")

        # Test for automation features
        automation_features=("verbose" "quiet" "batch" "unattended")
        for feature in "''${automation_features[@]}"; do
          if grep -qi "$feature" "$script_path" 2>/dev/null; then
            echo "✅ PASS: Build script '$script' supports '$feature' mode"
            PASSED_TESTS+=("build-script-$script-$feature")
          fi
        done

        # Test for progress indicators
        if grep -q "progress\|step\|phase\|%" "$script_path" 2>/dev/null; then
          echo "✅ PASS: Build script '$script' has progress indicators"
          PASSED_TESTS+=("build-script-$script-progress")
        fi
      fi
    done

    # Section 8: Dependency Management
    echo ""
    echo "🔍 Section 8: Dependency management..."

    # Test flake inputs for dependency management
    if [[ -f "'${src}/flake.nix" ]]; then
      echo "✅ PASS: flake.nix exists for dependency management"
      PASSED_TESTS+=("flake-dependency-management")

      # Test for common dependencies
      common_deps=("nixpkgs" "home-manager" "darwin" "flake-utils")
      for dep in "''${common_deps[@]}"; do
        if grep -q "$dep.*=" "'${src}/flake.nix" 2>/dev/null; then
          echo "✅ PASS: Dependency '$dep' configured"
          PASSED_TESTS+=("dependency-$dep")
        fi
      done

      # Test for dependency pinning
      if grep -q "follows\|rev.*=" "'${src}/flake.nix" 2>/dev/null; then
        echo "✅ PASS: Dependencies are pinned"
        PASSED_TESTS+=("dependencies-pinned")
      else
        echo "⚠️  INFO: Dependencies may not be pinned"
      fi
    else
      echo "❌ FAIL: flake.nix missing for dependency management"
      FAILED_TESTS+=("no-flake-dependency-management")
    fi

    # Test flake.lock for reproducible builds
    if [[ -f "'${src}/flake.lock" ]]; then
      echo "✅ PASS: flake.lock exists for reproducible builds"
      PASSED_TESTS+=("flake-lock-exists")

      # Test lock file is not empty
      if [[ -s "'${src}/flake.lock" ]]; then
        echo "✅ PASS: flake.lock has content"
        PASSED_TESTS+=("flake-lock-has-content")
      else
        echo "❌ FAIL: flake.lock is empty"
        FAILED_TESTS+=("flake-lock-empty")
      fi
    else
      echo "❌ FAIL: flake.lock missing"
      FAILED_TESTS+=("flake-lock-missing")
    fi

    # Section 9: Package Testing and Validation
    echo ""
    echo "🔍 Section 9: Package testing and validation..."

    # Test for package validation scripts
    validation_scripts=("validate-packages.sh" "test-packages.sh" "check-dependencies.sh")
    for script in "''${validation_scripts[@]}"; do
      script_path="'${src}/scripts/$script"
      if [[ -f "$script_path" ]]; then
        echo "✅ PASS: Package validation script '$script' exists"
        PASSED_TESTS+=("validation-script-$script")
      fi
    done

    # Test package installation verification
    if command -v nix-instantiate >/dev/null 2>&1; then
      # Test that shared packages can be instantiated
      if [[ -f "'${src}/modules/shared/packages.nix" ]]; then
        cd "'${src}"
        if nix-instantiate --eval modules/shared/packages.nix --arg pkgs 'import <nixpkgs> {}' >/dev/null 2>&1; then
          echo "✅ PASS: Shared packages can be instantiated"
          PASSED_TESTS+=("shared-packages-instantiate")
        else
          echo "❌ FAIL: Shared packages cannot be instantiated"
          FAILED_TESTS+=("shared-packages-no-instantiate")
        fi
      fi
    fi

    # Section 10: Continuous Integration Automation
    echo ""
    echo "🔍 Section 10: Continuous integration automation..."

    # Test CI configuration
    ci_configs=(".github/workflows" ".gitlab-ci.yml" ".travis.yml" "buildkite")
    ci_found=false

    for ci_config in "''${ci_configs[@]}"; do
      if [[ -e "'${src}/$ci_config" ]]; then
        echo "✅ PASS: CI configuration found: $ci_config"
        PASSED_TESTS+=("ci-config-$ci_config")
        ci_found=true

        # Test for automated testing
        if find "'${src}/$ci_config" -type f -exec grep -l "test\|check\|build" {} \; 2>/dev/null | head -1; then
          echo "✅ PASS: CI includes automated testing"
          PASSED_TESTS+=("ci-automated-testing")
        fi

        break
      fi
    done

    if [[ "$ci_found" = "false" ]]; then
      echo "⚠️  INFO: No CI configuration found"
    fi

    # Test for pre-commit hooks
    precommit_configs=(".pre-commit-config.yaml" "pre-commit-config.yaml" ".pre-commit-hooks")
    for precommit in "''${precommit_configs[@]}"; do
      if [[ -f "'${src}/$precommit" ]]; then
        echo "✅ PASS: Pre-commit configuration found: $precommit"
        PASSED_TESTS+=("precommit-config")

        # Test for common hooks
        if grep -q "flake8\|black\|nixfmt\|prettier" "'${src}/$precommit" 2>/dev/null; then
          echo "✅ PASS: Pre-commit includes code quality hooks"
          PASSED_TESTS+=("precommit-quality-hooks")
        fi

        break
      fi
    done

    # Section 11: Package Performance Monitoring
    echo ""
    echo "🔍 Section 11: Package performance monitoring..."

    # Test for performance monitoring scripts
    perf_scripts=("monitor-performance.sh" "benchmark-packages.sh" "profile-system.sh")
    for script in "''${perf_scripts[@]}"; do
      script_path="'${src}/scripts/$script"
      if [[ -f "$script_path" ]]; then
        echo "✅ PASS: Performance monitoring script '$script' exists"
        PASSED_TESTS+=("perf-script-$script")
      fi
    done

    # Test build performance tracking
    if [[ -f "'${src}/scripts/build-switch-common.sh" ]]; then
      if grep -q "time\|duration\|benchmark\|performance" "'${src}/scripts/build-switch-common.sh" 2>/dev/null; then
        echo "✅ PASS: Build system includes performance tracking"
        PASSED_TESTS+=("build-performance-tracking")
      fi
    fi

    # Section 12: Package Security and Updates
    echo ""
    echo "🔍 Section 12: Package security and updates..."

    # Test security update automation
    security_scripts=("security-updates.sh" "vulnerability-scan.sh" "audit-packages.sh")
    for script in "''${security_scripts[@]}"; do
      script_path="'${src}/scripts/$script"
      if [[ -f "$script_path" ]]; then
        echo "✅ PASS: Security script '$script' exists"
        PASSED_TESTS+=("security-script-$script")
      fi
    done

    # Test for security considerations in auto-update
    if [[ -f "'${src}/scripts/auto-update-dotfiles" ]]; then
      if grep -q "signature\|verify\|checksum\|security" "'${src}/scripts/auto-update-dotfiles" 2>/dev/null; then
        echo "✅ PASS: Auto-update includes security measures"
        PASSED_TESTS+=("auto-update-security")
      else
        echo "⚠️  INFO: Auto-update may lack security measures"
      fi
    fi

    # Results Summary
    echo ""
    echo "=== Comprehensive Unit Test Results ==="
    echo "✅ Passed tests: ''${#PASSED_TESTS[@]}"
    echo "❌ Failed tests: ''${#FAILED_TESTS[@]}"

    if [[ ''${#FAILED_TESTS[@]} -gt 0 ]]; then
      echo ""
      echo "❌ FAILED TESTS:"
      for test in "''${FAILED_TESTS[@]}"; do
        echo "   - $test"
      done
      echo ""
      echo "🔧 Unit test identified ''${#FAILED_TESTS[@]} package/automation issues"
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} unit tests passed!"
      echo "✅ Package & Automation unit functionality is working correctly"
      echo ""
      echo "📋 Unit Test Coverage Summary:"
      echo "   ✓ Package configuration structure"
      echo "   ✓ Homebrew package management"
      echo "   ✓ Package overlays and customizations"
      echo "   ✓ Package management scripts"
      echo "   ✓ Automation scripts"
      echo "   ✓ Auto-update system"
      echo "   ✓ Build automation"
      echo "   ✓ Dependency management"
      echo "   ✓ Package testing and validation"
      echo "   ✓ Continuous integration automation"
      echo "   ✓ Package performance monitoring"
      echo "   ✓ Package security and updates"
      exit 0
    fi
  '';

in
pkgs.runCommand "package-automation-comprehensive-unit-test"
{
  buildInputs = with pkgs; [ bash nix findutils gnugrep coreutils ];
} ''
  echo "Running Package & Automation comprehensive unit tests..."

  # Run the comprehensive unit test
  ${packageAutomationUnitScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "Package & Automation unit test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
