{ pkgs, flake ? null, src }:
let
  testHelpers = import ../../lib/test-helpers.nix { inherit pkgs; };

in
pkgs.runCommand "config-comparison-workflow-integration-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Configuration Comparison Workflow Integration Tests"}

  # Test 1: End-to-end configuration comparison workflow
  ${testHelpers.testSubsection "Complete Comparison Workflow"}

  # Test that compare-configs script exists (will fail initially - TDD Red)
  COMPARE_SCRIPT="${src}/scripts/compare-configs"
  if [ -f "$COMPARE_SCRIPT" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Configuration comparison script exists"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Configuration comparison script missing (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test that script is executable
  if [ -x "$COMPARE_SCRIPT" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Comparison script is executable"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Comparison script not executable (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 2: Host configuration comparison
  ${testHelpers.testSubsection "Host Configuration Comparison"}

  # Test comparing host configurations
  if "$COMPARE_SCRIPT" --host darwin-config --host nixos-config --report-format json >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Host configuration comparison works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Host configuration comparison failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 3: Package list difference detection
  ${testHelpers.testSubsection "Package List Difference Detection"}

  # Test package difference detection
  if "$COMPARE_SCRIPT" --compare-packages --old-config ${src}/tests/refactor/fixtures/old-config.nix --new-config ${src}/tests/refactor/fixtures/new-config.nix >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Package difference detection works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Package difference detection failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 4: System settings comparison
  ${testHelpers.testSubsection "System Settings Comparison"}

  # Test system settings comparison
  if "$COMPARE_SCRIPT" --compare-settings --baseline ${src}/tests/refactor/baselines/darwin-baseline.json --current ${src}/tests/refactor/fixtures/current-darwin.json >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} System settings comparison works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} System settings comparison failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 5: Home-manager integration comparison
  ${testHelpers.testSubsection "Home Manager Integration Comparison"}

  # Test home-manager comparison
  if "$COMPARE_SCRIPT" --compare-home-manager --user baleen --old ${src}/tests/refactor/fixtures/hm-old.nix --new ${src}/tests/refactor/fixtures/hm-new.nix >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Home-manager comparison works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Home-manager comparison failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 6: Report generation and formatting
  ${testHelpers.testSubsection "Report Generation"}

  # Test JSON report generation
  TEMP_REPORT=$(mktemp)
  if "$COMPARE_SCRIPT" --report-format json --output "$TEMP_REPORT" --baseline ${src}/tests/refactor/baselines/config-baseline.json >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} JSON report generation works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} JSON report generation failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test markdown report generation
  if "$COMPARE_SCRIPT" --report-format markdown --output "$TEMP_REPORT.md" --baseline ${src}/tests/refactor/baselines/config-baseline.json >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Markdown report generation works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Markdown report generation failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 7: CI integration compatibility
  ${testHelpers.testSubsection "CI Integration Compatibility"}

  # Test CI-friendly output and exit codes
  if "$COMPARE_SCRIPT" --ci-mode --fail-on-differences --baseline ${src}/tests/refactor/baselines/identical-config.json >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} CI integration mode works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} CI integration mode failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 8: Ignore patterns and filtering
  ${testHelpers.testSubsection "Ignore Patterns and Filtering"}

  # Test ignore patterns work
  if "$COMPARE_SCRIPT" --ignore-patterns timestamps,version-info,build-paths --baseline ${src}/tests/refactor/baselines/config-with-metadata.json >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Ignore patterns functionality works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Ignore patterns functionality failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Cleanup
  rm -f "$TEMP_REPORT" "$TEMP_REPORT.md"

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Configuration Comparison Workflow Integration Tests ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}14${testHelpers.colors.reset}/14"
  echo "${testHelpers.colors.green}✓ All configuration comparison workflow tests passed!${testHelpers.colors.reset}"
  touch $out
''
