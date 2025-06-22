{ pkgs, flake ? null, src }:
let
  testHelpers = import ../../lib/test-helpers.nix { inherit pkgs; };

in
pkgs.runCommand "workflow-automation-unit-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Refactor Workflow Automation Unit Tests"}

  # Test 1: Workflow orchestration script exists
  ${testHelpers.testSubsection "Workflow Script Infrastructure"}

  # Test that workflow script exists (will fail initially - TDD Red)
  WORKFLOW_SCRIPT="${src}/scripts/refactor-workflow"
  if [ -f "$WORKFLOW_SCRIPT" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Refactor workflow script exists"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Refactor workflow script missing (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test that workflow script is executable
  if [ -x "$WORKFLOW_SCRIPT" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Workflow script is executable"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Workflow script not executable (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test workflow script help functionality
  if "$WORKFLOW_SCRIPT" --help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Workflow script help works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Workflow script help failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 2: Workflow step integration
  ${testHelpers.testSubsection "Workflow Step Integration"}

  # Test that workflow integrates with backup system
  if "$WORKFLOW_SCRIPT" backup --help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Workflow backup integration works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Workflow backup integration failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test that workflow integrates with comparison system
  if "$WORKFLOW_SCRIPT" compare --help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Workflow comparison integration works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Workflow comparison integration failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test that workflow integrates with rollback system
  if "$WORKFLOW_SCRIPT" rollback --help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Workflow rollback integration works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Workflow rollback integration failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 3: Workflow execution modes
  ${testHelpers.testSubsection "Workflow Execution Modes"}

  # Test interactive mode
  if "$WORKFLOW_SCRIPT" --interactive --help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Interactive workflow mode works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Interactive workflow mode failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test automated mode
  if "$WORKFLOW_SCRIPT" --automated --help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Automated workflow mode works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Automated workflow mode failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test dry-run mode
  if "$WORKFLOW_SCRIPT" --dry-run --help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Dry-run workflow mode works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Dry-run workflow mode failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 4: Workflow state management
  ${testHelpers.testSubsection "Workflow State Management"}

  # Test workflow status command
  if "$WORKFLOW_SCRIPT" status >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Workflow status command works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Workflow status command failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test workflow cleanup command
  if "$WORKFLOW_SCRIPT" cleanup >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Workflow cleanup command works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Workflow cleanup command failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 5: Safety and validation
  ${testHelpers.testSubsection "Safety and Validation"}

  # Test that workflow validates current state before proceeding
  if "$WORKFLOW_SCRIPT" validate >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Workflow validation works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Workflow validation failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test that workflow prevents concurrent execution
  if "$WORKFLOW_SCRIPT" --check-lock >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Workflow lock checking works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Workflow lock checking failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 6: Full workflow execution (dry-run)
  ${testHelpers.testSubsection "Full Workflow Execution"}

  # Test complete workflow execution in dry-run mode
  TEMP_CONFIG_DIR=$(mktemp -d)
  if "$WORKFLOW_SCRIPT" run --config-dir "$TEMP_CONFIG_DIR" --dry-run >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Full workflow dry-run execution works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Full workflow dry-run execution failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Cleanup
  rm -rf "$TEMP_CONFIG_DIR"

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Refactor Workflow Automation Unit Tests ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}12${testHelpers.colors.reset}/12"
  echo "${testHelpers.colors.green}✓ All workflow automation tests passed!${testHelpers.colors.reset}"
  touch $out
''
