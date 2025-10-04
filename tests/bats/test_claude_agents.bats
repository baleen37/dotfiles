#!/usr/bin/env bats
# BATS test for Claude Code agents system and configuration validation

load './test_helper'

setup() {
  export TEST_TEMP_DIR=$(mktemp -d)
  export PROJECT_ROOT="$(git rev-parse --show-toplevel)"

  # Claude agents specific setup
  export CLAUDE_CONFIG_DIR="$PROJECT_ROOT/modules/shared/config/claude"
  export AGENTS_DIR="$CLAUDE_CONFIG_DIR/agents"
  export COMMANDS_DIR="$CLAUDE_CONFIG_DIR/commands"
  export HOOKS_DIR="$CLAUDE_CONFIG_DIR/hooks"
  export SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"

  # Ensure we can access the directories
  [ -d "$CLAUDE_CONFIG_DIR" ] || skip "Claude config directory not found"
}

teardown() {
  [ -n "$TEST_TEMP_DIR" ] && rm -rf "$TEST_TEMP_DIR"
}

# Agent Configuration Tests
@test "Claude 에이전트: 에이전트 설정 디렉토리 존재 확인" {
  [ -d "$AGENTS_DIR" ]
}

@test "Claude 에이전트: 기본 에이전트 파일들 존재 확인" {
  local expected_agents=(
    "test-automator.md"
    "backend-architect.md"
    "code-reviewer.md"
    "git-specialist.md"
    "debugger.md"
    "context-manager.md"
    "javascript-pro.md"
    "python-pro.md"
    "frontend-developer.md"
    "devops-troubleshooter.md"
  )

  for agent in "${expected_agents[@]}"; do
    [ -f "$AGENTS_DIR/$agent" ] || {
      echo "Missing agent file: $agent"
      return 1
    }
  done
}

@test "Claude 에이전트: 에이전트 파일 front matter 구문 검증" {
  for agent_file in "$AGENTS_DIR"/*.md; do
    [ -f "$agent_file" ] || continue

    # Check for YAML front matter
    run grep -q "^---$" "$agent_file"
    [ "$status" -eq 0 ] || {
      echo "No YAML front matter found in $(basename "$agent_file")"
      return 1
    }

    # Check for required fields in front matter
    run grep -A 10 "^---$" "$agent_file" | grep -E "^(name|description|model):"
    [ "$status" -eq 0 ] || {
      echo "Missing required front matter fields in $(basename "$agent_file")"
      return 1
    }
  done
}

@test "Claude 에이전트: test-automator 에이전트 상세 검증" {
  local test_automator="$AGENTS_DIR/test-automator.md"
  [ -f "$test_automator" ]

  # Check specific content for test-automator
  run grep -q "test-automator" "$test_automator"
  [ "$status" -eq 0 ]

  run grep -q "test automation" "$test_automator"
  [ "$status" -eq 0 ]

  run grep -q "TDD" "$test_automator"
  [ "$status" -eq 0 ]

  # Check model specification
  run grep -q "model: sonnet" "$test_automator"
  [ "$status" -eq 0 ]
}

# Command Configuration Tests
@test "Claude 에이전트: 명령어 설정 디렉토리 존재 확인" {
  [ -d "$COMMANDS_DIR" ]
}

@test "Claude 에이전트: 기본 명령어 파일들 존재 확인" {
  local expected_commands=(
    "test.md"
    "debug.md"
    "implement.md"
    "analyze.md"
    "explain.md"
    "improve.md"
    "build.md"
    "cleanup.md"
    "create-pr.md"
    "fix-pr.md"
  )

  for command in "${expected_commands[@]}"; do
    [ -f "$COMMANDS_DIR/$command" ] || {
      echo "Missing command file: $command"
      return 1
    }
  done
}

@test "Claude 에이전트: 명령어 파일 front matter 구문 검증" {
  for cmd_file in "$COMMANDS_DIR"/*.md; do
    [ -f "$cmd_file" ] || continue

    # Check for YAML front matter
    run grep -q "^---$" "$cmd_file"
    [ "$status" -eq 0 ] || {
      echo "No YAML front matter found in $(basename "$cmd_file")"
      return 1
    }

    # Check for required fields
    run grep -A 10 "^---$" "$cmd_file" | grep -E "^(name|description):"
    [ "$status" -eq 0 ] || {
      echo "Missing required front matter fields in $(basename "$cmd_file")"
      return 1
    }
  done
}

@test "Claude 에이전트: test 명령어 상세 검증" {
  local test_command="$COMMANDS_DIR/test.md"
  [ -f "$test_command" ]

  # Check specific content
  run grep -q "name: test" "$test_command"
  [ "$status" -eq 0 ]

  run grep -q "Run tests" "$test_command"
  [ "$status" -eq 0 ]

  run grep -q "coverage" "$test_command"
  [ "$status" -eq 0 ]
}

# Settings Configuration Tests
@test "Claude 에이전트: settings.json 파일 존재 확인" {
  [ -f "$SETTINGS_FILE" ]
}

@test "Claude 에이전트: settings.json JSON 구문 검증" {
  run python3 -m json.tool "$SETTINGS_FILE"
  [ "$status" -eq 0 ] || {
    echo "Invalid JSON syntax in settings.json"
    return 1
  }
}

@test "Claude 에이전트: settings.json 필수 섹션 존재 확인" {
  local required_sections=(
    "permissions"
    "model"
    "hooks"
    "statusLine"
  )

  for section in "${required_sections[@]}"; do
    run jq -e ".$section" "$SETTINGS_FILE"
    [ "$status" -eq 0 ] || {
      echo "Missing required section: $section"
      return 1
    }
  done
}

@test "Claude 에이전트: permissions 설정 검증" {
  # Check for allowed permissions
  run jq -e '.permissions.allow | length > 0' "$SETTINGS_FILE"
  [ "$status" -eq 0 ]

  # Check for specific critical permissions
  local critical_permissions=(
    "Bash(*)"
    "Write"
    "Edit"
    "Read"
    "Grep"
    "Glob"
  )

  for permission in "${critical_permissions[@]}"; do
    run jq -e --arg perm "$permission" '.permissions.allow | contains([$perm])' "$SETTINGS_FILE"
    [ "$status" -eq 0 ] || {
      echo "Missing critical permission: $permission"
      return 1
    }
  done
}

@test "Claude 에이전트: MCP 서버 설정 검증" {
  # Check MCP server permissions
  run jq -e '.permissions.allow | map(select(startswith("mcp__"))) | length > 0' "$SETTINGS_FILE"
  [ "$status" -eq 0 ]

  # Check enableAllProjectMcpServers
  run jq -e '.enableAllProjectMcpServers == true' "$SETTINGS_FILE"
  [ "$status" -eq 0 ]
}

# Hooks Configuration Tests
@test "Claude 에이전트: hooks 디렉토리 존재 확인" {
  [ -d "$HOOKS_DIR" ]
}

@test "Claude 에이전트: hooks 설정 구조 검증" {
  local hook_types=(
    "PreToolUse"
    "PostToolUse"
    "UserPromptSubmit"
  )

  for hook_type in "${hook_types[@]}"; do
    run jq -e ".hooks.$hook_type" "$SETTINGS_FILE"
    [ "$status" -eq 0 ] || {
      echo "Missing hook type: $hook_type"
      return 1
    }
  done
}

@test "Claude 에이전트: hook 스크립트 파일들 존재 확인" {
  local expected_hooks=(
    "git-commit-validator.py"
    "claude_code_message_cleaner.py"
    "append_ultrathink.py"
  )

  for hook in "${expected_hooks[@]}"; do
    [ -f "$HOOKS_DIR/$hook" ] || {
      echo "Missing hook script: $hook"
      return 1
    }
  done
}

@test "Claude 에이전트: hook 스크립트 실행 권한 검증" {
  for hook_file in "$HOOKS_DIR"/*.py; do
    [ -f "$hook_file" ] || continue

    # Check if file is readable
    [ -r "$hook_file" ] || {
      echo "Hook script not readable: $(basename "$hook_file")"
      return 1
    }

    # Check Python syntax
    run python3 -m py_compile "$hook_file"
    [ "$status" -eq 0 ] || {
      echo "Python syntax error in: $(basename "$hook_file")"
      return 1
    }
  done
}

# Integration Tests
@test "Claude 에이전트: 전체 설정 파일 무결성 검증" {
  # Test that all referenced files exist
  local hook_commands
  hook_commands=$(jq -r '.hooks[][] | select(.type == "command") | .command' "$SETTINGS_FILE" 2>/dev/null)

  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue

    # Convert ~/.claude paths to actual paths
    local actual_path="${cmd/#~\/.claude/$HOOKS_DIR}"

    [ -f "$actual_path" ] || {
      echo "Referenced hook command not found: $cmd -> $actual_path"
      return 1
    }
  done <<<"$hook_commands"
}

@test "Claude 에이전트: 에이전트-명령어 매핑 일관성 검증" {
  # Check that test-automator agent exists and test command exists
  [ -f "$AGENTS_DIR/test-automator.md" ]
  [ -f "$COMMANDS_DIR/test.md" ]

  # Check git-specialist and related commands
  if [ -f "$AGENTS_DIR/git-specialist.md" ]; then
    [ -f "$COMMANDS_DIR/create-pr.md" ] || {
      echo "git-specialist exists but create-pr command missing"
      return 1
    }
  fi
}

@test "Claude 에이전트: 설정 파일 버전 호환성 검증" {
  # Check JSON schema reference
  run jq -e '."$schema"' "$SETTINGS_FILE"
  [ "$status" -eq 0 ]

  # Verify schema URL is accessible format
  local schema_url
  schema_url=$(jq -r '."$schema"' "$SETTINGS_FILE")
  [[ $schema_url =~ ^https?:// ]] || {
    echo "Invalid schema URL format: $schema_url"
    return 1
  }
}

# Performance and Security Tests
@test "Claude 에이전트: 대용량 에이전트 파일 크기 검증" {
  for agent_file in "$AGENTS_DIR"/*.md; do
    [ -f "$agent_file" ] || continue

    local file_size
    file_size=$(wc -c <"$agent_file")

    # Check if file is reasonable size (< 1MB)
    [ "$file_size" -lt 1048576 ] || {
      echo "Agent file too large: $(basename "$agent_file") (${file_size} bytes)"
      return 1
    }
  done
}

@test "Claude 에이전트: 보안 취약점 기본 검증" {
  # Check for suspicious patterns in hook scripts
  for hook_file in "$HOOKS_DIR"/*.py; do
    [ -f "$hook_file" ] || continue

    # Check for obvious security issues
    run grep -i "eval\|exec\|subprocess\.call.*shell=True" "$hook_file"
    [ "$status" -ne 0 ] || {
      echo "Potential security issue found in: $(basename "$hook_file")"
      return 1
    }
  done

  # Check settings.json for overly permissive settings
  run jq -e '.permissions.allow | contains(["*"])' "$SETTINGS_FILE"
  [ "$status" -ne 0 ] || {
    echo "Overly permissive wildcard permission found"
    return 1
  }
}
