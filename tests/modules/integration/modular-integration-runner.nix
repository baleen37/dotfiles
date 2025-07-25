# Modular Integration Test Runner
# Day 16: Green Phase - Optimized integration test execution

{ pkgs, src ? ../../., ... }:

let
  testHelpers = import ../../lib/test-helpers.nix { inherit pkgs; };

  # Efficient integration test runner
  modularIntegrationRunner = pkgs.writeShellScript "modular-integration-runner" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}
    ${testHelpers.measurePerformance}
    ${testHelpers.isolatedTest}

    echo "=== Modular Integration Test Runner ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    measure_start "INTEGRATION_TESTS"

    # Section 1: Component Integration Tests
    echo ""
    echo "🔍 Section 1: Component integration tests..."

    # Test CC alias and CCW function integration
    test_cc_ccw_integration() {
      local cc_alias_found=false
      local ccw_function_found=false

      # Check shell configuration files for both components
      for config_file in "${src}/modules/shared/config/shell/aliases.nix" \
                         "${src}/modules/shared/config/shell/functions.nix"; do
        if [[ -f "$config_file" ]]; then
          # Check for CC alias
          if grep -q "cc.*claude.*dangerously-skip-permissions" "$config_file" 2>/dev/null; then
            cc_alias_found=true
          fi

          # Check for CCW function
          if grep -q "ccw.*function\|ccw.*worktree\|ccw.*=" "$config_file" 2>/dev/null; then
            ccw_function_found=true
          fi
        fi
      done

      if [[ "$cc_alias_found" = "true" && "$ccw_function_found" = "true" ]]; then
        return 0
      else
        return 1
      fi
    }

    run_isolated "cc-ccw-integration" "test_cc_ccw_integration"
    if [[ $? -eq 0 ]]; then
      PASSED_TESTS+=("cc-ccw-integration")
    else
      FAILED_TESTS+=("cc-ccw-integration-failed")
    fi

    # Section 2: Home Manager Integration Tests
    echo ""
    echo "🔍 Section 2: Home Manager integration tests..."

    test_home_manager_integration() {
      local home_manager_configs=("${src}/modules/darwin/home-manager.nix" \
                                  "${src}/modules/shared/home-manager.nix" \
                                  "${src}/home.nix")

      for hm_config in "''${home_manager_configs[@]}"; do
        if [[ -f "$hm_config" ]]; then
          # Check for shell aliases integration
          if grep -q "shellAliases\|shell.*aliases\|aliases.*=" "$hm_config" 2>/dev/null; then
            return 0
          fi
        fi
      done

      return 1
    }

    run_isolated "home-manager-integration" "test_home_manager_integration"
    if [[ $? -eq 0 ]]; then
      PASSED_TESTS+=("home-manager-integration")
    else
      FAILED_TESTS+=("home-manager-integration-failed")
    fi

    # Section 3: Git Integration Tests
    echo ""
    echo "🔍 Section 3: Git integration tests..."

    test_git_integration() {
      # Test git command availability
      if ! command -v git >/dev/null 2>&1; then
        return 1
      fi

      # Test git worktree support
      if ! git worktree --help >/dev/null 2>&1; then
        return 1
      fi

      # Test in current repository if it's a git repo
      if [[ -d "${src}/.git" ]]; then
        cd "${src}"

        # Test git status
        if ! git status >/dev/null 2>&1; then
          return 1
        fi

        # Test git worktree list
        if ! git worktree list >/dev/null 2>&1; then
          return 1
        fi

        cd "$original_dir"
      fi

      return 0
    }

    run_isolated "git-integration" "test_git_integration"
    if [[ $? -eq 0 ]]; then
      PASSED_TESTS+=("git-integration")
    else
      FAILED_TESTS+=("git-integration-failed")
    fi

    measure_end "INTEGRATION_TESTS"

    # Results Summary
    echo ""
    echo "=== Modular Integration Test Results ==="
    echo "✅ Passed tests: ''${#PASSED_TESTS[@]}"
    echo "❌ Failed tests: ''${#FAILED_TESTS[@]}"
    echo "⏱️  Execution time: ''${INTEGRATION_TESTS_DURATION_MS}ms"
    echo "💾 Memory delta: ''${INTEGRATION_TESTS_MEMORY_DELTA_KB}KB"

    if [[ ''${#FAILED_TESTS[@]} -gt 0 ]]; then
      echo ""
      echo "❌ FAILED TESTS:"
      for test in "''${FAILED_TESTS[@]}"; do
        echo "   - $test"
      done
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} modular integration tests passed!"
      exit 0
    fi
  '';

in
pkgs.runCommand "modular-integration-test"
{
  buildInputs = with pkgs; [ bash git findutils gnugrep coreutils ];
} ''
  echo "Running modular integration tests..."

  # Run the modular integration test
  ${modularIntegrationRunner} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "Modular integration test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
