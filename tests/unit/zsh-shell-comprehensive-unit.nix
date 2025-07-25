# Comprehensive Zsh & Shell Unit Tests
# Consolidated unit tests covering all shell configuration functionality

{ pkgs, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Comprehensive shell testing script
  zshShellUnitScript = pkgs.writeShellScript "zsh-shell-comprehensive-unit" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive Zsh & Shell Unit Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Zsh Configuration Files
    echo ""
    echo "🔍 Section 1: Zsh configuration files..."

    # Check for zsh configuration in Nix files
    zsh_configs=("'${src}/modules/darwin/shell.nix" \
                 "'${src}/modules/shared/config/shell" \
                 "'${src}/modules/shared/home-manager.nix")

    zsh_config_found=false
    for config in "''${zsh_configs[@]}"; do
      if [[ -f "$config" || -d "$config" ]]; then
        echo "✅ PASS: Zsh configuration found: $config"
        PASSED_TESTS+=("zsh-config-found")
        zsh_config_found=true

        # Check for zsh program configuration
        if [[ -f "$config" ]] && grep -q "programs\.zsh\|zsh.*enable" "$config" 2>/dev/null; then
          echo "✅ PASS: Zsh program configuration detected"
          PASSED_TESTS+=("zsh-program-config")
        fi

        # Check for shell environment variables
        if [[ -f "$config" ]] && grep -q "EDITOR\|SHELL\|PATH" "$config" 2>/dev/null; then
          echo "✅ PASS: Shell environment variables configured"
          PASSED_TESTS+=("shell-env-vars")
        fi

        break
      fi
    done

    if [[ "$zsh_config_found" = "false" ]]; then
      echo "❌ FAIL: No zsh configuration found"
      FAILED_TESTS+=("no-zsh-config")
    fi

    # Section 2: Shell Aliases Configuration
    echo ""
    echo "🔍 Section 2: Shell aliases configuration..."

    # Check for aliases configuration
    alias_configs=("'${src}/modules/shared/config/shell/aliases.nix" \
                   "'${src}/modules/darwin/shell.nix" \
                   "'${src}/config/shell/aliases.nix")

    alias_config_found=false
    for alias_config in "''${alias_configs[@]}"; do
      if [[ -f "$alias_config" ]]; then
        echo "✅ PASS: Alias configuration found: $alias_config"
        PASSED_TESTS+=("alias-config-found")
        alias_config_found=true

        # Check for common aliases
        common_aliases=("ls" "ll" "la" "grep" ".." "cd")
        for alias_name in "''${common_aliases[@]}"; do
          if grep -q "$alias_name.*=" "$alias_config" 2>/dev/null; then
            echo "✅ PASS: Common alias '$alias_name' configured"
            PASSED_TESTS+=("alias-$alias_name")
          fi
        done

        # Check for IntelliJ IDEA alias
        if grep -q "idea.*=" "$alias_config" 2>/dev/null; then
          echo "✅ PASS: IntelliJ IDEA alias configured"
          PASSED_TESTS+=("idea-alias-configured")

          # Check for proper argument handling
          if grep -q "idea.*nohup\|idea.*function\|idea.*\"$@\"" "$alias_config" 2>/dev/null; then
            echo "✅ PASS: IDEA alias has proper argument handling"
            PASSED_TESTS+=("idea-alias-args")
          else
            echo "❌ FAIL: IDEA alias may have argument handling issues"
            FAILED_TESTS+=("idea-alias-args-issue")
          fi
        else
          echo "⚠️  INFO: IntelliJ IDEA alias not found"
        fi

        # Check for Claude CLI aliases
        if grep -q "cc.*claude\|ccw.*worktree" "$alias_config" 2>/dev/null; then
          echo "✅ PASS: Claude CLI aliases configured"
          PASSED_TESTS+=("claude-cli-aliases")
        fi

        break
      fi
    done

    if [[ "$alias_config_found" = "false" ]]; then
      echo "❌ FAIL: No alias configuration found"
      FAILED_TESTS+=("no-alias-config")
    fi

    # Section 3: Powerlevel10k Configuration
    echo ""
    echo "🔍 Section 3: Powerlevel10k configuration..."

    # Check for Powerlevel10k theme configuration
    p10k_config_found=false
    for config in "''${zsh_configs[@]}"; do
      if [[ -f "$config" ]] && grep -q "powerlevel10k\|p10k" "$config" 2>/dev/null; then
        echo "✅ PASS: Powerlevel10k configuration found"
        PASSED_TESTS+=("p10k-config-found")
        p10k_config_found=true

        # Check for theme source
        if grep -q "source.*powerlevel10k\|plugins.*powerlevel10k" "$config" 2>/dev/null; then
          echo "✅ PASS: Powerlevel10k theme source configured"
          PASSED_TESTS+=("p10k-theme-source")
        fi

        break
      fi
    done

    # Check for P10k configuration file
    p10k_config_file="'${src}/.p10k.zsh"
    if [[ -f "$p10k_config_file" ]]; then
      echo "✅ PASS: P10k configuration file exists"
      PASSED_TESTS+=("p10k-config-file")

      # Check for instant prompt configuration
      if grep -q "instant.*prompt\|POWERLEVEL9K_INSTANT_PROMPT" "$p10k_config_file" 2>/dev/null; then
        echo "✅ PASS: P10k instant prompt configured"
        PASSED_TESTS+=("p10k-instant-prompt")
      fi
    else
      echo "⚠️  INFO: P10k configuration file not found (may be generated)"
    fi

    if [[ "$p10k_config_found" = "false" ]]; then
      echo "❌ FAIL: No Powerlevel10k configuration found"
      FAILED_TESTS+=("no-p10k-config")
    fi

    # Section 4: Shell Functions
    echo ""
    echo "🔍 Section 4: Shell functions..."

    # Check for shell functions configuration
    function_configs=("'${src}/modules/shared/config/shell/functions.nix" \
                     "'${src}/modules/darwin/shell.nix" \
                     "'${src}/config/shell/functions.nix")

    function_config_found=false
    for func_config in "''${function_configs[@]}"; do
      if [[ -f "$func_config" ]]; then
        echo "✅ PASS: Shell functions configuration found: $func_config"
        PASSED_TESTS+=("functions-config-found")
        function_config_found=true

        # Check for CCW function
        if grep -q "ccw.*function\|ccw.*=" "$func_config" 2>/dev/null; then
          echo "✅ PASS: CCW function configured"
          PASSED_TESTS+=("ccw-function-configured")

          # Check for git worktree logic
          if grep -q "git.*worktree\|worktree.*add" "$func_config" 2>/dev/null; then
            echo "✅ PASS: CCW function has git worktree logic"
            PASSED_TESTS+=("ccw-git-worktree-logic")
          fi
        fi

        # Check for utility functions
        utility_functions=("extract" "mkcd" "backup" "find_and_replace")
        for func_name in "''${utility_functions[@]}"; do
          if grep -q "$func_name.*=" "$func_config" 2>/dev/null; then
            echo "✅ PASS: Utility function '$func_name' configured"
            PASSED_TESTS+=("function-$func_name")
          fi
        done

        break
      fi
    done

    if [[ "$function_config_found" = "false" ]]; then
      echo "⚠️  INFO: No dedicated shell functions configuration found"
    fi

    # Section 5: Environment Variables
    echo ""
    echo "🔍 Section 5: Environment variables..."

    # Check for environment variable configuration
    env_configured=false
    for config in "''${zsh_configs[@]}"; do
      if [[ -f "$config" ]]; then
        # Check for common environment variables
        env_vars=("EDITOR" "BROWSER" "LANG" "LC_ALL")
        for env_var in "''${env_vars[@]}"; do
          if grep -q "$env_var.*=" "$config" 2>/dev/null; then
            echo "✅ PASS: Environment variable '$env_var' configured"
            PASSED_TESTS+=("env-$env_var")
            env_configured=true
          fi
        done

        # Check for PATH modifications
        if grep -q "PATH.*=" "$config" 2>/dev/null; then
          echo "✅ PASS: PATH modifications configured"
          PASSED_TESTS+=("path-modifications")
          env_configured=true
        fi

        # Check for SSH agent configuration
        if grep -q "SSH_AUTH_SOCK\|ssh-agent" "$config" 2>/dev/null; then
          echo "✅ PASS: SSH agent configuration found"
          PASSED_TESTS+=("ssh-agent-config")
          env_configured=true
        fi
      fi
    done

    if [[ "$env_configured" = "false" ]]; then
      echo "❌ FAIL: No environment variables configured"
      FAILED_TESTS+=("no-env-config")
    fi

    # Section 6: Direnv Integration
    echo ""
    echo "🔍 Section 6: Direnv integration..."

    # Check for direnv configuration
    direnv_configured=false
    for config in "''${zsh_configs[@]}"; do
      if [[ -f "$config" ]] && grep -q "direnv\|programs\.direnv" "$config" 2>/dev/null; then
        echo "✅ PASS: Direnv integration configured"
        PASSED_TESTS+=("direnv-configured")
        direnv_configured=true

        # Check for direnv hook
        if grep -q "direnv.*hook\|eval.*direnv" "$config" 2>/dev/null; then
          echo "✅ PASS: Direnv hook configured"
          PASSED_TESTS+=("direnv-hook")
        fi

        break
      fi
    done

    if [[ "$direnv_configured" = "false" ]]; then
      echo "❌ FAIL: No direnv integration found"
      FAILED_TESTS+=("no-direnv-config")
    fi

    # Section 7: Shell History Configuration
    echo ""
    echo "🔍 Section 7: Shell history configuration..."

    # Check for history configuration
    history_configured=false
    for config in "''${zsh_configs[@]}"; do
      if [[ -f "$config" ]]; then
        # Check for history settings
        history_settings=("HISTSIZE" "HISTFILE" "SAVEHIST" "history")
        for setting in "''${history_settings[@]}"; do
          if grep -q "$setting" "$config" 2>/dev/null; then
            echo "✅ PASS: History setting '$setting' configured"
            PASSED_TESTS+=("history-$setting")
            history_configured=true
          fi
        done

        # Check for history options
        if grep -q "setopt.*hist\|histverify\|histignoredups" "$config" 2>/dev/null; then
          echo "✅ PASS: History options configured"
          PASSED_TESTS+=("history-options")
          history_configured=true
        fi
      fi
    done

    if [[ "$history_configured" = "false" ]]; then
      echo "⚠️  INFO: No explicit history configuration found (may use defaults)"
    fi

    # Section 8: Plugin Management
    echo ""
    echo "🔍 Section 8: Plugin management..."

    # Check for plugin configuration
    plugins_configured=false
    for config in "''${zsh_configs[@]}"; do
      if [[ -f "$config" ]]; then
        # Check for common plugins
        plugins=("plugins" "oh-my-zsh" "prezto" "zinit")
        for plugin in "''${plugins[@]}"; do
          if grep -q "$plugin" "$config" 2>/dev/null; then
            echo "✅ PASS: Plugin system '$plugin' configured"
            PASSED_TESTS+=("plugin-$plugin")
            plugins_configured=true
          fi
        done

        # Check for syntax highlighting
        if grep -q "syntax.*highlight\|zsh-syntax-highlighting" "$config" 2>/dev/null; then
          echo "✅ PASS: Syntax highlighting configured"
          PASSED_TESTS+=("syntax-highlighting")
          plugins_configured=true
        fi

        # Check for autosuggestions
        if grep -q "autosuggestions\|zsh-autosuggestions" "$config" 2>/dev/null; then
          echo "✅ PASS: Autosuggestions configured"
          PASSED_TESTS+=("autosuggestions")
          plugins_configured=true
        fi
      fi
    done

    if [[ "$plugins_configured" = "false" ]]; then
      echo "⚠️  INFO: No explicit plugin configuration found"
    fi

    # Section 9: Home Manager Integration
    echo ""
    echo "🔍 Section 9: Home Manager integration..."

    # Check for Home Manager shell integration
    hm_configs=("'${src}/modules/darwin/home-manager.nix" \
                "'${src}/modules/shared/home-manager.nix" \
                "'${src}/home.nix")

    hm_shell_integration=false
    for hm_config in "''${hm_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        # Check for shell programs
        if grep -q "programs\.zsh\|programs\.bash\|programs\.fish" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Shell programs configured in Home Manager"
          PASSED_TESTS+=("hm-shell-programs")
          hm_shell_integration=true
        fi

        # Check for shell aliases in Home Manager
        if grep -q "shellAliases\|shell.*aliases" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Shell aliases integrated with Home Manager"
          PASSED_TESTS+=("hm-shell-aliases")
          hm_shell_integration=true
        fi

        break
      fi
    done

    if [[ "$hm_shell_integration" = "false" ]]; then
      echo "❌ FAIL: No Home Manager shell integration found"
      FAILED_TESTS+=("no-hm-shell-integration")
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
      echo "🔧 Unit test identified ''${#FAILED_TESTS[@]} issues that need resolution"
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} unit tests passed!"
      echo "✅ Zsh & Shell unit functionality is working correctly"
      echo ""
      echo "📋 Unit Test Coverage Summary:"
      echo "   ✓ Zsh configuration files"
      echo "   ✓ Shell aliases configuration"
      echo "   ✓ Powerlevel10k configuration"
      echo "   ✓ Shell functions"
      echo "   ✓ Environment variables"
      echo "   ✓ Direnv integration"
      echo "   ✓ Shell history configuration"
      echo "   ✓ Plugin management"
      echo "   ✓ Home Manager integration"
      exit 0
    fi
  '';

in
pkgs.runCommand "zsh-shell-comprehensive-unit-test"
{
  buildInputs = with pkgs; [ bash findutils gnugrep coreutils ];
} ''
  echo "Running Zsh & Shell comprehensive unit tests..."

  # Run the comprehensive unit test
  ${zshShellUnitScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "Zsh & Shell unit test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
