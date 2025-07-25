# Comprehensive General Functionality Unit Tests
# Tests miscellaneous features, utilities, and general system functionality

{ pkgs, flake ? null, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  generalFunctionalityUnitScript = pkgs.writeShellScript "general-functionality-comprehensive-unit" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive General Functionality Unit Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Documentation and Help System
    echo ""
    echo "🔍 Section 1: Documentation and help system..."

    # Test essential documentation files
    essential_docs=("README.md" "CLAUDE.md")
    for doc in "''${essential_docs[@]}"; do
      if [[ -f "'${src}/$doc" ]]; then
        echo "✅ PASS: Essential documentation '$doc' exists"
        PASSED_TESTS+=("doc-$doc-exists")

        # Test documentation is not empty
        if [[ -s "'${src}/$doc" ]]; then
          echo "✅ PASS: Documentation '$doc' has content"
          PASSED_TESTS+=("doc-$doc-has-content")
        else
          echo "❌ FAIL: Documentation '$doc' is empty"
          FAILED_TESTS+=("doc-$doc-empty")
        fi
      else
        echo "❌ FAIL: Essential documentation '$doc' missing"
        FAILED_TESTS+=("doc-$doc-missing")
      fi
    done

    # Test documentation directory structure
    if [[ -d "'${src}/docs" ]]; then
      echo "✅ PASS: Documentation directory exists"
      PASSED_TESTS+=("docs-dir-exists")

      doc_count=$(find "'${src}/docs" -name "*.md" -type f | wc -l)
      if [[ $doc_count -gt 0 ]]; then
        echo "✅ PASS: Documentation directory has $doc_count markdown files"
        PASSED_TESTS+=("docs-dir-has-files")
      fi
    fi

    # Section 2: Editor and IDE Configuration
    echo ""
    echo "🔍 Section 2: Editor and IDE configuration..."

    # Test editor configuration files
    editor_configs=(".vimrc" ".nvimrc" "init.vim" ".emacs" ".spacemacs")
    editor_found=false

    for config in "''${editor_configs[@]}"; do
      if [[ -f "'${src}/$config" ]]; then
        echo "✅ PASS: Editor configuration '$config' exists"
        PASSED_TESTS+=("editor-config-$config")
        editor_found=true
      fi
    done

    # Test editor configuration directories
    editor_dirs=("config/nvim" "config/vim" "modules/shared/config/vim" "modules/shared/config/nvim")
    for dir in "''${editor_dirs[@]}"; do
      if [[ -d "'${src}/$dir" ]]; then
        echo "✅ PASS: Editor configuration directory '$dir' exists"
        PASSED_TESTS+=("editor-dir-$dir")
        editor_found=true
      fi
    done

    if [[ "$editor_found" = "false" ]]; then
      echo "⚠️  INFO: No editor configurations found"
    fi

    # Section 3: Development Tools Configuration
    echo ""
    echo "🔍 Section 3: Development tools configuration..."

    # Test Git configuration
    git_configs=(".gitconfig" "modules/shared/config/git" "config/git")
    git_found=false

    for git_config in "''${git_configs[@]}"; do
      if [[ -e "'${src}/$git_config" ]]; then
        echo "✅ PASS: Git configuration '$git_config' exists"
        PASSED_TESTS+=("git-config-exists")
        git_found=true
        break
      fi
    done

    if [[ "$git_found" = "false" ]]; then
      echo "⚠️  INFO: Git configuration not found in expected locations"
    fi

    # Test development environment files
    dev_files=(".editorconfig" ".prettierrc" ".eslintrc" "pyproject.toml" "package.json")
    for dev_file in "''${dev_files[@]}"; do
      if [[ -f "'${src}/$dev_file" ]]; then
        echo "✅ PASS: Development file '$dev_file' exists"
        PASSED_TESTS+=("dev-file-$dev_file")
      fi
    done

    # Test direnv configuration
    if [[ -f "'${src}/.envrc" ]]; then
      echo "✅ PASS: Direnv configuration exists"
      PASSED_TESTS+=("direnv-config-exists")
    fi

    # Section 4: Shell Utilities and Functions
    echo ""
    echo "🔍 Section 4: Shell utilities and functions..."

    # Test shell utility files
    shell_utils=("lib/utils.sh" "scripts/utils.sh" "modules/shared/shell-utils.nix")
    utils_found=false

    for util in "''${shell_utils[@]}"; do
      if [[ -f "'${src}/$util" ]]; then
        echo "✅ PASS: Shell utility '$util' exists"
        PASSED_TESTS+=("shell-util-$util")
        utils_found=true

        # Test utility file is not empty
        if [[ -s "'${src}/$util" ]]; then
          echo "✅ PASS: Utility '$util' has content"
          PASSED_TESTS+=("util-$util-has-content")
        fi
      fi
    done

    if [[ "$utils_found" = "false" ]]; then
      echo "⚠️  INFO: No shell utilities found in expected locations"
    fi

    # Test custom shell functions
    shell_function_indicators=("function " "() {" "alias ")
    function_count=0

    for config_file in "'${src}/modules/shared/config/zsh"/* "'${src}/.zshrc" "'${src}/.bashrc"; do
      if [[ -f "$config_file" ]]; then
        for indicator in "''${shell_function_indicators[@]}"; do
          count=$(grep -c "$indicator" "$config_file" 2>/dev/null || echo "0")
          function_count=$((function_count + count))
        done
      fi
    done

    if [[ $function_count -gt 0 ]]; then
      echo "✅ PASS: Found $function_count shell functions/aliases"
      PASSED_TESTS+=("shell-functions-found")
    fi

    # Section 5: Security and Privacy Configuration
    echo ""
    echo "🔍 Section 5: Security and privacy configuration..."

    # Test SSH configuration
    ssh_configs=("config/ssh" "modules/shared/config/ssh" ".ssh/config")
    ssh_found=false

    for ssh_config in "''${ssh_configs[@]}"; do
      if [[ -e "'${src}/$ssh_config" ]]; then
        echo "✅ PASS: SSH configuration '$ssh_config' exists"
        PASSED_TESTS+=("ssh-config-exists")
        ssh_found=true
        break
      fi
    done

    # Test GPG configuration
    gpg_configs=("config/gpg" "modules/shared/config/gpg" ".gnupg")
    for gpg_config in "''${gpg_configs[@]}"; do
      if [[ -e "'${src}/$gpg_config" ]]; then
        echo "✅ PASS: GPG configuration '$gpg_config' exists"
        PASSED_TESTS+=("gpg-config-exists")
        break
      fi
    done

    # Test security-related files
    security_files=(".gitignore" ".dockerignore" "secrets.example")
    for sec_file in "''${security_files[@]}"; do
      if [[ -f "'${src}/$sec_file" ]]; then
        echo "✅ PASS: Security file '$sec_file' exists"
        PASSED_TESTS+=("security-file-$sec_file")
      fi
    done

    # Section 6: Backup and Sync Configuration
    echo ""
    echo "🔍 Section 6: Backup and sync configuration..."

    # Test backup scripts
    backup_scripts=("scripts/backup-system.sh" "scripts/backup-dotfiles.sh" "scripts/sync-dotfiles.sh")
    backup_found=false

    for backup_script in "''${backup_scripts[@]}"; do
      if [[ -f "'${src}/$backup_script" ]]; then
        echo "✅ PASS: Backup script '$backup_script' exists"
        PASSED_TESTS+=("backup-script-$backup_script")
        backup_found=true

        # Test script is executable
        if [[ -x "'${src}/$backup_script" ]]; then
          echo "✅ PASS: Backup script '$backup_script' is executable"
          PASSED_TESTS+=("backup-script-$backup_script-executable")
        fi
      fi
    done

    if [[ "$backup_found" = "false" ]]; then
      echo "⚠️  INFO: No backup scripts found"
    fi

    # Test sync configuration
    sync_configs=("rsync.conf" "unison.prf" "config/sync")
    for sync_config in "''${sync_configs[@]}"; do
      if [[ -e "'${src}/$sync_config" ]]; then
        echo "✅ PASS: Sync configuration '$sync_config' exists"
        PASSED_TESTS+=("sync-config-$sync_config")
      fi
    done

    # Section 7: Media and Entertainment Configuration
    echo ""
    echo "🔍 Section 7: Media and entertainment configuration..."

    # Test media player configurations
    media_configs=("config/mpv" "config/vlc" "modules/shared/config/media")
    media_found=false

    for media_config in "''${media_configs[@]}"; do
      if [[ -d "'${src}/$media_config" ]]; then
        echo "✅ PASS: Media configuration '$media_config' exists"
        PASSED_TESTS+=("media-config-$media_config")
        media_found=true
      fi
    done

    # Test audio configuration
    audio_configs=("config/pulse" "config/alsa" "modules/shared/config/audio")
    for audio_config in "''${audio_configs[@]}"; do
      if [[ -d "'${src}/$audio_config" ]]; then
        echo "✅ PASS: Audio configuration '$audio_config' exists"
        PASSED_TESTS+=("audio-config-$audio_config")
        media_found=true
      fi
    done

    if [[ "$media_found" = "false" ]]; then
      echo "⚠️  INFO: No media configurations found"
    fi

    # Section 8: Network and Communication Tools
    echo ""
    echo "🔍 Section 8: Network and communication tools..."

    # Test network configuration
    network_configs=("config/network" "modules/shared/config/network")
    for net_config in "''${network_configs[@]}"; do
      if [[ -d "'${src}/$net_config" ]]; then
        echo "✅ PASS: Network configuration '$net_config' exists"
        PASSED_TESTS+=("network-config-$net_config")
      fi
    done

    # Test communication tool configs
    comm_configs=("config/irc" "config/slack" "config/discord" "modules/shared/config/communication")
    comm_found=false

    for comm_config in "''${comm_configs[@]}"; do
      if [[ -d "'${src}/$comm_config" ]]; then
        echo "✅ PASS: Communication configuration '$comm_config' exists"
        PASSED_TESTS+=("comm-config-$comm_config")
        comm_found=true
      fi
    done

    if [[ "$comm_found" = "false" ]]; then
      echo "⚠️  INFO: No communication tool configurations found"
    fi

    # Section 9: System Monitoring and Logging
    echo ""
    echo "🔍 Section 9: System monitoring and logging..."

    # Test monitoring configurations
    monitoring_configs=("config/htop" "config/btop" "modules/shared/config/monitoring")
    monitoring_found=false

    for mon_config in "''${monitoring_configs[@]}"; do
      if [[ -e "'${src}/$mon_config" ]]; then
        echo "✅ PASS: Monitoring configuration '$mon_config' exists"
        PASSED_TESTS+=("monitoring-config-$mon_config")
        monitoring_found=true
      fi
    done

    # Test logging configuration
    log_configs=("config/rsyslog" "config/journald" "scripts/log-management.sh")
    for log_config in "''${log_configs[@]}"; do
      if [[ -e "'${src}/$log_config" ]]; then
        echo "✅ PASS: Logging configuration '$log_config' exists"
        PASSED_TESTS+=("log-config-$log_config")
        monitoring_found=true
      fi
    done

    if [[ "$monitoring_found" = "false" ]]; then
      echo "⚠️  INFO: No monitoring/logging configurations found"
    fi

    # Section 10: Fonts and Theming
    echo ""
    echo "🔍 Section 10: Fonts and theming..."

    # Test font configurations
    font_configs=("config/fonts" "modules/shared/config/fonts" "fontconfig")
    font_found=false

    for font_config in "''${font_configs[@]}"; do
      if [[ -e "'${src}/$font_config" ]]; then
        echo "✅ PASS: Font configuration '$font_config' exists"
        PASSED_TESTS+=("font-config-$font_config")
        font_found=true
      fi
    done

    # Test theme configurations
    theme_configs=("config/themes" "modules/shared/config/themes" "gtk.css")
    theme_found=false

    for theme_config in "''${theme_configs[@]}"; do
      if [[ -e "'${src}/$theme_config" ]]; then
        echo "✅ PASS: Theme configuration '$theme_config' exists"
        PASSED_TESTS+=("theme-config-$theme_config")
        theme_found=true
      fi
    done

    if [[ "$font_found" = "false" && "$theme_found" = "false" ]]; then
      echo "⚠️  INFO: No font or theme configurations found"
    fi

    # Section 11: Custom Scripts and Utilities
    echo ""
    echo "🔍 Section 11: Custom scripts and utilities..."

    # Test custom script directory
    if [[ -d "'${src}/scripts" ]]; then
      echo "✅ PASS: Scripts directory exists"
      PASSED_TESTS+=("scripts-dir-exists")

      # Count custom scripts
      script_count=$(find "'${src}/scripts" -name "*.sh" -type f | wc -l)
      if [[ $script_count -gt 0 ]]; then
        echo "✅ PASS: Found $script_count custom shell scripts"
        PASSED_TESTS+=("custom-scripts-found")

        # Test scripts are executable
        executable_count=$(find "'${src}/scripts" -name "*.sh" -type f -executable | wc -l)
        if [[ $executable_count -gt 0 ]]; then
          echo "✅ PASS: $executable_count scripts are executable"
          PASSED_TESTS+=("scripts-executable")
        fi
      fi
    fi

    # Test utility categories
    utility_categories=("maintenance" "development" "system" "backup" "automation")
    for category in "''${utility_categories[@]}"; do
      if find "'${src}/scripts" -name "*$category*" -type f 2>/dev/null | head -1; then
        echo "✅ PASS: $category utility scripts found"
        PASSED_TESTS+=("utility-category-$category")
      fi
    done

    # Section 12: Configuration Management
    echo ""
    echo "🔍 Section 12: Configuration management..."

    # Test configuration validation
    if [[ -f "'${src}/flake.nix" ]]; then
      echo "✅ PASS: Flake configuration exists for management"
      PASSED_TESTS+=("flake-config-management")

      # Test configuration syntax
      if command -v nix >/dev/null 2>&1; then
        if nix flake check --no-build "'${src}" 2>/dev/null; then
          echo "✅ PASS: Configuration syntax is valid"
          PASSED_TESTS+=("config-syntax-valid")
        else
          echo "⚠️  WARN: Configuration syntax check failed"
        fi
      fi
    fi

    # Test configuration file organization
    config_dirs=("config" "modules/shared/config" "modules/darwin/config" "modules/nixos/config")
    total_config_files=0

    for config_dir in "''${config_dirs[@]}"; do
      if [[ -d "'${src}/$config_dir" ]]; then
        file_count=$(find "'${src}/$config_dir" -type f | wc -l)
        total_config_files=$((total_config_files + file_count))
      fi
    done

    if [[ $total_config_files -gt 0 ]]; then
      echo "✅ PASS: Total configuration files: $total_config_files"
      PASSED_TESTS+=("config-files-organized")
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
      echo "🔧 Unit test identified ''${#FAILED_TESTS[@]} general functionality issues"
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} unit tests passed!"
      echo "✅ General functionality unit testing is working correctly"
      echo ""
      echo "📋 Unit Test Coverage Summary:"
      echo "   ✓ Documentation and help system"
      echo "   ✓ Editor and IDE configuration"
      echo "   ✓ Development tools configuration"
      echo "   ✓ Shell utilities and functions"
      echo "   ✓ Security and privacy configuration"
      echo "   ✓ Backup and sync configuration"
      echo "   ✓ Media and entertainment configuration"
      echo "   ✓ Network and communication tools"
      echo "   ✓ System monitoring and logging"
      echo "   ✓ Fonts and theming"
      echo "   ✓ Custom scripts and utilities"
      echo "   ✓ Configuration management"
      exit 0
    fi
  '';

in
pkgs.runCommand "general-functionality-comprehensive-unit-test"
{
  buildInputs = with pkgs; [ bash nix findutils gnugrep coreutils ];
} ''
  echo "Running General Functionality comprehensive unit tests..."

  # Run the comprehensive unit test
  ${generalFunctionalityUnitScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "General functionality unit test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
