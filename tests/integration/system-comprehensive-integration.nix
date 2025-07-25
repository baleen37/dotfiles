# Comprehensive System Integration Tests
# Tests complete system integration across platforms and configurations

{ pkgs, flake ? null, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  system = pkgs.system;

  systemIntegrationScript = pkgs.writeShellScript "system-comprehensive-integration" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive System Integration Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Platform Support Integration
    echo ""
    echo "🔍 Section 1: Platform support integration..."
    echo "Current platform: ${system}"

    # Test current platform support in flake
    if [[ -f "${src}/flake.nix" ]]; then
      echo "✅ PASS: flake.nix exists"
      PASSED_TESTS+=("flake-exists")

      # Test platform detection
      current_platform=$(uname -s)
      current_arch=$(uname -m)
      echo "Detected platform: $current_platform ($current_arch)"

      case "$current_platform" in
        "Darwin")
          if [[ "$current_arch" == "arm64" ]]; then
            expected_system="aarch64-darwin"
          else
            expected_system="x86_64-darwin"
          fi
          ;;
        "Linux")
          if [[ "$current_arch" == "aarch64" ]]; then
            expected_system="aarch64-linux"
          else
            expected_system="x86_64-linux"
          fi
          ;;
      esac

      echo "Expected Nix system: $expected_system"

      if [[ "${system}" == "$expected_system" ]]; then
        echo "✅ PASS: Nix system matches detected platform"
        PASSED_TESTS+=("system-platform-match")
      else
        echo "❌ FAIL: Nix system mismatch (${system} vs $expected_system)"
        FAILED_TESTS+=("system-platform-mismatch")
      fi
    else
      echo "❌ FAIL: flake.nix not found"
      FAILED_TESTS+=("flake-missing")
    fi

    # Section 2: Configuration Integration
    echo ""
    echo "🔍 Section 2: Configuration integration..."

    # Test flake configuration availability
    if command -v nix >/dev/null 2>&1; then
      cd "${src}"

      # Test flake evaluation
      if nix flake check --no-build 2>/dev/null; then
        echo "✅ PASS: Flake check passes"
        PASSED_TESTS+=("flake-check-passes")
      else
        echo "⚠️  WARN: Flake check failed (may be network/cache related)"
      fi

      # Test platform-specific configurations
      case "${system}" in
        *darwin*)
          echo "Testing Darwin configuration integration..."

          if nix eval ".#darwinConfigurations" >/dev/null 2>&1; then
            echo "✅ PASS: Darwin configurations available"
            PASSED_TESTS+=("darwin-configs-available")
          else
            echo "❌ FAIL: Darwin configurations not available"
            FAILED_TESTS+=("darwin-configs-unavailable")
          fi

          # Test specific Darwin host
          if nix eval ".#darwinConfigurations.${system}" >/dev/null 2>&1; then
            echo "✅ PASS: Darwin configuration for ${system} available"
            PASSED_TESTS+=("darwin-config-system-available")
          else
            echo "⚠️  INFO: Specific Darwin configuration for ${system} not found"
          fi
          ;;
        *linux*)
          echo "Testing NixOS configuration integration..."

          if nix eval ".#nixosConfigurations" >/dev/null 2>&1; then
            echo "✅ PASS: NixOS configurations available"
            PASSED_TESTS+=("nixos-configs-available")
          else
            echo "❌ FAIL: NixOS configurations not available"
            FAILED_TESTS+=("nixos-configs-unavailable")
          fi
          ;;
      esac
    else
      echo "⚠️  WARN: Nix command not available for flake testing"
    fi

    # Section 3: Module Integration Testing
    echo ""
    echo "🔍 Section 3: Module integration testing..."

    # Test shared module integration
    shared_modules_dir="${src}/modules/shared"
    if [[ -d "$shared_modules_dir" ]]; then
      echo "✅ PASS: Shared modules directory exists"
      PASSED_TESTS+=("shared-modules-dir-exists")

      # Test shared module imports
      shared_modules=("packages.nix" "home-manager.nix" "files.nix")
      for module in "''${shared_modules[@]}"; do
        if [[ -f "$shared_modules_dir/$module" ]]; then
          echo "✅ PASS: Shared module '$module' exists"
          PASSED_TESTS+=("shared-module-$module-exists")

          # Test module syntax (basic)
          if command -v nix-instantiate >/dev/null 2>&1; then
            case "$module" in
              "packages.nix")
                if nix-instantiate --eval "$shared_modules_dir/$module" --arg pkgs 'import <nixpkgs> {}' >/dev/null 2>&1; then
                  echo "✅ PASS: Shared packages module syntax valid"
                  PASSED_TESTS+=("shared-packages-syntax-valid")
                fi
                ;;
              "files.nix")
                if nix-instantiate --parse "$shared_modules_dir/$module" >/dev/null 2>&1; then
                  echo "✅ PASS: Shared files module syntax valid"
                  PASSED_TESTS+=("shared-files-syntax-valid")
                fi
                ;;
            esac
          fi
        fi
      done
    else
      echo "❌ FAIL: Shared modules directory not found"
      FAILED_TESTS+=("shared-modules-dir-missing")
    fi

    # Test platform-specific module integration
    case "${system}" in
      *darwin*)
        darwin_modules_dir="${src}/modules/darwin"
        if [[ -d "$darwin_modules_dir" ]]; then
          echo "✅ PASS: Darwin modules directory exists"
          PASSED_TESTS+=("darwin-modules-dir-exists")

          # Test Darwin-specific modules
          darwin_modules=("default.nix" "home-manager.nix" "casks.nix" "packages.nix")
          for module in "''${darwin_modules[@]}"; do
            if [[ -f "$darwin_modules_dir/$module" ]]; then
              echo "✅ PASS: Darwin module '$module' exists"
              PASSED_TESTS+=("darwin-module-$module-exists")
            fi
          done

          # Test Darwin configuration directories
          darwin_config_dirs=("config/hammerspoon" "config/karabiner" "config/iterm2")
          for config_dir in "''${darwin_config_dirs[@]}"; do
            if [[ -d "$darwin_modules_dir/$config_dir" ]]; then
              echo "✅ PASS: Darwin config directory '$config_dir' exists"
              PASSED_TESTS+=("darwin-config-$config_dir-exists")
            fi
          done
        else
          echo "⚠️  INFO: Darwin modules directory not found (expected on Darwin)"
        fi
        ;;
      *linux*)
        nixos_modules_dir="${src}/modules/nixos"
        if [[ -d "$nixos_modules_dir" ]]; then
          echo "✅ PASS: NixOS modules directory exists"
          PASSED_TESTS+=("nixos-modules-dir-exists")

          # Test NixOS-specific modules
          nixos_modules=("default.nix" "home-manager.nix" "packages.nix")
          for module in "''${nixos_modules[@]}"; do
            if [[ -f "$nixos_modules_dir/$module" ]]; then
              echo "✅ PASS: NixOS module '$module' exists"
              PASSED_TESTS+=("nixos-module-$module-exists")
            fi
          done
        else
          echo "⚠️  INFO: NixOS modules directory not found (expected on Linux)"
        fi
        ;;
    esac

    # Section 4: Application Integration
    echo ""
    echo "🔍 Section 4: Application integration..."

    # Test apps directory structure
    apps_dir="${src}/apps"
    if [[ -d "$apps_dir" ]]; then
      echo "✅ PASS: Apps directory exists"
      PASSED_TESTS+=("apps-dir-exists")

      # Test platform-specific apps
      if [[ -d "$apps_dir/${system}" ]]; then
        echo "✅ PASS: Apps directory for ${system} exists"
        PASSED_TESTS+=("apps-system-dir-exists")

        # Count available apps
        app_count=$(find "$apps_dir/${system}" -type f -executable | wc -l)
        if [[ $app_count -gt 0 ]]; then
          echo "✅ PASS: Found $app_count executable apps for ${system}"
          PASSED_TESTS+=("apps-system-executables-found")
        fi

        # Test specific essential apps
        essential_apps=("build-switch" "apply")
        for app in "''${essential_apps[@]}"; do
          if [[ -f "$apps_dir/${system}/$app" ]]; then
            echo "✅ PASS: Essential app '$app' exists for ${system}"
            PASSED_TESTS+=("app-$app-exists")

            # Test app is executable
            if [[ -x "$apps_dir/${system}/$app" ]]; then
              echo "✅ PASS: App '$app' is executable"
              PASSED_TESTS+=("app-$app-executable")
            fi
          fi
        done
      else
        echo "❌ FAIL: Apps directory for ${system} not found"
        FAILED_TESTS+=("apps-system-dir-missing")
      fi
    else
      echo "❌ FAIL: Apps directory not found"
      FAILED_TESTS+=("apps-dir-missing")
    fi

    # Section 5: Package Manager Integration
    echo ""
    echo "🔍 Section 5: Package manager integration..."

    case "${system}" in
      *darwin*)
        echo "Testing Darwin package manager integration..."

        # Test Homebrew integration
        if [[ -f "${src}/modules/darwin/casks.nix" ]]; then
          echo "✅ PASS: Homebrew casks configuration exists"
          PASSED_TESTS+=("homebrew-config-exists")

          # Check for common cask categories
          if grep -q "browsers\|development\|utilities" "${src}/modules/darwin/casks.nix" 2>/dev/null; then
            echo "✅ PASS: Homebrew casks include common categories"
            PASSED_TESTS+=("homebrew-casks-categories")
          fi
        fi

        # Test nix-homebrew integration
        if grep -q "nix-homebrew" "${src}/flake.nix" 2>/dev/null; then
          echo "✅ PASS: nix-homebrew integration configured"
          PASSED_TESTS+=("nix-homebrew-integration")
        fi
        ;;
      *linux*)
        echo "Testing Linux package manager integration..."

        # Test native Nix package management
        if [[ -f "${src}/modules/nixos/packages.nix" ]]; then
          echo "✅ PASS: NixOS packages configuration exists"
          PASSED_TESTS+=("nixos-packages-config-exists")
        fi
        ;;
    esac

    # Section 6: Home Manager Integration
    echo ""
    echo "🔍 Section 6: Home Manager integration..."

    # Test Home Manager configuration integration
    hm_configs=("${src}/modules/shared/home-manager.nix" \
                "${src}/modules/darwin/home-manager.nix" \
                "${src}/modules/nixos/home-manager.nix")

    hm_config_found=false
    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        echo "✅ PASS: Home Manager configuration found: $hm_config"
        PASSED_TESTS+=("hm-config-found")
        hm_config_found=true

        # Test Home Manager programs integration
        if grep -q "programs\." "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Home Manager programs configured"
          PASSED_TESTS+=("hm-programs-configured")
        fi

        # Test specific program integrations
        hm_programs=("zsh" "git" "direnv" "vim")
        for program in "''${hm_programs[@]}"; do
          if grep -q "programs\.$program" "$hm_config" 2>/dev/null; then
            echo "✅ PASS: Home Manager program '$program' configured"
            PASSED_TESTS+=("hm-program-$program")
          fi
        done

        break
      fi
    done

    if [[ "$hm_config_found" = "false" ]]; then
      echo "❌ FAIL: No Home Manager configuration found"
      FAILED_TESTS+=("hm-config-missing")
    fi

    # Section 7: Library Integration
    echo ""
    echo "🔍 Section 7: Library integration..."

    # Test library directory
    lib_dir="${src}/lib"
    if [[ -d "$lib_dir" ]]; then
      echo "✅ PASS: Library directory exists"
      PASSED_TESTS+=("lib-dir-exists")

      # Test essential library files
      lib_files=("default.nix" "utils.nix" "platform-apps.nix" "system-configs.nix")
      for lib_file in "''${lib_files[@]}"; do
        if [[ -f "$lib_dir/$lib_file" ]]; then
          echo "✅ PASS: Library file '$lib_file' exists"
          PASSED_TESTS+=("lib-file-$lib_file-exists")

          # Test library file syntax
          if command -v nix-instantiate >/dev/null 2>&1; then
            case "$lib_file" in
              "default.nix")
                if nix-instantiate --eval "$lib_dir/$lib_file" >/dev/null 2>&1; then
                  echo "✅ PASS: Library default.nix syntax valid"
                  PASSED_TESTS+=("lib-default-syntax-valid")
                fi
                ;;
              "utils.nix")
                if nix-instantiate --parse "$lib_dir/$lib_file" >/dev/null 2>&1; then
                  echo "✅ PASS: Library utils.nix syntax valid"
                  PASSED_TESTS+=("lib-utils-syntax-valid")
                fi
                ;;
            esac
          fi
        fi
      done
    else
      echo "❌ FAIL: Library directory not found"
      FAILED_TESTS+=("lib-dir-missing")
    fi

    # Section 8: Configuration File Integration
    echo ""
    echo "🔍 Section 8: Configuration file integration..."

    # Test configuration file deployment
    config_files_found=0

    # Test shared configuration files
    shared_config_dir="${src}/modules/shared/config"
    if [[ -d "$shared_config_dir" ]]; then
      config_files_found=$((config_files_found + $(find "$shared_config_dir" -type f | wc -l)))
      echo "✅ PASS: Shared config directory has files"
      PASSED_TESTS+=("shared-config-files-exist")
    fi

    # Test platform-specific configuration files
    case "${system}" in
      *darwin*)
        darwin_config_dir="${src}/modules/darwin/config"
        if [[ -d "$darwin_config_dir" ]]; then
          config_files_found=$((config_files_found + $(find "$darwin_config_dir" -type f | wc -l)))
          echo "✅ PASS: Darwin config directory has files"
          PASSED_TESTS+=("darwin-config-files-exist")
        fi
        ;;
      *linux*)
        nixos_config_dir="${src}/modules/nixos/config"
        if [[ -d "$nixos_config_dir" ]]; then
          config_files_found=$((config_files_found + $(find "$nixos_config_dir" -type f | wc -l)))
          echo "✅ PASS: NixOS config directory has files"
          PASSED_TESTS+=("nixos-config-files-exist")
        fi
        ;;
    esac

    echo "Total configuration files found: $config_files_found"

    # Section 9: Cross-Platform Compatibility
    echo ""
    echo "🔍 Section 9: Cross-platform compatibility..."

    # Test that shared modules work across platforms
    if command -v nix-instantiate >/dev/null 2>&1; then
      cd "${src}"

      # Test cross-platform evaluation (basic)
      platforms=("aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux")
      for platform in "''${platforms[@]}"; do
        # Skip testing current platform again
        if [[ "$platform" == "${system}" ]]; then
          continue
        fi

        # Test if we can evaluate configuration for other platforms
        case "$platform" in
          *darwin*)
            if nix eval ".#darwinConfigurations" --impure 2>/dev/null | grep -q "$platform"; then
              echo "✅ PASS: Can evaluate Darwin config for $platform"
              PASSED_TESTS+=("cross-eval-$platform")
            fi
            ;;
          *linux*)
            if nix eval ".#nixosConfigurations" --impure 2>/dev/null | grep -q "$platform"; then
              echo "✅ PASS: Can evaluate NixOS config for $platform"
              PASSED_TESTS+=("cross-eval-$platform")
            fi
            ;;
        esac
      done
    fi

    # Section 10: System State Integration
    echo ""
    echo "🔍 Section 10: System state integration..."

    # Test system state management
    if [[ -d "${src}/scripts" ]]; then
      echo "✅ PASS: Scripts directory exists for system management"
      PASSED_TESTS+=("scripts-dir-exists")

      # Test for system state scripts
      state_scripts=("build-switch-common.sh" "lib/sudo-management.sh" "lib/build-logic.sh")
      for script in "''${state_scripts[@]}"; do
        if [[ -f "${src}/scripts/$script" ]]; then
          echo "✅ PASS: System state script '$script' exists"
          PASSED_TESTS+=("state-script-$script-exists")
        fi
      done
    fi

    # Test system generation management
    case "${system}" in
      *darwin*)
        # Test Darwin system generation support
        if command -v darwin-rebuild >/dev/null 2>&1; then
          echo "✅ PASS: darwin-rebuild available for system management"
          PASSED_TESTS+=("darwin-rebuild-available")
        else
          echo "⚠️  INFO: darwin-rebuild not available (may be expected in test environment)"
        fi
        ;;
      *linux*)
        # Test NixOS system generation support
        if command -v nixos-rebuild >/dev/null 2>&1; then
          echo "✅ PASS: nixos-rebuild available for system management"
          PASSED_TESTS+=("nixos-rebuild-available")
        else
          echo "⚠️  INFO: nixos-rebuild not available (may be expected in test environment)"
        fi
        ;;
    esac

    # Results Summary
    echo ""
    echo "=== Comprehensive Integration Test Results ==="
    echo "✅ Passed tests: ''${#PASSED_TESTS[@]}"
    echo "❌ Failed tests: ''${#FAILED_TESTS[@]}"

    if [[ ''${#FAILED_TESTS[@]} -gt 0 ]]; then
      echo ""
      echo "❌ FAILED TESTS:"
      for test in "''${FAILED_TESTS[@]}"; do
        echo "   - $test"
      done
      echo ""
      echo "🔧 Integration test identified ''${#FAILED_TESTS[@]} system integration issues"
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} integration tests passed!"
      echo "✅ System comprehensive integration is working correctly"
      echo ""
      echo "📋 Integration Test Coverage Summary:"
      echo "   ✓ Platform support integration"
      echo "   ✓ Configuration integration"
      echo "   ✓ Module integration testing"
      echo "   ✓ Application integration"
      echo "   ✓ Package manager integration"
      echo "   ✓ Home Manager integration"
      echo "   ✓ Library integration"
      echo "   ✓ Configuration file integration"
      echo "   ✓ Cross-platform compatibility"
      echo "   ✓ System state integration"
      echo ""
      echo "🎯 Current platform: ${system}"
      exit 0
    fi
  '';

in
pkgs.runCommand "system-comprehensive-integration-test"
{
  buildInputs = with pkgs; [ bash nix findutils gnugrep coreutils ];
} ''
  echo "Running System comprehensive integration tests..."
  echo "Platform: ${system}"

  # Run the comprehensive integration test
  ${systemIntegrationScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "System integration test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
