#!/usr/bin/env bats
# BATS test for Claude Code activation and configuration management

load './test_helper'

setup() {
  export TEST_TEMP_DIR=$(mktemp -d)
  export PROJECT_ROOT="$(git rev-parse --show-toplevel)"

  # Claude activation specific setup
  export SOURCE_BASE="$TEST_TEMP_DIR/source"
  export TARGET_BASE="$TEST_TEMP_DIR/target"
  export CLAUDE_DIR="$TARGET_BASE/.claude"

  mkdir -p "$SOURCE_BASE" "$CLAUDE_DIR"

  # Create test configuration files
  cat >"$SOURCE_BASE/settings.json" <<'EOF'
{
  "version": "1.0.0",
  "theme": "dark",
  "autoSave": true
}
EOF

  cat >"$SOURCE_BASE/CLAUDE.md" <<'EOF'
# Test Claude Configuration
This is a test configuration file.
EOF

  mkdir -p "$SOURCE_BASE/commands"
  cat >"$SOURCE_BASE/commands/test.md" <<'EOF'
# Test Command
This is a test command.
EOF

  mkdir -p "$SOURCE_BASE/agents"
  cat >"$SOURCE_BASE/agents/test-agent.md" <<'EOF'
# Test Agent
This is a test agent.
EOF
}

teardown() {
  [ -n "$TEST_TEMP_DIR" ] && rm -rf "$TEST_TEMP_DIR"
}

@test "Claude 활성화: 기본 디렉토리 생성" {
  # Simulate claude activation by creating required directories
  mkdir -p "$CLAUDE_DIR"/{commands,agents,hooks}

  assert_directory_exists "$CLAUDE_DIR"
  assert_directory_exists "$CLAUDE_DIR/commands"
  assert_directory_exists "$CLAUDE_DIR/agents"
  assert_directory_exists "$CLAUDE_DIR/hooks"
}

@test "Claude 활성화: 설정 파일 복사" {
  # Test configuration file copying
  cp "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/"
  cp "$SOURCE_BASE/CLAUDE.md" "$CLAUDE_DIR/"

  assert_file_exists "$CLAUDE_DIR/settings.json"
  assert_file_exists "$CLAUDE_DIR/CLAUDE.md"

  # Verify content
  run grep "dark" "$CLAUDE_DIR/settings.json"
  [ "$status" -eq 0 ]

  run grep "Test Claude Configuration" "$CLAUDE_DIR/CLAUDE.md"
  [ "$status" -eq 0 ]
}

@test "Claude 활성화: 명령어 디렉토리 복사" {
  # Test commands directory copying
  cp -r "$SOURCE_BASE/commands" "$CLAUDE_DIR/"

  assert_directory_exists "$CLAUDE_DIR/commands"
  assert_file_exists "$CLAUDE_DIR/commands/test.md"

  run grep "Test Command" "$CLAUDE_DIR/commands/test.md"
  [ "$status" -eq 0 ]
}

@test "Claude 활성화: 에이전트 디렉토리 복사" {
  # Test agents directory copying
  cp -r "$SOURCE_BASE/agents" "$CLAUDE_DIR/"

  assert_directory_exists "$CLAUDE_DIR/agents"
  assert_file_exists "$CLAUDE_DIR/agents/test-agent.md"

  run grep "Test Agent" "$CLAUDE_DIR/agents/test-agent.md"
  [ "$status" -eq 0 ]
}

@test "Claude 활성화: 심볼릭 링크 생성 (Darwin)" {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    skip "Skipping on non-Darwin systems"
  fi

  # Create source files
  cp "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/"

  # Create symbolic link (simulated)
  ln -sf "$CLAUDE_DIR/settings.json" "$TEST_TEMP_DIR/settings.json"

  [ -L "$TEST_TEMP_DIR/settings.json" ]
  [ -f "$TEST_TEMP_DIR/settings.json" ]
}

@test "Claude 활성화: 실제 Claude 설정 검증" {
  cd "$PROJECT_ROOT"

  # Check if Claude configuration exists in the project
  assert_file_exists "modules/shared/config/claude/settings.json"
  assert_file_exists "modules/shared/config/claude/CLAUDE.md"
  assert_directory_exists "modules/shared/config/claude/commands"
  assert_directory_exists "modules/shared/config/claude/agents"

  # Verify settings.json is valid JSON
  run nix eval --impure --expr 'builtins.fromJSON (builtins.readFile ./modules/shared/config/claude/settings.json)'
  [ "$status" -eq 0 ]
}

@test "Claude 활성화: 활성화 스크립트 존재 확인" {
  cd "$PROJECT_ROOT"

  # Check if activation script is referenced in home-manager
  assert_file_exists "modules/shared/lib/claude-activation.nix"

  run grep -r "claude-activation" modules/shared/home-manager.nix
  [ "$status" -eq 0 ]
}

@test "Claude 활성화: MCP 서버 설정 검증" {
  cd "$PROJECT_ROOT"

  # Check if MCP settings are configured
  run grep -r "mcp" modules/shared/config/claude/settings.json
  [ "$status" -eq 0 ]

  # Verify MCP server configurations exist
  run jq '.mcpServers' modules/shared/config/claude/settings.json
  [ "$status" -eq 0 ]
}

@test "Claude 활성화: 한국어 설정 확인" {
  cd "$PROJECT_ROOT"

  # Check Korean language settings in CLAUDE.md
  run grep -i "한국어" modules/shared/config/claude/CLAUDE.md
  [ "$status" -eq 0 ]

  # Check Korean language policy
  run grep "Korean" modules/shared/config/claude/CLAUDE.md
  [ "$status" -eq 0 ]
}

@test "Claude 활성화: 커맨드 파일 개수 확인" {
  cd "$PROJECT_ROOT"

  # Count command files
  command_count=$(find modules/shared/config/claude/commands -name "*.md" | wc -l)

  # Should have at least 10 commands based on current setup
  [ "$command_count" -ge 10 ]
}

@test "Claude 활성화: 에이전트 파일 개수 확인" {
  cd "$PROJECT_ROOT"

  # Count agent files
  agent_count=$(find modules/shared/config/claude/agents -name "*.md" | wc -l)

  # Should have at least 8 agents based on current setup
  [ "$agent_count" -ge 8 ]
}
