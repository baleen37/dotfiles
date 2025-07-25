# Modular Unit Test Runner
# Day 16: Green Phase - Optimized unit test execution

{ pkgs, src ? ../../., ... }:

let
  testHelpers = import ../../lib/test-helpers.nix { inherit pkgs; };

  # Lightweight unit test runner with improved performance
  modularUnitRunner = pkgs.writeShellScript "modular-unit-runner" ''
    set -euo pipefail

    ${testHelpers.setupTestEnv}
    ${testHelpers.measurePerformance}

    echo "=== Modular Unit Test Runner ==="

    FAILED_TESTS=()
    PASSED_TESTS=()

    measure_start "UNIT_TESTS"

    # Section 1: Core Component Unit Tests
    echo ""
    echo "🔍 Section 1: Core component unit tests..."

    # Test claude CLI commands structure
    commands_dir="${src}/modules/shared/config/claude/commands"
    if [[ -d "$commands_dir" ]]; then
      echo "✅ PASS: Commands directory exists"
      PASSED_TESTS+=("commands-dir-exists")

      # Optimized file counting (faster than find)
      md_file_count=$(ls -1 "$commands_dir"/*.md 2>/dev/null | wc -l)
      echo "📄 Found $md_file_count command files"

      if [[ $md_file_count -gt 0 ]]; then
        echo "✅ PASS: Command files found ($md_file_count files)"
        PASSED_TESTS+=("command-files-found")
      else
        echo "❌ FAIL: No command files found"
        FAILED_TESTS+=("no-command-files")
      fi
    else
      echo "❌ FAIL: Commands directory not found"
      FAILED_TESTS+=("commands-dir-missing")
    fi

    # Section 2: Shell Integration Unit Tests
    echo ""
    echo "🔍 Section 2: Shell integration unit tests..."

    # Test CC alias configuration
    aliases_file="${src}/modules/shared/config/shell/aliases.nix"
    if [[ -f "$aliases_file" ]]; then
      echo "✅ PASS: Shell aliases configuration exists"
      PASSED_TESTS+=("aliases-config-exists")

      # Optimized grep with early exit
      if grep -q "cc.*claude.*dangerously-skip-permissions" "$aliases_file"; then
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

    # Section 3: Configuration Unit Tests
    echo ""
    echo "🔍 Section 3: Configuration unit tests..."

    # Test for Claude configuration
    claude_config_dirs=("${src}/modules/shared/config/claude" "${src}/.claude")
    claude_config_found=false

    for config_dir in "''${claude_config_dirs[@]}"; do
      if [[ -d "$config_dir" ]]; then
        echo "✅ PASS: Claude configuration directory found: $config_dir"
        PASSED_TESTS+=("claude-config-dir-found")
        claude_config_found=true
        break
      fi
    done

    if [[ "$claude_config_found" = "false" ]]; then
      echo "❌ FAIL: No Claude configuration directory found"
      FAILED_TESTS+=("no-claude-config-dir")
    fi

    measure_end "UNIT_TESTS"

    # Results Summary
    echo ""
    echo "=== Modular Unit Test Results ==="
    echo "✅ Passed tests: ''${#PASSED_TESTS[@]}"
    echo "❌ Failed tests: ''${#FAILED_TESTS[@]}"
    echo "⏱️  Execution time: ''${UNIT_TESTS_DURATION_MS}ms"
    echo "💾 Memory delta: ''${UNIT_TESTS_MEMORY_DELTA_KB}KB"

    if [[ ''${#FAILED_TESTS[@]} -gt 0 ]]; then
      echo ""
      echo "❌ FAILED TESTS:"
      for test in "''${FAILED_TESTS[@]}"; do
        echo "   - $test"
      done
      exit 1
    else
      echo ""
      echo "🎉 All ''${#PASSED_TESTS[@]} modular unit tests passed!"
      exit 0
    fi
  '';

in
pkgs.runCommand "modular-unit-test"
{
  buildInputs = with pkgs; [ bash findutils gnugrep coreutils ];
} ''
  echo "Running modular unit tests..."

  # Run the modular unit test
  ${modularUnitRunner} 2>&1 | tee test-output.log

  # Store results
  echo ""
  echo "Modular unit test completed"
  echo "Results saved to: $out"
  cp test-output.log $out
''
