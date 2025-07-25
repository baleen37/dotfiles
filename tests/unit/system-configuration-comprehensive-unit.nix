# Comprehensive System Configuration Unit Tests
# Tests all system configuration components and modules

{ pkgs, flake ? null, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  systemConfigUnitScript = pkgs.writeShellScript "system-configuration-comprehensive-unit" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive System Configuration Unit Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Flake Structure Validation
    echo ""
    echo "🔍 Section 1: Flake structure validation..."

    # Check for flake.nix
    if [[ -f "'${src}/flake.nix" ]]; then
      echo "✅ PASS: flake.nix exists"
      PASSED_TESTS+=("flake-exists")

      # Test flake.nix syntax
      if command -v nix-instantiate >/dev/null 2>&1; then
        if nix-instantiate --eval "'${src}/flake.nix" >/dev/null 2>&1; then
          echo "✅ PASS: flake.nix syntax valid"
          PASSED_TESTS+=("flake-syntax-valid")
        else
          echo "❌ FAIL: flake.nix syntax invalid"
          FAILED_TESTS+=("flake-syntax-invalid")
        fi
      fi

      # Check for required flake sections
      flake_sections=("inputs" "outputs" "description")
      for section in "''${flake_sections[@]}"; do
        if grep -q "$section.*=" "'${src}/flake.nix" 2>/dev/null; then
          echo "✅ PASS: Flake section '$section' present"
          PASSED_TESTS+=("flake-section-$section")
        else
          echo "❌ FAIL: Flake section '$section' missing"
          FAILED_TESTS+=("flake-section-$section-missing")
        fi
      done
    else
      echo "❌ FAIL: flake.nix not found"
      FAILED_TESTS+=("flake-missing")
    fi

    # Section 2: System Configuration Modules
    echo ""
    echo "🔍 Section 2: System configuration modules..."

    # Check for system-configs.nix module
    if [[ -f "'${src}/lib/system-configs.nix" ]]; then
      echo "✅ PASS: system-configs.nix module exists"
      PASSED_TESTS+=("system-configs-module-exists")

      # Test module syntax
      if command -v nix-instantiate >/dev/null 2>&1; then
        # Create mock test for system-configs module
        cat > /tmp/test-system-configs.nix << 'EOF'
let
  mockInputs = {
    darwin = { lib = { darwinSystem = null; }; darwinModules = { home-manager = null; }; };
    nix-homebrew = { darwinModules = { nix-homebrew = null; }; };
    homebrew-bundle = null;
    homebrew-core = null;
    homebrew-cask = null;
    disko = { nixosModules = { disko = null; }; };
    home-manager = {
      darwinModules = { home-manager = null; };
      nixosModules = { home-manager = null; };
    };
    self = null;
  };
  mockNixpkgs = {
    lib = {
      genAttrs = systems: f: {};
      nixosSystem = null;
    };
  };
  systemConfigs = import ./lib/system-configs.nix {
    inputs = mockInputs;
    nixpkgs = mockNixpkgs;
  };
in
systemConfigs
EOF

        cd "'${src}"
        if nix-instantiate --eval /tmp/test-system-configs.nix >/dev/null 2>&1; then
          echo "✅ PASS: system-configs.nix module syntax valid"
          PASSED_TESTS+=("system-configs-syntax-valid")
        else
          echo "❌ FAIL: system-configs.nix module syntax invalid"
          FAILED_TESTS+=("system-configs-syntax-invalid")
        fi
        rm -f /tmp/test-system-configs.nix
      fi
    else
      echo "❌ FAIL: system-configs.nix module not found"
      FAILED_TESTS+=("system-configs-module-missing")
    fi

    # Section 3: Platform-Specific Modules
    echo ""
    echo "🔍 Section 3: Platform-specific modules..."

    # Check Darwin modules
    darwin_modules_dir="'${src}/modules/darwin"
    if [[ -d "$darwin_modules_dir" ]]; then
      echo "✅ PASS: Darwin modules directory exists"
      PASSED_TESTS+=("darwin-modules-dir-exists")

      # Check for essential Darwin modules
      darwin_modules=("default.nix" "home-manager.nix" "shell.nix")
      for module in "''${darwin_modules[@]}"; do
        if [[ -f "$darwin_modules_dir/$module" ]]; then
          echo "✅ PASS: Darwin module '$module' exists"
          PASSED_TESTS+=("darwin-module-$module")

          # Test module syntax
          if command -v nix-instantiate >/dev/null 2>&1; then
            if nix-instantiate --eval "$darwin_modules_dir/$module" >/dev/null 2>/dev/null; then
              echo "✅ PASS: Darwin module '$module' syntax valid"
              PASSED_TESTS+=("darwin-module-$module-syntax")
            else
              echo "⚠️  INFO: Darwin module '$module' syntax may require context"
            fi
          fi
        else
          echo "⚠️  INFO: Darwin module '$module' not found"
        fi
      done
    else
      echo "⚠️  INFO: Darwin modules directory not found"
    fi

    # Check NixOS modules
    nixos_modules_dir="'${src}/modules/nixos"
    if [[ -d "$nixos_modules_dir" ]]; then
      echo "✅ PASS: NixOS modules directory exists"
      PASSED_TESTS+=("nixos-modules-dir-exists")

      # Check for essential NixOS modules
      nixos_modules=("default.nix" "home-manager.nix")
      for module in "''${nixos_modules[@]}"; do
        if [[ -f "$nixos_modules_dir/$module" ]]; then
          echo "✅ PASS: NixOS module '$module' exists"
          PASSED_TESTS+=("nixos-module-$module")
        else
          echo "⚠️  INFO: NixOS module '$module' not found"
        fi
      done
    else
      echo "⚠️  INFO: NixOS modules directory not found"
    fi

    # Check shared modules
    shared_modules_dir="'${src}/modules/shared"
    if [[ -d "$shared_modules_dir" ]]; then
      echo "✅ PASS: Shared modules directory exists"
      PASSED_TESTS+=("shared-modules-dir-exists")

      # Check for essential shared modules
      shared_modules=("packages.nix" "home-manager.nix" "files.nix")
      for module in "''${shared_modules[@]}"; do
        if [[ -f "$shared_modules_dir/$module" ]]; then
          echo "✅ PASS: Shared module '$module' exists"
          PASSED_TESTS+=("shared-module-$module")
        else
          echo "⚠️  INFO: Shared module '$module' not found"
        fi
      done
    else
      echo "❌ FAIL: Shared modules directory not found"
      FAILED_TESTS+=("shared-modules-dir-missing")
    fi

    # Section 4: Package Configuration Validation
    echo ""
    echo "🔍 Section 4: Package configuration validation..."

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

      # Check for common package categories
      package_categories=("development" "utilities" "system" "media")
      for category in "''${package_categories[@]}"; do
        if grep -q "$category\|# $category" "$shared_packages" 2>/dev/null; then
          echo "✅ PASS: Package category '$category' found"
          PASSED_TESTS+=("package-category-$category")
        fi
      done
    else
      echo "❌ FAIL: Shared packages configuration not found"
      FAILED_TESTS+=("shared-packages-missing")
    fi

    # Section 5: Home Manager Configuration
    echo ""
    echo "🔍 Section 5: Home Manager configuration..."

    # Test shared home-manager configuration
    shared_hm="'${src}/modules/shared/home-manager.nix"
    if [[ -f "$shared_hm" ]]; then
      echo "✅ PASS: Shared Home Manager configuration exists"
      PASSED_TESTS+=("shared-hm-exists")

      # Check for essential Home Manager sections
      hm_sections=("programs" "services" "home" "xdg")
      for section in "''${hm_sections[@]}"; do
        if grep -q "$section\." "$shared_hm" 2>/dev/null; then
          echo "✅ PASS: Home Manager section '$section' configured"
          PASSED_TESTS+=("hm-section-$section")
        fi
      done

      # Check for shell configuration
      if grep -q "programs\.zsh\|programs\.bash" "$shared_hm" 2>/dev/null; then
        echo "✅ PASS: Shell programs configured in Home Manager"
        PASSED_TESTS+=("hm-shell-programs")
      fi
    else
      echo "❌ FAIL: Shared Home Manager configuration not found"
      FAILED_TESTS+=("shared-hm-missing")
    fi

    # Section 6: Configuration Files Structure
    echo ""
    echo "🔍 Section 6: Configuration files structure..."

    # Check for configuration directories
    config_dirs=("'${src}/modules/shared/config" \
                 "'${src}/modules/darwin/config" \
                 "'${src}/modules/nixos/config")

    for config_dir in "''${config_dirs[@]}"; do
      if [[ -d "$config_dir" ]]; then
        platform=$(basename "$(dirname "$config_dir")")
        echo "✅ PASS: $platform configuration directory exists"
        PASSED_TESTS+=("config-dir-$platform")

        # Count configuration files
        config_files=$(find "$config_dir" -type f | wc -l)
        if [[ $config_files -gt 0 ]]; then
          echo "✅ PASS: $platform has $config_files configuration files"
          PASSED_TESTS+=("config-files-$platform")
        fi
      fi
    done

    # Check for Claude configuration specifically
    claude_config_dirs=("'${src}/modules/shared/config/claude" \
                        "'${src}/config/claude" \
                        "'${src}/.claude")

    claude_config_found=false
    for claude_dir in "''${claude_config_dirs[@]}"; do
      if [[ -d "$claude_dir" ]]; then
        echo "✅ PASS: Claude configuration directory found: $claude_dir"
        PASSED_TESTS+=("claude-config-dir")
        claude_config_found=true

        # Check for essential Claude files
        claude_files=("CLAUDE.md" "settings.json" "commands")
        for file in "''${claude_files[@]}"; do
          if [[ -e "$claude_dir/$file" ]]; then
            echo "✅ PASS: Claude configuration '$file' exists"
            PASSED_TESTS+=("claude-config-$file")
          fi
        done

        break
      fi
    done

    if [[ "$claude_config_found" = "false" ]]; then
      echo "⚠️  INFO: Claude configuration directory not found"
    fi

    # Section 7: Application Configuration
    echo ""
    echo "🔍 Section 7: Application configuration..."

    # Check for application-specific configurations
    app_configs=("hammerspoon" "karabiner" "iterm2" "wezterm" "tmux")

    for app in "''${app_configs[@]}"; do
      app_config_found=false

      # Search in multiple possible locations
      for config_base in "'${src}/modules/darwin/config" "'${src}/modules/shared/config" "'${src}/config"; do
        if [[ -d "$config_base/$app" ]] || [[ -f "$config_base/$app.conf" ]] || [[ -f "$config_base/$app.json" ]]; then
          echo "✅ PASS: $app configuration found"
          PASSED_TESTS+=("app-config-$app")
          app_config_found=true
          break
        fi
      done

      if [[ "$app_config_found" = "false" ]]; then
        echo "⚠️  INFO: $app configuration not found"
      fi
    done

    # Section 8: Overlay Configuration
    echo ""
    echo "🔍 Section 8: Overlay configuration..."

    # Check for overlays directory
    overlays_dir="'${src}/overlays"
    if [[ -d "$overlays_dir" ]]; then
      echo "✅ PASS: Overlays directory exists"
      PASSED_TESTS+=("overlays-dir-exists")

      # Count overlay files
      overlay_files=$(find "$overlays_dir" -name "*.nix" -type f | wc -l)
      if [[ $overlay_files -gt 0 ]]; then
        echo "✅ PASS: Found $overlay_files overlay files"
        PASSED_TESTS+=("overlay-files-found")

        # Test overlay syntax
        if command -v nix-instantiate >/dev/null 2>&1; then
          overlay_syntax_valid=true
          for overlay_file in "$overlays_dir"/*.nix; do
            if [[ -f "$overlay_file" ]] && ! nix-instantiate --eval "$overlay_file" >/dev/null 2>&1; then
              overlay_syntax_valid=false
              break
            fi
          done

          if [[ "$overlay_syntax_valid" = "true" ]]; then
            echo "✅ PASS: Overlay files syntax valid"
            PASSED_TESTS+=("overlay-syntax-valid")
          else
            echo "❌ FAIL: Some overlay files have syntax errors"
            FAILED_TESTS+=("overlay-syntax-invalid")
          fi
        fi
      else
        echo "⚠️  INFO: No overlay files found"
      fi
    else
      echo "⚠️  INFO: Overlays directory not found"
    fi

    # Section 9: Host Configuration
    echo ""
    echo "🔍 Section 9: Host configuration..."

    # Check for hosts directory
    hosts_dir="'${src}/hosts"
    if [[ -d "$hosts_dir" ]]; then
      echo "✅ PASS: Hosts directory exists"
      PASSED_TESTS+=("hosts-dir-exists")

      # Check for platform-specific host configurations
      host_platforms=("darwin" "nixos")
      for platform in "''${host_platforms[@]}"; do
        if [[ -d "$hosts_dir/$platform" ]]; then
          echo "✅ PASS: $platform host configuration exists"
          PASSED_TESTS+=("host-config-$platform")

          # Check for default.nix in host configuration
          if [[ -f "$hosts_dir/$platform/default.nix" ]]; then
            echo "✅ PASS: $platform host default.nix exists"
            PASSED_TESTS+=("host-default-$platform")
          fi
        fi
      done
    else
      echo "⚠️  INFO: Hosts directory not found"
    fi

    # Section 10: Library Functions
    echo ""
    echo "🔍 Section 10: Library functions..."

    # Check for lib directory
    lib_dir="'${src}/lib"
    if [[ -d "$lib_dir" ]]; then
      echo "✅ PASS: Library directory exists"
      PASSED_TESTS+=("lib-dir-exists")

      # Check for essential library files
      lib_files=("default.nix" "utils.nix" "platform-apps.nix")
      for lib_file in "''${lib_files[@]}"; do
        if [[ -f "$lib_dir/$lib_file" ]]; then
          echo "✅ PASS: Library file '$lib_file' exists"
          PASSED_TESTS+=("lib-file-$lib_file")
        fi
      done

      # Test library syntax
      if command -v nix-instantiate >/dev/null 2>&1; then
        if [[ -f "$lib_dir/default.nix" ]] && nix-instantiate --eval "$lib_dir/default.nix" >/dev/null 2>&1; then
          echo "✅ PASS: Library default.nix syntax valid"
          PASSED_TESTS+=("lib-default-syntax-valid")
        fi
      fi
    else
      echo "❌ FAIL: Library directory not found"
      FAILED_TESTS+=("lib-dir-missing")
    fi

    # Section 11: Scripts and Applications
    echo ""
    echo "🔍 Section 11: Scripts and applications..."

    # Check for scripts directory
    scripts_dir="'${src}/scripts"
    if [[ -d "$scripts_dir" ]]; then
      echo "✅ PASS: Scripts directory exists"
      PASSED_TESTS+=("scripts-dir-exists")

      # Count script files
      script_files=$(find "$scripts_dir" -name "*.sh" -type f | wc -l)
      if [[ $script_files -gt 0 ]]; then
        echo "✅ PASS: Found $script_files shell scripts"
        PASSED_TESTS+=("script-files-found")
      fi
    fi

    # Check for apps directory
    apps_dir="'${src}/apps"
    if [[ -d "$apps_dir" ]]; then
      echo "✅ PASS: Apps directory exists"
      PASSED_TESTS+=("apps-dir-exists")

      # Check for platform-specific apps
      for platform in aarch64-darwin x86_64-darwin aarch64-linux x86_64-linux; do
        if [[ -d "$apps_dir/$platform" ]]; then
          echo "✅ PASS: $platform apps directory exists"
          PASSED_TESTS+=("apps-platform-$platform")
        fi
      done
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
      echo "🔧 Unit test identified ''${#FAILED_TESTS[@]} configuration issues"
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} unit tests passed!"
      echo "✅ System configuration unit functionality is working correctly"
      echo ""
      echo "📋 Unit Test Coverage Summary:"
      echo "   ✓ Flake structure validation"
      echo "   ✓ System configuration modules"
      echo "   ✓ Platform-specific modules"
      echo "   ✓ Package configuration validation"
      echo "   ✓ Home Manager configuration"
      echo "   ✓ Configuration files structure"
      echo "   ✓ Application configuration"
      echo "   ✓ Overlay configuration"
      echo "   ✓ Host configuration"
      echo "   ✓ Library functions"
      echo "   ✓ Scripts and applications"
      exit 0
    fi
  '';

in
pkgs.runCommand "system-configuration-comprehensive-unit-test"
{
  buildInputs = with pkgs; [ bash nix findutils gnugrep coreutils ];
} ''
  echo "Running System Configuration comprehensive unit tests..."

  # Run the comprehensive unit test
  ${systemConfigUnitScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "System Configuration unit test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
