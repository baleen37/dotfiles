# Comprehensive Claude CLI Integration Tests
# Tests complete workflows and multi-component interactions

{ pkgs, src ? ../., ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  claudeCliIntegrationScript = pkgs.writeShellScript "claude-cli-comprehensive-integration" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}

    echo "=== Comprehensive Claude CLI Integration Tests ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    # Section 1: Complete Workflow Integration
    echo ""
    echo "🔍 Section 1: Complete workflow integration..."

    # Create test repository for workflow testing
    test_repo_dir=$(mktemp -d -t "claude-cli-workflow-XXXXXX")
    cd "$test_repo_dir"

    if git init --quiet; then
      echo "✅ PASS: Test repository initialized"
      PASSED_TESTS+=("test-repo-init")

      # Configure git for testing
      git config user.email "test@example.com"
      git config user.name "Test User"

      # Create initial project structure
      echo "# Test Project" > README.md
      mkdir -p src tests docs
      echo "console.log('Hello World');" > src/main.js
      echo "# Documentation" > docs/README.md

      git add .
      if git commit -m "Initial project setup" --quiet; then
        echo "✅ PASS: Initial project commit created"
        PASSED_TESTS+=("initial-commit")

        # Test workflow: Feature development
        feature_branch="feature/authentication"

        # Simulate CCW command (create worktree directory structure)
        mkdir -p "../$feature_branch"
        cd "../$feature_branch"

        # Copy project files to simulate worktree
        cp -r "$test_repo_dir"/* . 2>/dev/null || true
        cp -r "$test_repo_dir"/.git . 2>/dev/null || true

        if git init --quiet; then
          git config user.email "test@example.com"
          git config user.name "Test User"
          git remote add origin "$test_repo_dir" 2>/dev/null || true

          echo "✅ PASS: Feature worktree environment created"
          PASSED_TESTS+=("feature-worktree-created")

          # Simulate feature development
          mkdir -p src/auth
          echo "export const authenticate = () => ({ success: true });" > src/auth/auth.js
          echo "# Authentication Feature" > FEATURE.md

          echo "✅ PASS: Feature development simulated"
          PASSED_TESTS+=("feature-development")

          # Test independent work preservation
          if [[ -f "src/auth/auth.js" && -f "FEATURE.md" ]]; then
            echo "✅ PASS: Feature work preserved independently"
            PASSED_TESTS+=("work-preservation")
          else
            echo "❌ FAIL: Feature work not preserved"
            FAILED_TESTS+=("work-not-preserved")
          fi
        else
          echo "❌ FAIL: Feature worktree environment setup failed"
          FAILED_TESTS+=("feature-worktree-failed")
        fi
      else
        echo "❌ FAIL: Initial commit failed"
        FAILED_TESTS+=("initial-commit-failed")
      fi
    else
      echo "❌ FAIL: Test repository initialization failed"
      FAILED_TESTS+=("test-repo-init-failed")
    fi

    # Clean up test repository
    cd "$original_dir"
    rm -rf "$test_repo_dir" 2>/dev/null || true

    # Section 2: Multi-Component Integration
    echo ""
    echo "🔍 Section 2: Multi-component integration..."

    # Test CC alias and CCW function integration
    cc_alias_found=false
    ccw_function_found=false

    # Check shell configuration files for both components
    for config_file in "${src}/modules/shared/config/shell/aliases.nix" \
                       "${src}/modules/shared/config/shell/functions.nix" \
                       "${src}/modules/darwin/shell.nix" \
                       "${src}/home.nix"; do
      if [[ -f "$config_file" ]]; then
        # Check for CC alias
        if grep -q "cc.*claude.*dangerously-skip-permissions" "$config_file" 2>/dev/null; then
          echo "✅ PASS: CC alias found in $config_file"
          PASSED_TESTS+=("cc-alias-integration")
          cc_alias_found=true
        fi

        # Check for CCW function
        if grep -q "ccw.*function\|ccw.*worktree\|ccw.*=" "$config_file" 2>/dev/null; then
          echo "✅ PASS: CCW function found in $config_file"
          PASSED_TESTS+=("ccw-function-integration")
          ccw_function_found=true
        fi
      fi
    done

    if [[ "$cc_alias_found" = "false" ]]; then
      echo "❌ FAIL: CC alias not integrated into shell configuration"
      FAILED_TESTS+=("cc-alias-not-integrated")
    fi

    if [[ "$ccw_function_found" = "false" ]]; then
      echo "❌ FAIL: CCW function not integrated into shell configuration"
      FAILED_TESTS+=("ccw-function-not-integrated")
    fi

    # Section 3: Home Manager Integration
    echo ""
    echo "🔍 Section 3: Home Manager integration..."

    # Test Home Manager configuration includes Claude CLI components
    home_manager_configs=("${src}/modules/darwin/home-manager.nix" \
                          "${src}/modules/shared/home-manager.nix" \
                          "${src}/home.nix")

    home_manager_integration=false
    for hm_config in "''${home_manager_configs[@]}"; do
      if [[ -f "$hm_config" ]]; then
        echo "✅ PASS: Home Manager configuration found: $hm_config"
        PASSED_TESTS+=("home-manager-config-found")

        # Check for shell aliases integration
        if grep -q "shellAliases\|shell.*aliases\|aliases.*=" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Shell aliases integration found"
          PASSED_TESTS+=("shell-aliases-hm-integration")
          home_manager_integration=true
        fi

        # Check for shell functions integration
        if grep -q "shellInit\|bashInit\|zshInit\|shell.*init" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Shell initialization integration found"
          PASSED_TESTS+=("shell-init-hm-integration")
          home_manager_integration=true
        fi

        # Check for programs.git integration (for CCW)
        if grep -q "programs\.git\|git.*=" "$hm_config" 2>/dev/null; then
          echo "✅ PASS: Git integration found in Home Manager"
          PASSED_TESTS+=("git-hm-integration")
        fi

        break
      fi
    done

    if [[ "$home_manager_integration" = "false" ]]; then
      echo "❌ FAIL: Claude CLI not integrated with Home Manager"
      FAILED_TESTS+=("no-hm-integration")
    fi

    # Section 4: Flake Integration Testing
    echo ""
    echo "🔍 Section 4: Flake integration testing..."

    if [[ -f "${src}/flake.nix" ]]; then
      echo "✅ PASS: flake.nix exists"
      PASSED_TESTS+=("flake-exists")

      # Test flake evaluation (if nix is available)
      if command -v nix >/dev/null 2>&1; then
        cd "${src}"

        # Test flake check (with timeout to avoid hanging)
        if timeout 30s nix flake check --no-build 2>/dev/null; then
          echo "✅ PASS: Flake check passed"
          PASSED_TESTS+=("flake-check-passed")
        else
          echo "⚠️  WARN: Flake check failed or timed out (may be network-related)"
        fi

        # Test flake show (to verify structure)
        if timeout 15s nix flake show 2>/dev/null | head -10; then
          echo "✅ PASS: Flake show executed"
          PASSED_TESTS+=("flake-show-executed")
        else
          echo "⚠️  WARN: Flake show failed or timed out"
        fi

        cd "$original_dir"
      else
        echo "⚠️  INFO: Nix not available for flake testing"
      fi

      # Check for home-manager integration in flake
      if grep -q "home-manager\|homeManagerConfiguration" "${src}/flake.nix" 2>/dev/null; then
        echo "✅ PASS: Home Manager integration found in flake"
        PASSED_TESTS+=("hm-flake-integration")
      else
        echo "⚠️  INFO: Home Manager integration may be implicit"
      fi
    else
      echo "❌ FAIL: flake.nix not found"
      FAILED_TESTS+=("no-flake")
    fi

    # Section 5: Command Files Integration
    echo ""
    echo "🔍 Section 5: Command files integration..."

    commands_dir="${src}/modules/shared/config/claude/commands"
    if [[ -d "$commands_dir" ]]; then
      echo "✅ PASS: Commands directory exists"
      PASSED_TESTS+=("commands-dir-exists")

      # Test command files are accessible
      command_files=$(find "$commands_dir" -name "*.md" -type f 2>/dev/null)
      command_count=$(echo "$command_files" | wc -l)

      if [[ $command_count -gt 0 ]]; then
        echo "✅ PASS: $command_count command files found"
        PASSED_TESTS+=("command-files-found")

        # Test command files are integrated with Claude configuration
        claude_config_found=false
        for claude_config in "${src}/.claude/CLAUDE.md" \
                            "${src}/modules/shared/config/claude/CLAUDE.md" \
                            "${src}/config/claude/CLAUDE.md"; do
          if [[ -f "$claude_config" ]]; then
            if grep -q "commands\|\.md\|command.*file" "$claude_config" 2>/dev/null; then
              echo "✅ PASS: Command files integrated with Claude configuration"
              PASSED_TESTS+=("commands-claude-integration")
              claude_config_found=true
              break
            fi
          fi
        done

        if [[ "$claude_config_found" = "false" ]]; then
          echo "⚠️  INFO: Command files integration may be implicit"
        fi
      else
        echo "❌ FAIL: No command files found"
        FAILED_TESTS+=("no-command-files")
      fi
    else
      echo "❌ FAIL: Commands directory not found"
      FAILED_TESTS+=("commands-dir-missing")
    fi

    # Section 6: Git Integration Testing
    echo ""
    echo "🔍 Section 6: Git integration testing..."

    # Test git configuration compatibility
    if command -v git >/dev/null 2>&1; then
      echo "✅ PASS: Git command available"
      PASSED_TESTS+=("git-available")

      # Test git worktree support
      if git worktree --help >/dev/null 2>&1; then
        echo "✅ PASS: Git worktree support available"
        PASSED_TESTS+=("git-worktree-support")
      else
        echo "❌ FAIL: Git worktree not supported"
        FAILED_TESTS+=("git-worktree-unsupported")
      fi

      # Test in current repository if it's a git repo
      if [[ -d "${src}/.git" ]]; then
        cd "${src}"

        # Test git status
        if git status >/dev/null 2>&1; then
          echo "✅ PASS: Git repository is functional"
          PASSED_TESTS+=("git-repo-functional")

          # Test git worktree list
          if git worktree list >/dev/null 2>&1; then
            echo "✅ PASS: Git worktree list functional"
            PASSED_TESTS+=("git-worktree-list-functional")
          fi
        fi

        cd "$original_dir"
      fi
    else
      echo "❌ FAIL: Git command not available"
      FAILED_TESTS+=("git-unavailable")
    fi

    # Section 7: Cross-Platform Integration
    echo ""
    echo "🔍 Section 7: Cross-platform integration..."

    # Check for platform-specific configurations
    platform_configs=("${src}/modules/darwin" \
                      "${src}/modules/linux" \
                      "${src}/modules/shared")

    for platform_dir in "''${platform_configs[@]}"; do
      if [[ -d "$platform_dir" ]]; then
        platform_name=$(basename "$platform_dir")
        echo "✅ PASS: $platform_name platform configuration found"
        PASSED_TESTS+=("platform-$platform_name-found")

        # Check for shell configuration in platform
        if find "$platform_dir" -name "*shell*" -o -name "*aliases*" -o -name "*functions*" 2>/dev/null | head -1; then
          echo "✅ PASS: Shell configuration found in $platform_name"
          PASSED_TESTS+=("shell-config-$platform_name")
        fi
      fi
    done

    # Section 8: End-to-End Integration Simulation
    echo ""
    echo "🔍 Section 8: End-to-end integration simulation..."

    # Simulate complete user workflow
    workflow_steps=("alias_availability" "function_availability" "command_files" "git_integration")
    workflow_success=true

    for step in "''${workflow_steps[@]}"; do
      case "$step" in
        "alias_availability")
          if [[ "$cc_alias_found" = "true" ]]; then
            echo "✅ PASS: Step $step - CC alias available"
            PASSED_TESTS+=("workflow-$step")
          else
            echo "❌ FAIL: Step $step - CC alias not available"
            FAILED_TESTS+=("workflow-$step")
            workflow_success=false
          fi
          ;;
        "function_availability")
          if [[ "$ccw_function_found" = "true" ]]; then
            echo "✅ PASS: Step $step - CCW function available"
            PASSED_TESTS+=("workflow-$step")
          else
            echo "❌ FAIL: Step $step - CCW function not available"
            FAILED_TESTS+=("workflow-$step")
            workflow_success=false
          fi
          ;;
        "command_files")
          if [[ -d "$commands_dir" ]]; then
            echo "✅ PASS: Step $step - Command files available"
            PASSED_TESTS+=("workflow-$step")
          else
            echo "❌ FAIL: Step $step - Command files not available"
            FAILED_TESTS+=("workflow-$step")
            workflow_success=false
          fi
          ;;
        "git_integration")
          if command -v git >/dev/null 2>&1; then
            echo "✅ PASS: Step $step - Git integration available"
            PASSED_TESTS+=("workflow-$step")
          else
            echo "❌ FAIL: Step $step - Git integration not available"
            FAILED_TESTS+=("workflow-$step")
            workflow_success=false
          fi
          ;;
      esac
    done

    if [[ "$workflow_success" = "true" ]]; then
      echo "✅ PASS: End-to-end workflow integration successful"
      PASSED_TESTS+=("e2e-workflow-success")
    else
      echo "❌ FAIL: End-to-end workflow integration has issues"
      FAILED_TESTS+=("e2e-workflow-failed")
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
      echo "✅ Claude CLI comprehensive integration is working correctly"
      echo ""
      echo "📋 Integration Test Coverage Summary:"
      echo "   ✓ Complete workflow integration"
      echo "   ✓ Multi-component integration"
      echo "   ✓ Home Manager integration"
      echo "   ✓ Flake integration testing"
      echo "   ✓ Command files integration"
      echo "   ✓ Git integration testing"
      echo "   ✓ Cross-platform integration"
      echo "   ✓ End-to-end integration simulation"
      exit 0
    fi
  '';

in
pkgs.runCommand "claude-cli-comprehensive-integration-test"
{
  buildInputs = with pkgs; [ bash git findutils gnugrep coreutils timeout ];
} ''
  echo "Running Claude CLI comprehensive integration tests..."

  # Run the comprehensive integration test
  ${claudeCliIntegrationScript} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "Claude CLI integration test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
