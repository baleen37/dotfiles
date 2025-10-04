#!/usr/bin/env bats
# Integration test for no backup file creation
# This test MUST fail initially (TDD approach)

load ../lib/common.bash 2>/dev/null || true
load ../lib/assertions.bash 2>/dev/null || true

@test "no backups: deployment creates no backup files" {
  skip "Implementation not ready - TDD failing test"

  # Mock home directory
  local test_home="/tmp/no_backup_test_$$"
  mkdir -p "$test_home/.claude"
  export HOME="$test_home"

  # Create existing files
  echo "existing config" >"$test_home/.claude/config.yaml"
  echo "existing settings" >"$test_home/.claude/settings.json"

  # Deploy configuration
  run deploy_config --force-overwrite true
  assert_success

  # Verify NO backup files exist
  run find "$test_home" -name "*.backup" -o -name "*.bak" -o -name "*~"
  assert_output ""

  # Clean up
  rm -rf "$test_home"
}

@test "no backups: clean command finds no backups" {
  skip "Implementation not ready - TDD failing test"

  # Mock home directory
  local test_home="/tmp/no_backup_test_$$"
  mkdir -p "$test_home/.claude"
  export HOME="$test_home"

  # Deploy configuration
  run deploy_config --force-overwrite true
  assert_success

  # Try to clean backups (should find none)
  run clean_backups
  assert_output_contains "No backups found"

  # Clean up
  rm -rf "$test_home"
}

@test "no backups: multiple deployments create no backups" {
  skip "Implementation not ready - TDD failing test"

  # Mock home directory
  local test_home="/tmp/no_backup_test_$$"
  mkdir -p "$test_home/.claude"
  export HOME="$test_home"

  # Deploy multiple times
  for i in {1..3}; do
    echo "config version $i" >"$test_home/.claude/config.yaml"
    run deploy_config --force-overwrite true
    assert_success
  done

  # Still no backup files
  run find "$test_home" -name "*.backup" -o -name "*.bak"
  assert_output ""

  # Only current version exists
  assert [ -f "$test_home/.claude/config.yaml" ] || assert [ -L "$test_home/.claude/config.yaml" ]
  assert_no_file "$test_home/.claude/config.yaml.backup"

  # Clean up
  rm -rf "$test_home"
}
