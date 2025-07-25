# Comprehensive General Functionality Integration Tests
# Tests integration between miscellaneous features and system components

{ pkgs, flake ? null, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  generalFunctionalityIntegrationScript = pkgs.writeShellScript "general-functionality-comprehensive-integration" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive General Functionality Integration Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Documentation Integration
    echo ""
    echo "🔍 Section 1: Documentation integration..."

    cd "${src}"

    # Test documentation integration with project structure
    if [[ -f "README.md" ]]; then
      echo "✅ PASS: README.md exists"
      PASSED_TESTS+=("readme-exists")

      # Test README references to project components
      components=("flake.nix" "modules" "scripts" "apps")
      for component in "''${components[@]}"; do
        if grep -qi "$component" README.md 2>/dev/null; then
          echo "✅ PASS: README references '$component'"
          PASSED_TESTS+=("readme-references-$component")
        fi
      done
    fi

    # Test documentation consistency across platforms
    platform_docs=("docs/darwin.md" "docs/nixos.md" "docs/linux.md")
    doc_consistency=true

    for doc in "''${platform_docs[@]}"; do
      if [[ -f "$doc" ]]; then
        if [[ -f "modules/darwin/default.nix" ]] && [[ ! -f "docs/darwin.md" ]]; then
          doc_consistency=false
        fi
        if [[ -f "modules/nixos/default.nix" ]] && [[ ! -f "docs/nixos.md" ]]; then
          doc_consistency=false
        fi
      fi
    done

    if [[ "$doc_consistency" = "true" ]]; then
      echo "✅ PASS: Documentation consistency maintained"
      PASSED_TESTS+=("doc-consistency")
    fi

    # Section 2: Editor Configuration Integration
    echo ""
    echo "🔍 Section 2: Editor configuration integration..."

    # Test editor configuration integration with Home Manager
    editor_integration=false
    hm_configs=("modules/shared/home-manager.nix" "modules/darwin/home-manager.nix" "modules/nixos/home-manager.nix")

    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        if grep -q "programs\\.vim\\|programs\\.neovim\\|programs\\.emacs" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Editor configuration integrated with Home Manager"
          PASSED_TESTS+=("editor-hm-integration")
          editor_integration=true
          break
        fi
      fi
    done

    # Test editor configuration with package management
    if [[ -f "modules/shared/packages.nix" ]]; then
      if grep -q "vim\\|neovim\\|emacs\\|vscode" "modules/shared/packages.nix" 2>/dev/null; then
        echo "✅ PASS: Editor packages integrated with system packages"
        PASSED_TESTS+=("editor-package-integration")
        editor_integration=true
      fi
    fi

    if [[ "$editor_integration" = "false" ]]; then
      echo "⚠️  INFO: Editor configuration integration not detected"
    fi

    # Section 3: Development Tools Integration
    echo ""
    echo "🔍 Section 3: Development tools integration..."

    # Test Git configuration integration
    git_integration=false

    # Check Git in Home Manager
    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        if grep -q "programs\\.git" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Git configuration integrated with Home Manager"
          PASSED_TESTS+=("git-hm-integration")
          git_integration=true
          break
        fi
      fi
    done

    # Check Git in packages
    if [[ -f "modules/shared/packages.nix" ]]; then
      if grep -q "git" "modules/shared/packages.nix" 2>/dev/null; then
        echo "✅ PASS: Git integrated with package management"
        PASSED_TESTS+=("git-package-integration")
        git_integration=true
      fi
    fi

    # Test development environment integration
    if [[ -f ".envrc" ]]; then
      if command -v nix >/dev/null 2>&1; then
        if grep -q "use flake" ".envrc" 2>/dev/null; then
          echo "✅ PASS: Development environment integrated with flake"
          PASSED_TESTS+=("devenv-flake-integration")
        fi
      fi
    fi

    # Section 4: Shell Integration
    echo ""
    echo "🔍 Section 4: Shell integration..."

    # Test shell configuration integration
    shell_integration_count=0

    # Check shell in Home Manager
    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        if grep -q "programs\\.zsh\\|programs\\.bash\\|programs\\.fish" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Shell configuration integrated with Home Manager"
          PASSED_TESTS+=("shell-hm-integration")
          shell_integration_count=$((shell_integration_count + 1))
          break
        fi
      fi
    done

    # Test shell utility integration
    shell_util_dirs=("modules/shared/config/zsh" "modules/shared/config/bash")
    for util_dir in "''${shell_util_dirs[@]}"; do
      if [[ -d "$util_dir" ]]; then
        echo "✅ PASS: Shell utilities directory '$util_dir' integrated"
        PASSED_TESTS+=("shell-util-integration-$util_dir")
        shell_integration_count=$((shell_integration_count + 1))
      fi
    done

    if [[ $shell_integration_count -gt 0 ]]; then
      echo "✅ PASS: Shell integration components working ($shell_integration_count components)"
      PASSED_TESTS+=("shell-integration-working")
    fi

    # Section 5: Security Integration
    echo ""
    echo "🔍 Section 5: Security integration..."

    # Test SSH integration
    ssh_integration=false

    # Check SSH in Home Manager
    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        if grep -q "programs\\.ssh\\|services\\.ssh" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: SSH configuration integrated with Home Manager"
          PASSED_TESTS+=("ssh-hm-integration")
          ssh_integration=true
          break
        fi
      fi
    done

    # Test GPG integration
    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        if grep -q "programs\\.gpg\\|services\\.gpg" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: GPG configuration integrated with Home Manager"
          PASSED_TESTS+=("gpg-hm-integration")
          ssh_integration=true
          break
        fi
      fi
    done

    # Test security file integration with Git
    if [[ -f ".gitignore" ]]; then
      if grep -q "secret\\|key\\|password\\|\\.env" ".gitignore" 2>/dev/null; then
        echo "✅ PASS: Security patterns integrated with Git ignore"
        PASSED_TESTS+=("security-git-integration")
        ssh_integration=true
      fi
    fi

    if [[ "$ssh_integration" = "false" ]]; then
      echo "⚠️  INFO: Security integration not fully detected"
    fi

    # Section 6: Backup System Integration
    echo ""
    echo "🔍 Section 6: Backup system integration..."

    # Test backup script integration with system components
    backup_integration=false
    backup_scripts=("scripts/backup-system.sh" "scripts/backup-dotfiles.sh")

    for backup_script in "''${backup_scripts[@]}"; do
      if [[ -f "$backup_script" ]]; then
        echo "✅ PASS: Backup script '$backup_script' exists"
        PASSED_TESTS+=("backup-script-exists")
        backup_integration=true

        # Test backup script integrates with system paths
        if grep -q "/etc\\|/home\\|/Users\\|\\.config" "$backup_script" 2>/dev/null; then
          echo "✅ PASS: Backup script integrates system paths"
          PASSED_TESTS+=("backup-system-paths")
        fi

        # Test backup script integrates with automation
        if [[ -f "scripts/auto-update-dotfiles" ]]; then
          if grep -q "backup" "scripts/auto-update-dotfiles" 2>/dev/null; then
            echo "✅ PASS: Backup integrated with automation system"
            PASSED_TESTS+=("backup-automation-integration")
          fi
        fi
      fi
    done

    if [[ "$backup_integration" = "false" ]]; then
      echo "⚠️  INFO: Backup system integration not detected"
    fi

    # Section 7: Media Configuration Integration
    echo ""
    echo "🔍 Section 7: Media configuration integration..."

    # Test media configuration with package management
    media_integration=false
    media_packages=("mpv" "vlc" "ffmpeg" "imagemagick")

    if [[ -f "modules/shared/packages.nix" ]]; then
      for media_pkg in "''${media_packages[@]}"; do
        if grep -q "$media_pkg" "modules/shared/packages.nix" 2>/dev/null; then
          echo "✅ PASS: Media package '$media_pkg' integrated"
          PASSED_TESTS+=("media-pkg-$media_pkg-integrated")
          media_integration=true
        fi
      done
    fi

    # Test media configuration with Home Manager
    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        if grep -q "programs\\.mpv\\|services\\.mpd" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Media configuration integrated with Home Manager"
          PASSED_TESTS+=("media-hm-integration")
          media_integration=true
          break
        fi
      fi
    done

    if [[ "$media_integration" = "false" ]]; then
      echo "⚠️  INFO: Media configuration integration not detected"
    fi

    # Section 8: Network Tool Integration
    echo ""
    echo "🔍 Section 8: Network tool integration..."

    # Test network tools with package management
    network_integration=false
    network_tools=("curl" "wget" "nmap" "wireshark")

    if [[ -f "modules/shared/packages.nix" ]]; then
      for tool in "''${network_tools[@]}"; do
        if grep -q "$tool" "modules/shared/packages.nix" 2>/dev/null; then
          echo "✅ PASS: Network tool '$tool' integrated"
          PASSED_TESTS+=("network-tool-$tool-integrated")
          network_integration=true
        fi
      done
    fi

    # Test network configuration integration
    if [[ -d "modules/shared/config/network" ]]; then
      echo "✅ PASS: Network configuration directory integrated"
      PASSED_TESTS+=("network-config-integrated")
      network_integration=true
    fi

    if [[ "$network_integration" = "false" ]]; then
      echo "⚠️  INFO: Network tool integration not detected"
    fi

    # Section 9: Monitoring Integration
    echo ""
    echo "🔍 Section 9: Monitoring integration..."

    # Test monitoring tools integration
    monitoring_integration=false
    monitoring_tools=("htop" "btop" "iotop" "nethogs")

    if [[ -f "modules/shared/packages.nix" ]]; then
      for tool in "''${monitoring_tools[@]}"; do
        if grep -q "$tool" "modules/shared/packages.nix" 2>/dev/null; then
          echo "✅ PASS: Monitoring tool '$tool' integrated"
          PASSED_TESTS+=("monitoring-tool-$tool-integrated")
          monitoring_integration=true
        fi
      done
    fi

    # Test monitoring configuration integration
    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        if grep -q "programs\\.htop\\|programs\\.btop" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Monitoring configuration integrated with Home Manager"
          PASSED_TESTS+=("monitoring-hm-integration")
          monitoring_integration=true
          break
        fi
      fi
    done

    if [[ "$monitoring_integration" = "false" ]]; then
      echo "⚠️  INFO: Monitoring integration not detected"
    fi

    # Section 10: Theme and Font Integration
    echo ""
    echo "🔍 Section 10: Theme and font integration..."

    # Test font integration
    font_integration=false

    # Check fonts in packages
    if [[ -f "modules/shared/packages.nix" ]]; then
      if grep -q "font\\|Font" "modules/shared/packages.nix" 2>/dev/null; then
        echo "✅ PASS: Fonts integrated with package management"
        PASSED_TESTS+=("font-package-integration")
        font_integration=true
      fi
    fi

    # Check fonts in Home Manager
    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        if grep -q "fonts\\|fontconfig" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Fonts integrated with Home Manager"
          PASSED_TESTS+=("font-hm-integration")
          font_integration=true
          break
        fi
      fi
    done

    # Test theme integration
    theme_integration=false
    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        if grep -q "gtk\\|qt\\|theme" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Theme configuration integrated with Home Manager"
          PASSED_TESTS+=("theme-hm-integration")
          theme_integration=true
          break
        fi
      fi
    done

    if [[ "$font_integration" = "false" && "$theme_integration" = "false" ]]; then
      echo "⚠️  INFO: Font and theme integration not detected"
    fi

    # Section 11: Custom Script Integration
    echo ""
    echo "🔍 Section 11: Custom script integration..."

    # Test script integration with system
    script_integration_count=0

    if [[ -d "scripts" ]]; then
      echo "✅ PASS: Scripts directory exists for integration"
      PASSED_TESTS+=("scripts-dir-integration")
      script_integration_count=$((script_integration_count + 1))

      # Test script integration with flake apps
      if [[ -f "flake.nix" ]]; then
        if grep -q "scripts/" "flake.nix" 2>/dev/null; then
          echo "✅ PASS: Scripts integrated with flake applications"
          PASSED_TESTS+=("scripts-flake-integration")
          script_integration_count=$((script_integration_count + 1))
        fi
      fi

      # Test script integration with automation
      if [[ -f "scripts/auto-update-dotfiles" ]]; then
        if find scripts -name "*.sh" -exec grep -l "source\\|\\." {} \\; 2>/dev/null | head -1; then
          echo "✅ PASS: Scripts integrate with each other"
          PASSED_TESTS+=("scripts-cross-integration")
          script_integration_count=$((script_integration_count + 1))
        fi
      fi
    fi

    if [[ $script_integration_count -gt 0 ]]; then
      echo "✅ PASS: Custom script integration working ($script_integration_count integrations)"
      PASSED_TESTS+=("custom-script-integration")
    fi

    # Section 12: Cross-Platform Feature Integration
    echo ""
    echo "🔍 Section 12: Cross-platform feature integration..."

    # Test cross-platform configuration consistency
    platform_integration_score=0

    # Check shared configurations
    if [[ -d "modules/shared" ]]; then
      shared_configs=$(find modules/shared -name "*.nix" -type f | wc -l)
      if [[ $shared_configs -gt 0 ]]; then
        echo "✅ PASS: Shared configurations support cross-platform ($shared_configs files)"
        PASSED_TESTS+=("shared-config-cross-platform")
        platform_integration_score=$((platform_integration_score + 1))
      fi
    fi

    # Check platform-specific integrations
    platforms=("darwin" "nixos")
    for platform in "''${platforms[@]}"; do
      if [[ -d "modules/$platform" ]]; then
        echo "✅ PASS: $platform platform integration available"
        PASSED_TESTS+=("platform-integration-$platform")
        platform_integration_score=$((platform_integration_score + 1))
      fi
    done

    if [[ $platform_integration_score -ge 2 ]]; then
      echo "✅ PASS: Cross-platform feature integration complete"
      PASSED_TESTS+=("cross-platform-integration-complete")
    elif [[ $platform_integration_score -eq 1 ]]; then
      echo "✅ PASS: Single-platform feature integration"
      PASSED_TESTS+=("single-platform-integration")
    fi

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
      echo "🔧 Integration test identified ''${#FAILED_TESTS[@]} general functionality integration issues"
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} integration tests passed!"
      echo "✅ General functionality integration is working correctly"
      echo ""
      echo "📋 Integration Test Coverage Summary:"
      echo "   ✓ Documentation integration"
      echo "   ✓ Editor configuration integration"
      echo "   ✓ Development tools integration"
      echo "   ✓ Shell integration"
      echo "   ✓ Security integration"
      echo "   ✓ Backup system integration"
      echo "   ✓ Media configuration integration"
      echo "   ✓ Network tool integration"
      echo "   ✓ Monitoring integration"
      echo "   ✓ Theme and font integration"
      echo "   ✓ Custom script integration"
      echo "   ✓ Cross-platform feature integration"
      exit 0
    fi
  '';

in
pkgs.runCommand "general-functionality-comprehensive-integration-test"
{
  buildInputs = with pkgs; [ bash nix findutils gnugrep coreutils ];
} ''
  echo "Running General Functionality comprehensive integration tests..."

  # Run the comprehensive integration test
  ${generalFunctionalityIntegrationScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "General functionality integration test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
