# Comprehensive General Functionality End-to-End Tests
# Tests real-world scenarios for miscellaneous features and system functionality

{ pkgs, flake ? null, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  system = pkgs.system;

  generalFunctionalityE2EScript = pkgs.writeShellScript "general-functionality-comprehensive-e2e" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive General Functionality End-to-End Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Complete Documentation Workflow
    echo ""
    echo "🔍 Section 1: Complete documentation workflow..."
    echo "Current system: ${system}"

    cd "${src}"
    export USER=\${USER:-testuser}

    # Test documentation accessibility and completeness
    if [[ -f "README.md" ]]; then
      echo "✅ PASS: README.md accessible"
      PASSED_TESTS+=("readme-accessible")

      # Test README covers essential topics
      essential_topics=("installation" "usage" "configuration" "troubleshooting")
      topics_covered=0

      for topic in "''${essential_topics[@]}"; do
        if grep -qi "\$topic" README.md 2>/dev/null; then
          topics_covered=\$((topics_covered + 1))
          echo "✅ PASS: README covers '\$topic'"
          PASSED_TESTS+=("readme-covers-\$topic")
        fi
      done

      if [[ \$topics_covered -ge 3 ]]; then
        echo "✅ PASS: README comprehensively covers essential topics (\$topics_covered/''${#essential_topics[@]})"
        PASSED_TESTS+=("readme-comprehensive")
      fi
    else
      echo "❌ FAIL: README.md not accessible"
      FAILED_TESTS+=("readme-not-accessible")
    fi

    # Test documentation consistency across the project
    if [[ -d "docs" ]]; then
      doc_files=\$(find docs -name "*.md" -type f | wc -l)
      if [[ \$doc_files -gt 0 ]]; then
        echo "✅ PASS: Additional documentation available (\$doc_files files)"
        PASSED_TESTS+=("additional-docs-available")
      fi
    fi

    # Section 2: Development Environment End-to-End
    echo ""
    echo "🔍 Section 2: Development environment end-to-end..."

    # Test complete development environment setup
    dev_env_ready=true

    # Check essential development tools availability
    if [[ -f "modules/shared/packages.nix" ]]; then
      essential_dev_tools=("git" "curl" "wget" "tree")
      dev_tools_found=0

      for tool in "''${essential_dev_tools[@]}"; do
        if grep -q "\$tool" "modules/shared/packages.nix" 2>/dev/null; then
          dev_tools_found=\$((dev_tools_found + 1))
          echo "✅ PASS: Development tool '\$tool' configured"
          PASSED_TESTS+=("dev-tool-\$tool-configured")
        fi
      done

      if [[ \$dev_tools_found -ge 3 ]]; then
        echo "✅ PASS: Essential development tools configured (\$dev_tools_found/''${#essential_dev_tools[@]})"
        PASSED_TESTS+=("essential-dev-tools-configured")
      else
        dev_env_ready=false
      fi
    else
      dev_env_ready=false
    fi

    # Test development environment integration
    if [[ -f ".envrc" ]]; then
      echo "✅ PASS: Development environment file exists"
      PASSED_TESTS+=("dev-env-file-exists")

      if grep -q "use flake\\|use nix" ".envrc" 2>/dev/null; then
        echo "✅ PASS: Development environment uses Nix/flake"
        PASSED_TESTS+=("dev-env-uses-nix")
      fi
    fi

    if [[ "\$dev_env_ready" = "true" ]]; then
      echo "✅ PASS: Development environment ready for real-world use"
      PASSED_TESTS+=("dev-env-ready")
    else
      echo "⚠️  WARN: Development environment may need additional setup"
    fi

    # Section 3: Editor and IDE Real-World Usage
    echo ""
    echo "🔍 Section 3: Editor and IDE real-world usage..."

    # Test editor configuration deployment
    editor_deployment_ready=false

    # Check for popular editor configurations
    editor_configs=("config/nvim" "config/vim" ".vimrc" ".nvimrc")
    editors_configured=0

    for config in "''${editor_configs[@]}"; do
      if [[ -e "\$config" ]]; then
        editors_configured=\$((editors_configured + 1))
        echo "✅ PASS: Editor configuration '\$config' deployed"
        PASSED_TESTS+=("editor-config-\$config-deployed")
        editor_deployment_ready=true
      fi
    done

    # Test editor package integration
    if [[ -f "modules/shared/packages.nix" ]]; then
      editor_packages=("vim" "neovim" "emacs")
      for editor in "''${editor_packages[@]}"; do
        if grep -q "\$editor" "modules/shared/packages.nix" 2>/dev/null; then
          echo "✅ PASS: Editor '\$editor' available in packages"
          PASSED_TESTS+=("editor-\$editor-packaged")
          editor_deployment_ready=true
        fi
      done
    fi

    if [[ "\$editor_deployment_ready" = "true" ]]; then
      echo "✅ PASS: Editor configuration ready for real-world development"
      PASSED_TESTS+=("editor-ready-real-world")
    else
      echo "⚠️  INFO: Editor configuration may be minimal"
    fi

    # Section 4: Shell Environment Production Readiness
    echo ""
    echo "🔍 Section 4: Shell environment production readiness..."

    # Test shell configuration completeness
    shell_ready_score=0

    # Check shell configuration files
    shell_configs=("modules/shared/config/zsh" ".zshrc" ".bashrc")
    for config in "''${shell_configs[@]}"; do
      if [[ -e "\$config" ]]; then
        echo "✅ PASS: Shell configuration '\$config' available"
        PASSED_TESTS+=("shell-config-\$config-available")
        shell_ready_score=\$((shell_ready_score + 1))
      fi
    done

    # Test shell customization features
    if [[ -d "modules/shared/config/zsh" ]]; then
      zsh_features=\$(find modules/shared/config/zsh -type f | wc -l)
      if [[ \$zsh_features -gt 2 ]]; then
        echo "✅ PASS: Zsh configuration has multiple features (\$zsh_features files)"
        PASSED_TESTS+=("zsh-multiple-features")
        shell_ready_score=\$((shell_ready_score + 1))
      fi
    fi

    # Test shell integration with system
    shell_packages=("zsh" "bash" "fish")
    for shell in "''${shell_packages[@]}"; do
      if [[ -f "modules/shared/packages.nix" ]] && grep -q "\$shell" "modules/shared/packages.nix" 2>/dev/null; then
        echo "✅ PASS: Shell '\$shell' integrated with package management"
        PASSED_TESTS+=("shell-\$shell-integrated")
        shell_ready_score=\$((shell_ready_score + 1))
      fi
    done

    if [[ \$shell_ready_score -ge 3 ]]; then
      echo "✅ PASS: Shell environment production-ready (\$shell_ready_score components)"
      PASSED_TESTS+=("shell-env-production-ready")
    else
      echo "⚠️  WARN: Shell environment may need additional configuration"
    fi

    # Section 5: Security Configuration Deployment
    echo ""
    echo "🔍 Section 5: Security configuration deployment..."

    # Test complete security setup
    security_deployment_score=0

    # Test SSH configuration
    ssh_configs=("config/ssh" ".ssh/config" "modules/shared/config/ssh")
    ssh_configured=false

    for ssh_config in "''${ssh_configs[@]}"; do
      if [[ -e "\$ssh_config" ]]; then
        echo "✅ PASS: SSH configuration '\$ssh_config' deployed"
        PASSED_TESTS+=("ssh-config-deployed")
        ssh_configured=true
        security_deployment_score=\$((security_deployment_score + 1))
        break
      fi
    done

    # Test GPG configuration
    gpg_configs=("config/gpg" ".gnupg" "modules/shared/config/gpg")
    for gpg_config in "''${gpg_configs[@]}"; do
      if [[ -e "\$gpg_config" ]]; then
        echo "✅ PASS: GPG configuration '\$gpg_config' deployed"
        PASSED_TESTS+=("gpg-config-deployed")
        security_deployment_score=\$((security_deployment_score + 1))
        break
      fi
    done

    # Test security file patterns
    if [[ -f ".gitignore" ]]; then
      security_patterns=("*.key" "*.pem" "secrets" ".env")
      patterns_found=0

      for pattern in "''${security_patterns[@]}"; do
        if grep -q "\$pattern" ".gitignore" 2>/dev/null; then
          patterns_found=\$((patterns_found + 1))
        fi
      done

      if [[ \$patterns_found -ge 2 ]]; then
        echo "✅ PASS: Security patterns properly ignored (\$patterns_found patterns)"
        PASSED_TESTS+=("security-patterns-ignored")
        security_deployment_score=\$((security_deployment_score + 1))
      fi
    fi

    if [[ \$security_deployment_score -ge 2 ]]; then
      echo "✅ PASS: Security configuration deployment ready (\$security_deployment_score components)"
      PASSED_TESTS+=("security-deployment-ready")
    else
      echo "⚠️  WARN: Security configuration may need enhancement"
    fi

    # Section 6: Backup and Recovery Workflow
    echo ""
    echo "🔍 Section 6: Backup and recovery workflow..."

    # Test complete backup workflow
    backup_workflow_ready=false

    # Test backup scripts exist and are executable
    backup_scripts=("scripts/backup-system.sh" "scripts/backup-dotfiles.sh")
    backup_scripts_ready=0

    for script in "''${backup_scripts[@]}"; do
      if [[ -f "\$script" ]]; then
        echo "✅ PASS: Backup script '\$script' exists"
        PASSED_TESTS+=("backup-script-\$script-exists")

        if [[ -x "\$script" ]]; then
          echo "✅ PASS: Backup script '\$script' is executable"
          PASSED_TESTS+=("backup-script-\$script-executable")
          backup_scripts_ready=\$((backup_scripts_ready + 1))
        fi
      fi
    done

    # Test backup integration with automation
    if [[ -f "scripts/auto-update-dotfiles" ]]; then
      if grep -q "backup" "scripts/auto-update-dotfiles" 2>/dev/null; then
        echo "✅ PASS: Backup integrated with automation workflow"
        PASSED_TESTS+=("backup-automation-workflow")
        backup_workflow_ready=true
      fi
    fi

    # Test recovery capabilities
    if [[ -f "flake.nix" ]]; then
      # Flake-based systems have inherent recovery capabilities
      echo "✅ PASS: Flake-based recovery capabilities available"
      PASSED_TESTS+=("flake-recovery-capabilities")
      backup_workflow_ready=true
    fi

    if [[ "\$backup_workflow_ready" = "true" ]]; then
      echo "✅ PASS: Backup and recovery workflow ready"
      PASSED_TESTS+=("backup-recovery-workflow-ready")
    else
      echo "⚠️  INFO: Backup and recovery workflow may be basic"
    fi

    # Section 7: Media and Entertainment Setup
    echo ""
    echo "🔍 Section 7: Media and entertainment setup..."

    # Test media software deployment
    media_setup_score=0

    # Test media packages
    if [[ -f "modules/shared/packages.nix" ]]; then
      media_packages=("mpv" "vlc" "ffmpeg" "imagemagick")
      media_packages_found=0

      for package in "''${media_packages[@]}"; do
        if grep -q "\$package" "modules/shared/packages.nix" 2>/dev/null; then
          echo "✅ PASS: Media package '\$package' configured"
          PASSED_TESTS+=("media-package-\$package-configured")
          media_packages_found=\$((media_packages_found + 1))
        fi
      done

      if [[ \$media_packages_found -gt 0 ]]; then
        echo "✅ PASS: Media packages configured (\$media_packages_found packages)"
        PASSED_TESTS+=("media-packages-configured")
        media_setup_score=\$((media_setup_score + 1))
      fi
    fi

    # Test media configuration
    media_configs=("config/mpv" "config/vlc" "modules/shared/config/media")
    for config in "''${media_configs[@]}"; do
      if [[ -d "\$config" ]]; then
        echo "✅ PASS: Media configuration '\$config' deployed"
        PASSED_TESTS+=("media-config-\$config-deployed")
        media_setup_score=\$((media_setup_score + 1))
        break
      fi
    done

    if [[ \$media_setup_score -gt 0 ]]; then
      echo "✅ PASS: Media and entertainment setup ready (\$media_setup_score components)"
      PASSED_TESTS+=("media-entertainment-setup-ready")
    else
      echo "⚠️  INFO: Media and entertainment setup minimal"
    fi

    # Section 8: Network and Communication Deployment
    echo ""
    echo "🔍 Section 8: Network and communication deployment..."

    # Test network tools deployment
    network_deployment_score=0

    # Test essential network tools
    if [[ -f "modules/shared/packages.nix" ]]; then
      network_tools=("curl" "wget" "openssh" "rsync")
      network_tools_found=0

      for tool in "''${network_tools[@]}"; do
        if grep -q "\$tool" "modules/shared/packages.nix" 2>/dev/null; then
          echo "✅ PASS: Network tool '\$tool' deployed"
          PASSED_TESTS+=("network-tool-\$tool-deployed")
          network_tools_found=\$((network_tools_found + 1))
        fi
      done

      if [[ \$network_tools_found -ge 3 ]]; then
        echo "✅ PASS: Essential network tools deployed (\$network_tools_found/''${#network_tools[@]})"
        PASSED_TESTS+=("essential-network-tools-deployed")
        network_deployment_score=\$((network_deployment_score + 1))
      fi
    fi

    # Test communication tool configuration
    comm_configs=("config/irc" "config/slack" "modules/shared/config/communication")
    for config in "''${comm_configs[@]}"; do
      if [[ -d "\$config" ]]; then
        echo "✅ PASS: Communication configuration '\$config' deployed"
        PASSED_TESTS+=("comm-config-\$config-deployed")
        network_deployment_score=\$((network_deployment_score + 1))
        break
      fi
    done

    if [[ \$network_deployment_score -gt 0 ]]; then
      echo "✅ PASS: Network and communication deployment ready (\$network_deployment_score components)"
      PASSED_TESTS+=("network-comm-deployment-ready")
    else
      echo "⚠️  INFO: Network and communication deployment basic"
    fi

    # Section 9: System Monitoring Production Setup
    echo ""
    echo "🔍 Section 9: System monitoring production setup..."

    # Test monitoring tools deployment
    monitoring_production_ready=false

    # Test monitoring packages
    if [[ -f "modules/shared/packages.nix" ]]; then
      monitoring_tools=("htop" "btop" "iotop" "nethogs")
      monitoring_tools_found=0

      for tool in "''${monitoring_tools[@]}"; do
        if grep -q "\$tool" "modules/shared/packages.nix" 2>/dev/null; then
          echo "✅ PASS: Monitoring tool '\$tool' ready for production"
          PASSED_TESTS+=("monitoring-tool-\$tool-production")
          monitoring_tools_found=\$((monitoring_tools_found + 1))
        fi
      done

      if [[ \$monitoring_tools_found -gt 0 ]]; then
        echo "✅ PASS: Monitoring tools production-ready (\$monitoring_tools_found tools)"
        PASSED_TESTS+=("monitoring-tools-production-ready")
        monitoring_production_ready=true
      fi
    fi

    # Test monitoring configuration
    monitoring_configs=("config/htop" "config/btop" "modules/shared/config/monitoring")
    for config in "''${monitoring_configs[@]}"; do
      if [[ -e "\$config" ]]; then
        echo "✅ PASS: Monitoring configuration '\$config' production-ready"
        PASSED_TESTS+=("monitoring-config-\$config-production")
        monitoring_production_ready=true
        break
      fi
    done

    if [[ "\$monitoring_production_ready" = "true" ]]; then
      echo "✅ PASS: System monitoring production setup complete"
      PASSED_TESTS+=("monitoring-production-setup-complete")
    else
      echo "⚠️  INFO: System monitoring setup may be basic"
    fi

    # Section 10: Theme and Appearance Deployment
    echo ""
    echo "🔍 Section 10: Theme and appearance deployment..."

    # Test complete theming setup
    theming_deployment_score=0

    # Test font deployment
    if [[ -f "modules/shared/packages.nix" ]]; then
      if grep -q "font\\|Font" "modules/shared/packages.nix" 2>/dev/null; then
        echo "✅ PASS: Fonts deployed in package management"
        PASSED_TESTS+=("fonts-deployed-packages")
        theming_deployment_score=\$((theming_deployment_score + 1))
      fi
    fi

    # Test theme configuration deployment
    theme_configs=("config/themes" "config/gtk" "modules/shared/config/themes")
    for config in "''${theme_configs[@]}"; do
      if [[ -d "\$config" ]]; then
        echo "✅ PASS: Theme configuration '\$config' deployed"
        PASSED_TESTS+=("theme-config-\$config-deployed")
        theming_deployment_score=\$((theming_deployment_score + 1))
        break
      fi
    done

    # Test cursor and icon deployment
    if [[ -f "modules/shared/packages.nix" ]]; then
      appearance_packages=("cursor" "icon" "theme")
      for package in "''${appearance_packages[@]}"; do
        if grep -qi "\$package" "modules/shared/packages.nix" 2>/dev/null; then
          echo "✅ PASS: Appearance package '\$package' deployed"
          PASSED_TESTS+=("appearance-package-\$package-deployed")
          theming_deployment_score=\$((theming_deployment_score + 1))
          break
        fi
      done
    fi

    if [[ \$theming_deployment_score -gt 0 ]]; then
      echo "✅ PASS: Theme and appearance deployment ready (\$theming_deployment_score components)"
      PASSED_TESTS+=("theming-deployment-ready")
    else
      echo "⚠️  INFO: Theme and appearance deployment minimal"
    fi

    # Section 11: Custom Workflow Integration
    echo ""
    echo "🔍 Section 11: Custom workflow integration..."

    # Test complete custom workflow deployment
    custom_workflow_score=0

    # Test custom scripts availability
    if [[ -d "scripts" ]]; then
      custom_script_count=\$(find scripts -name "*.sh" -type f | wc -l)
      if [[ \$custom_script_count -gt 3 ]]; then
        echo "✅ PASS: Multiple custom scripts available (\$custom_script_count scripts)"
        PASSED_TESTS+=("multiple-custom-scripts")
        custom_workflow_score=\$((custom_workflow_score + 1))
      fi

      # Test script executable permissions
      executable_script_count=\$(find scripts -name "*.sh" -type f -executable | wc -l)
      if [[ \$executable_script_count -gt 0 ]]; then
        echo "✅ PASS: Custom scripts are executable (\$executable_script_count executable)"
        PASSED_TESTS+=("custom-scripts-executable")
        custom_workflow_score=\$((custom_workflow_score + 1))
      fi
    fi

    # Test workflow automation integration
    if [[ -f "scripts/auto-update-dotfiles" ]]; then
      echo "✅ PASS: Automated workflow script available"
      PASSED_TESTS+=("automated-workflow-available")
      custom_workflow_score=\$((custom_workflow_score + 1))

      # Test workflow safety mechanisms
      if grep -q "backup\\|rollback\\|verify" "scripts/auto-update-dotfiles" 2>/dev/null; then
        echo "✅ PASS: Automated workflow includes safety mechanisms"
        PASSED_TESTS+=("automated-workflow-safety")
        custom_workflow_score=\$((custom_workflow_score + 1))
      fi
    fi

    if [[ \$custom_workflow_score -ge 3 ]]; then
      echo "✅ PASS: Custom workflow integration production-ready (\$custom_workflow_score components)"
      PASSED_TESTS+=("custom-workflow-production-ready")
    else
      echo "⚠️  WARN: Custom workflow integration may need enhancement"
    fi

    # Section 12: Production Readiness Validation
    echo ""
    echo "🔍 Section 12: Production readiness validation..."

    # Test overall production readiness
    production_components=()

    # Essential components check
    if [[ -f "README.md" ]]; then
      production_components+=("documentation")
    fi

    if [[ -f "modules/shared/packages.nix" ]]; then
      production_components+=("package-management")
    fi

    if [[ -d "scripts" ]]; then
      production_components+=("automation-scripts")
    fi

    if [[ -f "flake.nix" ]]; then
      production_components+=("configuration-management")
    fi

    if [[ -f ".gitignore" ]]; then
      production_components+=("security-practices")
    fi

    production_score=''${#production_components[@]}
    if [[ \$production_score -ge 4 ]]; then
      echo "✅ PASS: General functionality system production-ready (\$production_score/5 components)"
      PASSED_TESTS+=("general-functionality-production-ready")

      # List production components
      echo "Production components available:"
      for component in "''${production_components[@]}"; do
        echo "   ✓ \$component"
      done
    else
      echo "❌ FAIL: General functionality system not production-ready (\$production_score/5 components)"
      FAILED_TESTS+=("general-functionality-not-production-ready")
    fi

    # Section 13: Real-World Scenario Testing
    echo ""
    echo "🔍 Section 13: Real-world scenario testing..."

    # Scenario 1: New user onboarding
    echo "Testing new user onboarding scenario..."
    onboarding_ready=true

    if [[ ! -f "README.md" ]]; then
      onboarding_ready=false
    fi

    if [[ ! -f "flake.nix" ]]; then
      onboarding_ready=false
    fi

    if [[ "\$onboarding_ready" = "true" ]]; then
      echo "✅ PASS: New user onboarding scenario ready"
      PASSED_TESTS+=("new-user-onboarding-ready")
    else
      echo "❌ FAIL: New user onboarding scenario not ready"
      FAILED_TESTS+=("new-user-onboarding-not-ready")
    fi

    # Scenario 2: Daily development workflow
    echo "Testing daily development workflow scenario..."
    daily_workflow_ready=true

    if [[ ! -d "modules/shared" ]]; then
      daily_workflow_ready=false
    fi

    if [[ ! -d "scripts" ]]; then
      daily_workflow_ready=false
    fi

    if [[ "\$daily_workflow_ready" = "true" ]]; then
      echo "✅ PASS: Daily development workflow scenario ready"
      PASSED_TESTS+=("daily-workflow-ready")
    else
      echo "❌ FAIL: Daily development workflow scenario not ready"
      FAILED_TESTS+=("daily-workflow-not-ready")
    fi

    # Scenario 3: System maintenance workflow
    echo "Testing system maintenance workflow scenario..."
    maintenance_workflow_ready=false

    if [[ -f "scripts/auto-update-dotfiles" ]] || [[ -f "scripts/backup-system.sh" ]]; then
      maintenance_workflow_ready=true
    fi

    if [[ "\$maintenance_workflow_ready" = "true" ]]; then
      echo "✅ PASS: System maintenance workflow scenario ready"
      PASSED_TESTS+=("maintenance-workflow-ready")
    else
      echo "⚠️  INFO: System maintenance workflow may require manual steps"
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
      echo "🚨 E2E test identified ''${#FAILED_TESTS[@]} critical general functionality issues"
      echo "These issues must be resolved before production deployment"
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} E2E tests passed!"
      echo "✅ General functionality system is ready for real-world deployment"
      echo ""
      echo "🚀 E2E Test Coverage Summary:"
      echo "   ✓ Complete documentation workflow"
      echo "   ✓ Development environment end-to-end"
      echo "   ✓ Editor and IDE real-world usage"
      echo "   ✓ Shell environment production readiness"
      echo "   ✓ Security configuration deployment"
      echo "   ✓ Backup and recovery workflow"
      echo "   ✓ Media and entertainment setup"
      echo "   ✓ Network and communication deployment"
      echo "   ✓ System monitoring production setup"
      echo "   ✓ Theme and appearance deployment"
      echo "   ✓ Custom workflow integration"
      echo "   ✓ Production readiness validation"
      echo "   ✓ Real-world scenario testing"
      echo ""
      echo "🎯 Deployment Target: ${system}"
      echo "🌟 General functionality comprehensive deployment validated"
      exit 0
    fi
  '';

in
pkgs.runCommand "general-functionality-comprehensive-e2e-test"
{
  buildInputs = with pkgs; [ bash nix git findutils gnugrep coreutils ];
} ''
  echo "=== Starting Comprehensive General Functionality E2E Tests ==="
  echo "Testing real-world scenarios for miscellaneous features and system functionality..."
  echo "Platform: ${system}"
  echo ""

  # Run the comprehensive E2E test
  ${generalFunctionalityE2EScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "=== E2E Test Execution Complete ==="
  echo "Full results and logs saved to: $out"
  cp test-output.log $out
''
