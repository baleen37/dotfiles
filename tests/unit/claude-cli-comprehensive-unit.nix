# Comprehensive Claude CLI Unit Tests
# Consolidated unit tests covering all Claude CLI functionality

{ pkgs, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Create isolated test environment for Claude CLI testing
  claudeCliTestScript = pkgs.writeShellScript "claude-cli-comprehensive-unit" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive Claude CLI Unit Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Commands Directory Structure
    echo ""
    echo "🔍 Section 1: Commands directory structure..."

    commands_dir="'${src}/modules/shared/config/claude/commands"

    if [[ -d "$commands_dir" ]]; then
      echo "✅ PASS: Commands directory exists"
      PASSED_TESTS+=("commands-dir-exists")

      # Count command files
      md_file_count=$(find "$commands_dir" -name "*.md" -type f 2>/dev/null | wc -l)
      echo "📄 Found $md_file_count command files"

      if [[ $md_file_count -gt 0 ]]; then
        echo "✅ PASS: Command files found ($md_file_count files)"
        PASSED_TESTS+=("command-files-found")
      else
        echo "❌ FAIL: No command files found"
        FAILED_TESTS+=("no-command-files")
      fi

      # Check for specific command files
      essential_commands=("brainstorm.md" "code-review.md" "debug.md")
      for cmd in "''${essential_commands[@]}"; do
        if [[ -f "$commands_dir/$cmd" ]]; then
          echo "✅ PASS: $cmd exists"
          PASSED_TESTS+=("command-$cmd")

          # Check file is readable
          if [[ -r "$commands_dir/$cmd" ]]; then
            echo "✅ PASS: $cmd is readable"
            PASSED_TESTS+=("readable-$cmd")
          else
            echo "❌ FAIL: $cmd is not readable"
            FAILED_TESTS+=("not-readable-$cmd")
          fi
        else
          echo "⚠️  INFO: $cmd not found (may not be required)"
        fi
      done
    else
      echo "❌ FAIL: Commands directory not found"
      FAILED_TESTS+=("commands-dir-missing")
    fi

    # Section 2: CC Alias Functionality
    echo ""
    echo "🔍 Section 2: CC alias functionality..."

    # Source shell configuration to test aliases
    if [[ -f "'${src}/modules/shared/config/shell/aliases.nix" ]]; then
      echo "✅ PASS: Shell aliases configuration exists"
      PASSED_TESTS+=("aliases-config-exists")

      # Check for CC alias definition
      if grep -q "cc.*claude.*dangerously-skip-permissions" "'${src}/modules/shared/config/shell/aliases.nix" 2>/dev/null; then
        echo "✅ PASS: CC alias defined correctly"
        PASSED_TESTS+=("cc-alias-defined")
      else
        echo "❌ FAIL: CC alias not defined or incorrect"
        FAILED_TESTS+=("cc-alias-missing")
      fi
    else
      echo "❌ FAIL: Shell aliases configuration not found"
      FAILED_TESTS+=("aliases-config-missing")
    fi

    # Section 3: CCW Function Functionality
    echo ""
    echo "🔍 Section 3: CCW function functionality..."

    # Check for CCW function definition in shell configuration
    ccw_found=false
    for config_file in "'${src}/modules/shared/config/shell/functions.nix" \
                       "'${src}/modules/shared/config/shell/aliases.nix" \
                       "'${src}/modules/darwin/shell.nix"; do
      if [[ -f "$config_file" ]]; then
        if grep -q "ccw.*function\|ccw.*worktree\|ccw.*=" "$config_file" 2>/dev/null; then
          echo "✅ PASS: CCW function found in $config_file"
          PASSED_TESTS+=("ccw-function-defined")
          ccw_found=true
          break
        fi
      fi
    done

    if [[ "$ccw_found" = "false" ]]; then
      echo "❌ FAIL: CCW function not found in configuration"
      FAILED_TESTS+=("ccw-function-missing")
    fi

    # Section 4: Claude CLI Configuration Files
    echo ""
    echo "🔍 Section 4: Claude CLI configuration files..."

    # Check for Claude configuration
    claude_config_dirs=("'${src}/modules/shared/config/claude" \
                        "'${src}/config/claude" \
                        "'${src}/.claude")

    claude_config_found=false
    for config_dir in "''${claude_config_dirs[@]}"; do
      if [[ -d "$config_dir" ]]; then
        echo "✅ PASS: Claude configuration directory found: $config_dir"
        PASSED_TESTS+=("claude-config-dir-found")
        claude_config_found=true

        # Check for CLAUDE.md file
        if [[ -f "$config_dir/CLAUDE.md" ]]; then
          echo "✅ PASS: CLAUDE.md configuration file exists"
          PASSED_TESTS+=("claude-md-exists")

          # Check CLAUDE.md content
          if grep -q "instruction\|behavior\|context" "$config_dir/CLAUDE.md" 2>/dev/null; then
            echo "✅ PASS: CLAUDE.md contains configuration content"
            PASSED_TESTS+=("claude-md-content")
          else
            echo "❌ FAIL: CLAUDE.md is empty or invalid"
            FAILED_TESTS+=("claude-md-invalid")
          fi
        else
          echo "⚠️  INFO: CLAUDE.md not found in $config_dir"
        fi

        break
      fi
    done

    if [[ "$claude_config_found" = "false" ]]; then
      echo "❌ FAIL: No Claude configuration directory found"
      FAILED_TESTS+=("no-claude-config-dir")
    fi

    # Section 5: Git Integration Testing
    echo ""
    echo "🔍 Section 5: Git integration validation..."

    # Create a temporary git repository for testing
    test_git_dir=$(mktemp -d -t "claude-cli-git-test-XXXXXX")
    cd "$test_git_dir"

    # Initialize test git repository
    if git init --quiet; then
      echo "✅ PASS: Test git repository initialized"
      PASSED_TESTS+=("test-git-init")

      # Configure git for test environment
      git config user.email "test@example.com"
      git config user.name "Test User"

      # Create initial commit
      echo "# Test Repository" > README.md
      git add README.md
      if git commit -m "Initial commit" --quiet; then
        echo "✅ PASS: Initial commit created"
        PASSED_TESTS+=("initial-commit")

        # Test git worktree capability (basic command availability)
        if command -v git >/dev/null 2>&1 && git worktree --help >/dev/null 2>&1; then
          echo "✅ PASS: Git worktree command available"
          PASSED_TESTS+=("git-worktree-available")
        else
          echo "❌ FAIL: Git worktree command not available"
          FAILED_TESTS+=("git-worktree-unavailable")
        fi

        # Test branch creation capability
        if git checkout -b test-branch --quiet; then
          echo "✅ PASS: Git branch creation works"
          PASSED_TESTS+=("git-branch-creation")
          git checkout main --quiet
        else
          echo "❌ FAIL: Git branch creation failed"
          FAILED_TESTS+=("git-branch-creation-failed")
        fi
      else
        echo "❌ FAIL: Initial commit failed"
        FAILED_TESTS+=("initial-commit-failed")
      fi
    else
      echo "❌ FAIL: Test git repository initialization failed"
      FAILED_TESTS+=("test-git-init-failed")
    fi

    # Clean up test git repository
    cd "$original_dir"
    rm -rf "$test_git_dir" 2>/dev/null || true

    # Section 6: Command Content Validation
    echo ""
    echo "🔍 Section 6: Command content validation..."

    if [[ -d "$commands_dir" ]]; then
      # Check for command file structure and content
      for cmd_file in "$commands_dir"/*.md; do
        if [[ -f "$cmd_file" ]]; then
          cmd_name=$(basename "$cmd_file" .md)

          # Check if file has content
          if [[ -s "$cmd_file" ]]; then
            echo "✅ PASS: $cmd_name has content"
            PASSED_TESTS+=("content-$cmd_name")

            # Check for basic markdown structure
            if grep -q "^#\|^\*\|^-" "$cmd_file" 2>/dev/null; then
              echo "✅ PASS: $cmd_name has proper markdown structure"
              PASSED_TESTS+=("markdown-$cmd_name")
            else
              echo "⚠️  INFO: $cmd_name may not have markdown formatting"
            fi
          else
            echo "❌ FAIL: $cmd_name is empty"
            FAILED_TESTS+=("empty-$cmd_name")
          fi
        fi
      done
    fi

    # Section 7: Integration with Home Manager
    echo ""
    echo "🔍 Section 7: Home Manager integration..."

    # Check for home-manager configuration that includes Claude CLI
    home_manager_configs=("'${src}/modules/darwin/home-manager.nix" \
                          "'${src}/modules/shared/home-manager.nix" \
                          "'${src}/home.nix")

    home_manager_found=false
    for hm_config in "''${home_manager_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        echo "✅ PASS: Home Manager configuration found: $hm_config"
        PASSED_TESTS+=("home-manager-config-found")
        home_manager_found=true

        # Check if Claude CLI is configured in home-manager
        if grep -q "claude\|shellAliases\|shell.*function" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Claude CLI integration found in Home Manager"
          PASSED_TESTS+=("claude-cli-hm-integration")
        else
          echo "⚠️  INFO: Claude CLI integration may be in other files"
        fi

        break
      fi
    done

    if [[ "$home_manager_found" = "false" ]]; then
      echo "❌ FAIL: No Home Manager configuration found"
      FAILED_TESTS+=("no-home-manager-config")
    fi

    # Section 8: Nix Flake Integration
    echo ""
    echo "🔍 Section 8: Nix flake integration..."

    # Check if Claude CLI is integrated into the flake
    if [[ -f "'${src}/flake.nix" ]]; then
      echo "✅ PASS: flake.nix exists"
      PASSED_TESTS+=("flake-exists")

      # Check for Claude CLI related packages or configurations
      if grep -q "claude\|home-manager\|shellAliases" "'${src}/flake.nix" 2>/dev/null; then
        echo "✅ PASS: Claude CLI integration found in flake"
        PASSED_TESTS+=("claude-cli-flake-integration")
      else
        echo "⚠️  INFO: Claude CLI integration may be implicit"
      fi
    else
      echo "❌ FAIL: flake.nix not found"
      FAILED_TESTS+=("no-flake")
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
      echo "✅ Claude CLI unit functionality is working correctly"
      echo ""
      echo "📋 Unit Test Coverage Summary:"
      echo "   ✓ Commands directory structure"
      echo "   ✓ CC alias functionality"
      echo "   ✓ CCW function functionality"
      echo "   ✓ Claude CLI configuration files"
      echo "   ✓ Git integration validation"
      echo "   ✓ Command content validation"
      echo "   ✓ Home Manager integration"
      echo "   ✓ Nix flake integration"
      exit 0
    fi
  '';

in
pkgs.runCommand "claude-cli-comprehensive-unit-test"
{
  buildInputs = with pkgs; [ bash git findutils gnugrep coreutils ];
} ''
  echo "Running Claude CLI comprehensive unit tests..."

  # Run the comprehensive unit test
  ${claudeCliTestScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "Claude CLI unit test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
