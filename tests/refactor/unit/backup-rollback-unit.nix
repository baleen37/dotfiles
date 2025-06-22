{ pkgs, flake ? null, src }:
let
  testHelpers = import ../../lib/test-helpers.nix { inherit pkgs; };

in
pkgs.runCommand "backup-rollback-unit-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Backup and Rollback Unit Tests"}

  # Test 1: Backup script functionality
  ${testHelpers.testSubsection "Backup Script Infrastructure"}

  # Test that backup script exists (will fail initially - TDD Red)
  BACKUP_SCRIPT="${src}/scripts/refactor-backup"
  if [ -f "$BACKUP_SCRIPT" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Backup script exists"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Backup script missing (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test that backup script is executable
  if [ -x "$BACKUP_SCRIPT" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Backup script is executable"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Backup script not executable (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test backup script help functionality
  if "$BACKUP_SCRIPT" --help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Backup script help works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Backup script help failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 2: Rollback script functionality
  ${testHelpers.testSubsection "Rollback Script Infrastructure"}

  # Test that rollback script exists (will fail initially - TDD Red)
  ROLLBACK_SCRIPT="${src}/scripts/refactor-rollback"
  if [ -f "$ROLLBACK_SCRIPT" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Rollback script exists"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Rollback script missing (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test that rollback script is executable
  if [ -x "$ROLLBACK_SCRIPT" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Rollback script is executable"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Rollback script not executable (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test rollback script help functionality
  if "$ROLLBACK_SCRIPT" --help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Rollback script help works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Rollback script help failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 3: Backup functionality (will fail initially)
  ${testHelpers.testSubsection "Backup Functionality"}

  # Test backup creation
  TEMP_BACKUP_DIR=$(mktemp -d)
  if "$BACKUP_SCRIPT" create --output "$TEMP_BACKUP_DIR" >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Backup creation works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Backup creation failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test backup validation
  if "$BACKUP_SCRIPT" validate --backup "$TEMP_BACKUP_DIR" >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Backup validation works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Backup validation failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 4: Rollback functionality (will fail initially)
  ${testHelpers.testSubsection "Rollback Functionality"}

  # Test rollback execution
  if "$ROLLBACK_SCRIPT" restore --backup "$TEMP_BACKUP_DIR" >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Rollback execution works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Rollback execution failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Test 5: Configuration validation integration
  ${testHelpers.testSubsection "Configuration Validation Integration"}

  # Test that backup validates configuration builds
  if "$BACKUP_SCRIPT" create --validate-build >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Backup validates configuration builds"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Backup build validation failed (EXPECTED FAILURE - TDD Red)"
    exit 1
  fi

  # Cleanup
  rm -rf "$TEMP_BACKUP_DIR"

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Backup and Rollback Unit Tests ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}10${testHelpers.colors.reset}/10"
  echo "${testHelpers.colors.green}✓ All backup and rollback tests passed!${testHelpers.colors.reset}"
  touch $out
''