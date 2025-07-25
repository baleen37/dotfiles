# Comprehensive Zsh & Shell Integration Tests
# Tests complete shell environment integration and workflow scenarios

{ pkgs, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  zshShellIntegrationScript = pkgs.writeShellScript "zsh-shell-comprehensive-integration" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive Zsh & Shell Integration Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Shell Environment Integration
    echo ""
    echo "🔍 Section 1: Shell environment integration..."

    # Test zsh availability and basic functionality
    if command -v zsh >/dev/null 2>&1; then
      echo "✅ PASS: Zsh command available"
      PASSED_TESTS+=("zsh-available")

      # Test zsh version
      zsh_version=$(zsh --version 2>/dev/null | head -1)
      if [[ -n "$zsh_version" ]]; then
        echo "✅ PASS: Zsh version: $zsh_version"
        PASSED_TESTS+=("zsh-version")
      else
        echo "❌ FAIL: Cannot get zsh version"
        FAILED_TESTS+=("zsh-version-failed")
      fi

      # Test zsh basic execution
      if echo 'echo "zsh test"' | zsh 2>/dev/null | grep -q "zsh test"; then
        echo "✅ PASS: Zsh basic execution works"
        PASSED_TESTS+=("zsh-basic-execution")
      else
        echo "❌ FAIL: Zsh basic execution failed"
        FAILED_TESTS+=("zsh-basic-execution-failed")
      fi
    else
      echo "❌ FAIL: Zsh command not available"
      FAILED_TESTS+=("zsh-unavailable")
    fi

    # Test Home Manager zsh configuration
    home_zshrc="$HOME/.zshrc"
    if [[ -f "$home_zshrc" ]]; then
      echo "✅ PASS: Home Manager zshrc exists"
      PASSED_TESTS+=("hm-zshrc-exists")

      # Check for essential configurations
      essential_configs=("PATH" "EDITOR" "nix")
      for config in "''${essential_configs[@]}"; do
        if grep -q "$config" "$home_zshrc" 2>/dev/null; then
          echo "✅ PASS: Essential config '$config' found in zshrc"
          PASSED_TESTS+=("zshrc-$config")
        else
          echo "⚠️  INFO: Essential config '$config' not found in zshrc"
        fi
      done
    else
      echo "❌ FAIL: Home Manager zshrc does not exist"
      FAILED_TESTS+=("hm-zshrc-missing")
    fi

    # Section 2: Powerlevel10k Integration
    echo ""
    echo "🔍 Section 2: Powerlevel10k integration..."

    # Test Powerlevel10k configuration
    p10k_integration=false
    if [[ -f "$home_zshrc" ]]; then
      if grep -q "powerlevel10k\|p10k" "$home_zshrc" 2>/dev/null; then
        echo "✅ PASS: Powerlevel10k configuration found in zshrc"
        PASSED_TESTS+=("p10k-in-zshrc")
        p10k_integration=true
      fi
    fi

    # Check for P10k configuration file
    p10k_config_locations=("$HOME/.p10k.zsh" "${src}/.p10k.zsh" "${src}/config/.p10k.zsh")
    p10k_config_found=false
    for p10k_config in "''${p10k_config_locations[@]}"; do
      if [[ -f "$p10k_config" ]]; then
        echo "✅ PASS: P10k configuration file found: $p10k_config"
        PASSED_TESTS+=("p10k-config-file")
        p10k_config_found=true

        # Check for instant prompt configuration
        if grep -q "instant.*prompt\|POWERLEVEL9K_INSTANT_PROMPT" "$p10k_config" 2>/dev/null; then
          echo "✅ PASS: P10k instant prompt configured"
          PASSED_TESTS+=("p10k-instant-prompt")
        fi

        # Check for segment configurations
        if grep -q "POWERLEVEL9K.*LEFT\|POWERLEVEL9K.*RIGHT" "$p10k_config" 2>/dev/null; then
          echo "✅ PASS: P10k prompt segments configured"
          PASSED_TESTS+=("p10k-segments")
        fi

        break
      fi
    done

    if [[ "$p10k_config_found" = "false" ]]; then
      echo "⚠️  INFO: P10k configuration file not found (may be generated at runtime)"
    fi

    # Test P10k functionality in shell
    if command -v zsh >/dev/null 2>&1 && [[ "$p10k_integration" = "true" ]]; then
      # Test if P10k functions are available
      p10k_functions=$(zsh -c 'autoload -U compinit; compinit; typeset -f | grep -c "^p10k" 2>/dev/null || echo 0')
      if [[ "$p10k_functions" -gt 0 ]]; then
        echo "✅ PASS: P10k functions available ($p10k_functions functions)"
        PASSED_TESTS+=("p10k-functions-available")
      else
        echo "⚠️  INFO: P10k functions not immediately available (may require full shell initialization)"
      fi
    fi

    # Section 3: Alias Integration Testing
    echo ""
    echo "🔍 Section 3: Alias integration testing..."

    # Test alias configuration integration
    if [[ -f "$home_zshrc" ]]; then
      # Test common aliases
      common_aliases=("ll" "la" "ls" ".." "grep")
      for alias_name in "''${common_aliases[@]}"; do
        if zsh -c "source $home_zshrc; alias $alias_name" >/dev/null 2>&1; then
          echo "✅ PASS: Common alias '$alias_name' works in shell"
          PASSED_TESTS+=("alias-$alias_name-works")
        else
          echo "⚠️  INFO: Common alias '$alias_name' not available"
        fi
      done

      # Test IntelliJ IDEA alias specifically
      if zsh -c "source $home_zshrc; type idea" >/dev/null 2>&1; then
        echo "✅ PASS: IntelliJ IDEA alias/function available"
        PASSED_TESTS+=("idea-command-available")

        # Test idea command type (function vs alias)
        idea_type=$(zsh -c "source $home_zshrc; type idea" 2>/dev/null)
        if echo "$idea_type" | grep -q "function"; then
          echo "✅ PASS: IDEA implemented as function (better for argument handling)"
          PASSED_TESTS+=("idea-is-function")
        elif echo "$idea_type" | grep -q "alias"; then
          echo "⚠️  INFO: IDEA implemented as alias (may have argument issues)"

          # Check for proper argument handling in alias
          if echo "$idea_type" | grep -q 'nohup.*"$@"'; then
            echo "✅ PASS: IDEA alias has proper argument handling"
            PASSED_TESTS+=("idea-alias-proper-args")
          else
            echo "❌ FAIL: IDEA alias may have argument handling issues"
            FAILED_TESTS+=("idea-alias-arg-issues")
          fi
        fi
      else
        echo "❌ FAIL: IntelliJ IDEA command not available"
        FAILED_TESTS+=("idea-command-unavailable")
      fi

      # Test Claude CLI aliases
      claude_aliases=("cc" "ccw")
      for claude_alias in "''${claude_aliases[@]}"; do
        if zsh -c "source $home_zshrc; type $claude_alias" >/dev/null 2>&1; then
          echo "✅ PASS: Claude CLI '$claude_alias' command available"
          PASSED_TESTS+=("claude-$claude_alias-available")
        else
          echo "⚠️  INFO: Claude CLI '$claude_alias' command not available"
        fi
      done
    fi

    # Section 4: Function Integration Testing
    echo ""
    echo "🔍 Section 4: Function integration testing..."

    # Test shell functions integration
    if [[ -f "$home_zshrc" ]]; then
      # Test CCW function specifically
      if zsh -c "source $home_zshrc; declare -f ccw" >/dev/null 2>&1; then
        echo "✅ PASS: CCW function declared"
        PASSED_TESTS+=("ccw-function-declared")

        # Test CCW function usage help
        ccw_help=$(zsh -c "source $home_zshrc; ccw" 2>&1 || true)
        if echo "$ccw_help" | grep -q "Usage\|usage\|branch-name"; then
          echo "✅ PASS: CCW function shows usage help"
          PASSED_TESTS+=("ccw-usage-help")
        else
          echo "⚠️  INFO: CCW function may not show usage help"
        fi
      else
        echo "⚠️  INFO: CCW function not declared (may be alias or unavailable)"
      fi

      # Test utility functions
      utility_functions=("extract" "mkcd" "backup")
      for func_name in "''${utility_functions[@]}"; do
        if zsh -c "source $home_zshrc; declare -f $func_name" >/dev/null 2>&1; then
          echo "✅ PASS: Utility function '$func_name' declared"
          PASSED_TESTS+=("function-$func_name-declared")
        else
          echo "⚠️  INFO: Utility function '$func_name' not declared"
        fi
      done
    fi

    # Section 5: Environment Variables Integration
    echo ""
    echo "🔍 Section 5: Environment variables integration..."

    # Test environment variables in shell context
    if command -v zsh >/dev/null 2>&1; then
      # Test essential environment variables
      essential_env_vars=("EDITOR" "HOME" "USER" "PATH")
      for env_var in "''${essential_env_vars[@]}"; do
        if zsh -c "test -n \"\$$env_var\"" 2>/dev/null; then
          echo "✅ PASS: Environment variable '$env_var' set in shell"
          PASSED_TESTS+=("env-$env_var-set")

          # Show value for informational purposes (except sensitive ones)
          if [[ "$env_var" != "PATH" ]]; then
            env_value=$(zsh -c "echo \$$env_var" 2>/dev/null)
            echo "     Value: $env_value"
          fi
        else
          echo "❌ FAIL: Environment variable '$env_var' not set in shell"
          FAILED_TESTS+=("env-$env_var-not-set")
        fi
      done

      # Test PATH includes Nix profile
      if zsh -c 'echo "$PATH"' 2>/dev/null | grep -q "nix-profile\|\.nix-profile"; then
        echo "✅ PASS: PATH includes Nix profile"
        PASSED_TESTS+=("path-includes-nix")
      else
        echo "❌ FAIL: PATH does not include Nix profile"
        FAILED_TESTS+=("path-missing-nix")
      fi

      # Test SSH agent configuration
      if zsh -c "test -n \"\$SSH_AUTH_SOCK\"" 2>/dev/null; then
        echo "✅ PASS: SSH agent socket configured"
        PASSED_TESTS+=("ssh-agent-configured")
      else
        echo "⚠️  INFO: SSH agent socket not configured"
      fi
    fi

    # Section 6: Direnv Integration Testing
    echo ""
    echo "🔍 Section 6: Direnv integration testing..."

    # Test direnv availability
    if command -v direnv >/dev/null 2>&1; then
      echo "✅ PASS: Direnv command available"
      PASSED_TESTS+=("direnv-available")

      # Test direnv hook in shell
      if [[ -f "$home_zshrc" ]] && grep -q "direnv.*hook\|eval.*direnv" "$home_zshrc" 2>/dev/null; then
        echo "✅ PASS: Direnv hook configured in zshrc"
        PASSED_TESTS+=("direnv-hook-configured")

        # Test direnv functionality
        if zsh -c "source $home_zshrc; direnv --version" >/dev/null 2>&1; then
          echo "✅ PASS: Direnv functional in shell"
          PASSED_TESTS+=("direnv-functional")
        else
          echo "❌ FAIL: Direnv not functional in shell"
          FAILED_TESTS+=("direnv-not-functional")
        fi
      else
        echo "❌ FAIL: Direnv hook not configured"
        FAILED_TESTS+=("direnv-hook-not-configured")
      fi
    else
      echo "❌ FAIL: Direnv command not available"
      FAILED_TESTS+=("direnv-unavailable")
    fi

    # Section 7: Plugin Integration Testing
    echo ""
    echo "🔍 Section 7: Plugin integration testing..."

    # Test syntax highlighting integration
    if [[ -f "$home_zshrc" ]]; then
      if grep -q "syntax.*highlight\|zsh-syntax-highlighting" "$home_zshrc" 2>/dev/null; then
        echo "✅ PASS: Syntax highlighting configured"
        PASSED_TESTS+=("syntax-highlighting-configured")
      else
        echo "⚠️  INFO: Syntax highlighting not explicitly configured"
      fi

      # Test autosuggestions integration
      if grep -q "autosuggestions\|zsh-autosuggestions" "$home_zshrc" 2>/dev/null; then
        echo "✅ PASS: Autosuggestions configured"
        PASSED_TESTS+=("autosuggestions-configured")
      else
        echo "⚠️  INFO: Autosuggestions not explicitly configured"
      fi

      # Test history configuration
      if grep -q "HISTSIZE\|HISTFILE\|SAVEHIST" "$home_zshrc" 2>/dev/null; then
        echo "✅ PASS: History configuration found"
        PASSED_TESTS+=("history-configured")
      else
        echo "⚠️  INFO: History configuration not explicitly found"
      fi
    fi

    # Section 8: Cross-Platform Integration
    echo ""
    echo "🔍 Section 8: Cross-platform integration..."

    # Test platform-specific configurations
    current_platform=$(uname -s)
    echo "Current platform: $current_platform"

    case "$current_platform" in
      "Darwin")
        echo "Testing macOS-specific integrations..."

        # Test macOS-specific aliases
        if [[ -f "$home_zshrc" ]]; then
          if grep -q "darwin\|macos\|mac" "$home_zshrc" 2>/dev/null; then
            echo "✅ PASS: macOS-specific configurations found"
            PASSED_TESTS+=("macos-specific-config")
          fi

          # Test homebrew integration if available
          if command -v brew >/dev/null 2>&1; then
            if grep -q "brew\|homebrew" "$home_zshrc" 2>/dev/null; then
              echo "✅ PASS: Homebrew integration configured"
              PASSED_TESTS+=("homebrew-integration")
            fi
          fi
        fi
        ;;
      "Linux")
        echo "Testing Linux-specific integrations..."

        # Test Linux-specific configurations
        if [[ -f "$home_zshrc" ]]; then
          if grep -q "linux" "$home_zshrc" 2>/dev/null; then
            echo "✅ PASS: Linux-specific configurations found"
            PASSED_TESTS+=("linux-specific-config")
          fi
        fi
        ;;
    esac

    # Section 9: Flake Integration Testing
    echo ""
    echo "🔍 Section 9: Flake integration testing..."

    # Test if shell configuration is integrated with Nix flake
    if [[ -f "${src}/flake.nix" ]]; then
      echo "✅ PASS: flake.nix exists"
      PASSED_TESTS+=("flake-exists")

      # Check for Home Manager configuration in flake
      if grep -q "home-manager\|homeManagerConfiguration" "${src}/flake.nix" 2>/dev/null; then
        echo "✅ PASS: Home Manager integration found in flake"
        PASSED_TESTS+=("hm-flake-integration")
      fi

      # Check for shell programs in flake or related configs
      if grep -q "programs\.zsh\|shell.*programs" "${src}/flake.nix" 2>/dev/null || \
         find "${src}/modules" -name "*.nix" -exec grep -l "programs\.zsh" {} \; 2>/dev/null | head -1; then
        echo "✅ PASS: Shell programs integrated with configuration"
        PASSED_TESTS+=("shell-programs-integrated")
      fi
    else
      echo "❌ FAIL: flake.nix not found"
      FAILED_TESTS+=("no-flake")
    fi

    # Section 10: Real-World Workflow Testing
    echo ""
    echo "🔍 Section 10: Real-world workflow testing..."

    # Test complete shell workflow
    if command -v zsh >/dev/null 2>&1 && [[ -f "$home_zshrc" ]]; then
      # Test shell startup time (should be reasonable)
      startup_time=$(time (zsh -c "exit") 2>&1 | grep real | awk '{print $2}' || echo "unknown")
      echo "Shell startup time: $startup_time"

      # Test interactive shell capabilities
      interactive_test=$(zsh -c "source $home_zshrc; echo 'Interactive test successful'" 2>/dev/null)
      if [[ "$interactive_test" == "Interactive test successful" ]]; then
        echo "✅ PASS: Interactive shell capabilities work"
        PASSED_TESTS+=("interactive-shell-works")
      else
        echo "❌ FAIL: Interactive shell capabilities not working"
        FAILED_TESTS+=("interactive-shell-failed")
      fi

      # Test command completion (basic test)
      if zsh -c "source $home_zshrc; compinit; complete -p" >/dev/null 2>&1; then
        echo "✅ PASS: Command completion system functional"
        PASSED_TESTS+=("completion-functional")
      else
        echo "⚠️  INFO: Command completion system may not be fully initialized"
      fi
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
      echo "🔧 Integration test identified ''${#FAILED_TESTS[@]} integration issues"
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} integration tests passed!"
      echo "✅ Zsh & Shell comprehensive integration is working correctly"
      echo ""
      echo "📋 Integration Test Coverage Summary:"
      echo "   ✓ Shell environment integration"
      echo "   ✓ Powerlevel10k integration"
      echo "   ✓ Alias integration testing"
      echo "   ✓ Function integration testing"
      echo "   ✓ Environment variables integration"
      echo "   ✓ Direnv integration testing"
      echo "   ✓ Plugin integration testing"
      echo "   ✓ Cross-platform integration"
      echo "   ✓ Flake integration testing"
      echo "   ✓ Real-world workflow testing"
      exit 0
    fi
  '';

in
pkgs.runCommand "zsh-shell-comprehensive-integration-test"
{
  buildInputs = with pkgs; [ bash zsh findutils gnugrep coreutils ];
} ''
  echo "Running Zsh & Shell comprehensive integration tests..."

  # Run the comprehensive integration test
  ${zshShellIntegrationScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "Zsh & Shell integration test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
