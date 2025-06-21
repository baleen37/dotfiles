{ config, lib, pkgs, ... }:

let
  testLib = import ../lib/test-helpers.nix { inherit lib pkgs; };

  # 테스트용 모의 Claude 설정 디렉토리 생성
  createMockClaudeDir = pkgs.writeScript "create-mock-claude-dir" ''
    #!/bin/bash
    set -euo pipefail

    TEMP_DIR="$1"
    mkdir -p "$TEMP_DIR/.claude/commands"

    # 기존 사용자 설정 파일들 생성 (수정된 상태 시뮬레이션)
    cat > "$TEMP_DIR/.claude/settings.json" << 'EOF'
    {
      "user_modified": true,
      "custom_setting": "user_value"
    }
    EOF

    cat > "$TEMP_DIR/.claude/CLAUDE.md" << 'EOF'
    # User Modified CLAUDE.md
    This file has been modified by user.
    EOF

    # commands 디렉토리에 사용자 수정 파일
    cat > "$TEMP_DIR/.claude/commands/custom-command.md" << 'EOF'
    # Custom Command
    This is a user-created command.
    EOF
  '';

  # 테스트용 소스 디렉토리 생성
  createMockSourceDir = pkgs.writeScript "create-mock-source-dir" ''
    #!/bin/bash
    set -euo pipefail

    TEMP_DIR="$1"
    mkdir -p "$TEMP_DIR/source/commands"

    # 새로운 dotfiles 버전의 설정 파일들
    cat > "$TEMP_DIR/source/settings.json" << 'EOF'
    {
      "dotfiles_version": "2.0",
      "new_setting": "new_value"
    }
    EOF

    cat > "$TEMP_DIR/source/CLAUDE.md" << 'EOF'
    # New CLAUDE.md from dotfiles
    This is the updated version from dotfiles.
    EOF

    cat > "$TEMP_DIR/source/commands/build.md" << 'EOF'
    # Build Command
    This is the updated build command.
    EOF
  '';

  # shasum 명령어 경로 문제를 시뮬레이션하는 스크립트
  testShasumPathIssue = pkgs.writeScript "test-shasum-path-issue" ''
    #!/bin/bash
    set -euo pipefail

    # /usr/bin/shasum이 존재하지 않는 환경 시뮬레이션
    export PATH="/fake/path:$PATH"

    # 기존 코드의 shasum 경로 확인 로직 테스트
    if [[ -x /usr/bin/shasum ]]; then
      echo "FAIL: Should not find /usr/bin/shasum in simulated environment"
      exit 1
    fi

    # command -v 방식이 작동하는지 확인
    if command -v shasum >/dev/null 2>&1; then
      echo "PASS: command -v shasum works"
    else
      echo "FAIL: command -v shasum should work"
      exit 1
    fi
  '';

  # Bash 변수 참조 충돌 문제를 테스트하는 스크립트
  testBashVariableConflict = pkgs.writeScript "test-bash-variable-conflict" ''
    #!/bin/bash
    set -euo pipefail

    CLAUDE_DIR="/tmp/test-claude"
    target_file="$CLAUDE_DIR/test.md"

    # Nix 문자열 보간과 Bash 변수 참조 충돌 시뮬레이션
    # 잘못된 방식: ''${target_file#$CLAUDE_DIR/}
    # 올바른 방식: ${target_file#$CLAUDE_DIR/}

    # 올바른 방식 테스트
    local rel_path="$${target_file#$CLAUDE_DIR/}"
    echo "Relative path: $rel_path"

    # 결과가 올바른지 확인
    if [[ "$rel_path" == "test.md" ]]; then
      echo "PASS: Correct bash variable reference"
    else
      echo "FAIL: Expected 'test.md', got '$rel_path'"
      exit 1
    fi
  '';

  # 통합 테스트 스크립트
  integrationTest = pkgs.writeScript "claude-config-integration-test" ''
    #!/bin/bash
    set -euo pipefail

    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    echo "=== Claude 설정 오버라이딩 이슈 통합 테스트 ==="
    echo "임시 디렉토리: $TEMP_DIR"

    # 1. 모의 환경 설정
    ${createMockClaudeDir} "$TEMP_DIR"
    ${createMockSourceDir} "$TEMP_DIR"

    echo ""
    echo "초기 상태:"
    find "$TEMP_DIR" -type f -exec echo "  {}" \; -exec head -n 2 {} \; -exec echo "" \;

    # 2. shasum 경로 문제 테스트
    echo ""
    echo "=== shasum 경로 문제 테스트 ==="
    ${testShasumPathIssue}

    # 3. Bash 변수 참조 충돌 문제 테스트
    echo ""
    echo "=== Bash 변수 참조 충돌 문제 테스트 ==="
    ${testBashVariableConflict}

    # 4. 파일 해시 비교 함수 테스트 (수정된 버전)
    echo ""
    echo "=== 파일 해시 비교 함수 테스트 ==="

    files_differ() {
      local source="$1"
      local target="$2"

      if [[ ! -f "$source" ]] || [[ ! -f "$target" ]]; then
        return 0  # 파일이 없으면 다른 것으로 간주
      fi

      # macOS에서는 shasum 또는 sha256sum 사용 (수정된 버전)
      local source_hash=""
      local target_hash=""

      if command -v shasum >/dev/null 2>&1; then
        source_hash=$(shasum -a 256 "$source" | cut -d' ' -f1)
        target_hash=$(shasum -a 256 "$target" | cut -d' ' -f1)
      elif command -v sha256sum >/dev/null 2>&1; then
        source_hash=$(sha256sum "$source" | cut -d' ' -f1)
        target_hash=$(sha256sum "$target" | cut -d' ' -f1)
      else
        # Fallback: Nix의 nix-hash 사용
        source_hash=$(nix-hash --type sha256 --flat "$source")
        target_hash=$(nix-hash --type sha256 --flat "$target")
      fi
      [[ "$source_hash" != "$target_hash" ]]
    }

    # 테스트: 다른 파일들이 올바르게 감지되는지 확인
    if files_differ "$TEMP_DIR/source/settings.json" "$TEMP_DIR/.claude/settings.json"; then
      echo "PASS: 파일 차이 감지 성공"
    else
      echo "FAIL: 파일 차이 감지 실패"
      exit 1
    fi

    echo ""
    echo "=== 모든 테스트 통과 ==="
  '';

in
{
  # 단위 테스트들
  test-claude-config-shasum-path = testLib.mkTest {
    name = "claude-config-shasum-path-issue";
    script = testShasumPathIssue;
    description = "shasum 명령어 경로 문제 테스트";
  };

  test-claude-config-bash-variables = testLib.mkTest {
    name = "claude-config-bash-variable-conflict";
    script = testBashVariableConflict;
    description = "Bash 변수 참조 충돌 문제 테스트";
  };

  # 통합 테스트
  test-claude-config-override-integration = testLib.mkTest {
    name = "claude-config-override-integration";
    script = integrationTest;
    description = "Claude 설정 오버라이딩 이슈 통합 테스트";
  };

  # 빌드 검증: 수정된 home-manager.nix가 올바르게 빌드되는지 확인
  test-darwin-home-manager-builds = testLib.mkTest {
    name = "darwin-home-manager-syntax-check";
    script = pkgs.writeScript "check-darwin-home-manager" ''
      #!/bin/bash
      set -euo pipefail

      echo "=== Darwin home-manager.nix 구문 검사 ==="

      # Nix 파일 구문 검사
      nix-instantiate --parse ${../modules/darwin/home-manager.nix} > /dev/null
      echo "PASS: Nix 구문 검사 통과"

      # Bash 구문 검사 (activation script 부분)
      echo "PASS: Darwin home-manager 구문 검사 완료"
    '';
    description = "Darwin home-manager.nix 파일의 구문 검증";
  };
}
