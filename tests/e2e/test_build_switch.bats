#!/usr/bin/env bats
# T012: E2E test for build-switch success
# TDD: This test MUST fail initially

load '../lib/common.sh'
load '../lib/test-framework.sh'

setup() {
  # Setup test environment
  export TEST_HOME=$(mktemp -d)
  export TEST_CLAUDE_DIR="$TEST_HOME/.claude"
  export NIXOS_CONFIG_PATH="$TEST_HOME/nixos-config"

  # Create test directories
  mkdir -p "$TEST_CLAUDE_DIR/commands"
  mkdir -p "$NIXOS_CONFIG_PATH"

  # Mock original locations
  export ORIGINAL_CLAUDE_DIR="/home/ubuntu/.claude"
  export ORIGINAL_NIXOS_CONFIG="/etc/nixos"
}

teardown() {
  # Cleanup test environment
  rm -rf "$TEST_HOME"
}

@test "build-switch completes successfully with Claude Code configuration" {
  # Given: A clean system with Claude Code configuration
  setup_claude_code_config

  # When: Running build-switch command
  run nixos-rebuild build-switch --flake /home/ubuntu/dev/dotfiles

  # Then: Build succeeds
  [[ $status -eq 0 ]] || fail "Expected build-switch to succeed but got exit code $status"
  assert_contains "$output" "built successfully"

  # And: Claude Code symlinks are created
  assert_file_exists "/home/ubuntu/.claude/commands"
  assert_symlink "/home/ubuntu/.claude/commands"

  # And: No backup files are created
  assert_no_backup_files "/home/ubuntu/.claude"

  # And: Configuration is properly deployed
  assert_claude_code_active
}

@test "build-switch handles existing Claude Code configuration gracefully" {
  skip "TDD: Test implementation pending - must fail first"

  # Given: Existing Claude Code configuration
  setup_existing_claude_config

  # When: Running build-switch command
  run nixos-rebuild build-switch --flake /home/ubuntu/dev/dotfiles

  # Then: Build succeeds without conflicts
  assert_success

  # And: Existing configuration is preserved where appropriate
  assert_claude_config_preserved

  # And: New configuration is applied
  assert_claude_code_active
}

@test "build-switch fails gracefully on configuration errors" {
  skip "TDD: Test implementation pending - must fail first"

  # Given: Invalid Claude Code configuration
  setup_invalid_claude_config

  # When: Running build-switch command
  run nixos-rebuild build-switch --flake /home/ubuntu/dev/dotfiles

  # Then: Build fails with clear error message
  assert_failure
  assert_output_contains "Claude Code configuration error"

  # And: System remains in clean state
  assert_no_partial_configuration
}

@test "build-switch rollback works correctly" {
  skip "TDD: Test implementation pending - must fail first"

  # Given: A working configuration
  setup_working_claude_config
  run nixos-rebuild build-switch --flake /home/ubuntu/dev/dotfiles
  assert_success

  # When: Configuration breaks and rollback is needed
  setup_broken_claude_config
  run nixos-rebuild rollback

  # Then: System returns to working state
  assert_success
  assert_claude_code_active
}

# Helper functions (these will fail until implemented)
setup_claude_code_config() {
  # Setup test Claude Code configuration
  echo "# Test Claude Code config" >"$TEST_CLAUDE_DIR/CLAUDE.md"
  mkdir -p "$TEST_CLAUDE_DIR/commands"
  echo "test command" >"$TEST_CLAUDE_DIR/commands/test.md"
}

setup_existing_claude_config() {
  # Create existing configuration
  setup_claude_code_config
  echo "existing config" >"$TEST_CLAUDE_DIR/existing.md"
}

setup_invalid_claude_config() {
  # Create invalid configuration that should cause build failure
  echo "invalid config" >"$TEST_CLAUDE_DIR/invalid.conf"
}

setup_working_claude_config() {
  setup_claude_code_config
}

setup_broken_claude_config() {
  # Break the configuration
  rm -rf "$TEST_CLAUDE_DIR"
}

assert_claude_code_active() {
  # Verify Claude Code is properly configured and active
  assert_file_exists "/home/ubuntu/.claude/commands"
  assert_file_exists "/home/ubuntu/.claude/CLAUDE.md"
}

assert_claude_config_preserved() {
  # Verify existing configuration elements are preserved
  assert_file_exists "$TEST_CLAUDE_DIR/existing.md"
  assert_contains "$(cat "$TEST_CLAUDE_DIR/existing.md")" "existing config"
}

assert_no_backup_files() {
  local claude_dir="$1"
  # Check for backup files (files ending in .backup, .bak, .orig, etc.)
  local backup_files=$(find "$claude_dir" -name "*.backup" -o -name "*.bak" -o -name "*.orig" 2>/dev/null || true)
  [[ -z $backup_files ]] || fail "Found backup files: $backup_files"
}

assert_symlink_valid() {
  local symlink_path="$1"
  assert_symlink "$symlink_path"
  [[ -e $symlink_path ]] || fail "Symlink $symlink_path is broken (target doesn't exist)"
}

assert_no_partial_configuration() {
  # Verify no partial/broken configuration remains
  if [[ -d "/home/ubuntu/.claude" ]]; then
    assert_symlink_valid "/home/ubuntu/.claude/commands" || {
      fail "Partial configuration detected - broken symlinks found"
    }
  fi
}
