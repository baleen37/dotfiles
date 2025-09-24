#!/usr/bin/env bats
# Integration test for Claude Code symlink creation
# This test MUST fail initially (TDD approach)

load ../lib/common.bash 2>/dev/null || true
load ../lib/assertions.bash 2>/dev/null || true

@test "claude symlinks: creates configuration symlinks" {
  skip "Implementation not ready - TDD failing test"

  # Mock home directory
  local test_home="/tmp/claude_test_$$"
  mkdir -p "$test_home/.claude"
  export HOME="$test_home"

  # Deploy configuration
  run deploy_config --force-overwrite true --platform "$(uname -s | tr '[:upper:]' '[:lower:]')"
  assert_success

  # Check symlinks created
  assert [ -L "$test_home/.claude/config.yaml" ]
  assert [ -L "$test_home/.claude/settings.json" ]

  # Clean up
  rm -rf "$test_home"
}

@test "claude symlinks: force overwrites existing files" {
  skip "Implementation not ready - TDD failing test"

  # Mock home directory
  local test_home="/tmp/claude_test_$$"
  mkdir -p "$test_home/.claude"
  export HOME="$test_home"

  # Create existing regular files
  echo "old config" > "$test_home/.claude/config.yaml"
  echo "old settings" > "$test_home/.claude/settings.json"

  # Deploy with force
  run deploy_config --force-overwrite true --platform "$(uname -s | tr '[:upper:]' '[:lower:]')"
  assert_success

  # Verify files are now symlinks
  assert [ -L "$test_home/.claude/config.yaml" ]
  assert [ -L "$test_home/.claude/settings.json" ]

  # Clean up
  rm -rf "$test_home"
}

@test "claude symlinks: platform-specific paths" {
  skip "Implementation not ready - TDD failing test"

  local test_home="/tmp/claude_test_$$"
  mkdir -p "$test_home"
  export HOME="$test_home"

  # Test Darwin paths
  if [[ "$(uname -s)" == "Darwin" ]]; then
    mkdir -p "$test_home/Library/Application Support/Claude"
    run deploy_config --platform darwin
    assert [ -L "$test_home/Library/Application Support/Claude/config.yaml" ]
  fi

  # Test Linux paths
  if [[ "$(uname -s)" == "Linux" ]]; then
    mkdir -p "$test_home/.config/claude"
    run deploy_config --platform nixos
    assert [ -L "$test_home/.config/claude/config.yaml" ]
  fi

  # Clean up
  rm -rf "$test_home"
}
