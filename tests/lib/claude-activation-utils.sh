#!/usr/bin/env bash
# Claude Activation 공통 테스트 유틸리티
#
# 이 파일은 모든 Claude 관련 테스트에서 공통으로 사용되는 함수들을 제공합니다.
# 기존 중복된 Claude 활성화 로직을 통합하여 재사용성을 높이고 유지보수를 간소화합니다.
#
# 사용법:
#   source "${SCRIPT_DIR}/../lib/claude-activation-utils.sh"
#
# 제공 함수:
#   - setup_claude_test_environment()
#   - create_settings_copy()
#   - create_mock_dotfiles_structure()
#   - cleanup_claude_test_environment()
#   - generate_claude_activation_script()

# Claude 활성화 로직에서 추출한 settings.json 복사 함수
create_settings_copy() {
    local source_file="$1"
    local target_file="$2"
    local file_name=$(basename "$source_file")

    echo "처리 중: $file_name (복사 모드)"

    if [[ ! -f "$source_file" ]]; then
        echo "  소스 파일 없음, 건너뜀"
        return 0
    fi

    # 기존 파일 백업 (동적 상태 보존용)
    if [[ -f "$target_file" && ! -L "$target_file" ]]; then
        echo "  기존 settings.json 백업 중..."
        cp "$target_file" "$target_file.backup"
    fi

    # 기존 심볼릭 링크 제거
    if [[ -L "$target_file" ]]; then
        echo "  기존 심볼릭 링크 제거"
        rm -f "$target_file"
    fi

    # 새로운 설정을 복사
    cp "$source_file" "$target_file"
    chmod 644 "$target_file"
    echo "  파일 복사 완료: $target_file (644 권한)"

    # 백업에서 동적 상태 병합
    if [[ -f "$target_file.backup" ]]; then
        echo "  동적 상태 병합 시도 중..."

        # jq가 있으면 JSON 병합, 없으면 백업만 유지
        if command -v jq >/dev/null 2>&1; then
            # 백업에서 feedbackSurveyState 추출해서 병합
            if jq -e '.feedbackSurveyState' "$target_file.backup" >/dev/null 2>&1; then
                local feedback_state=$(jq -c '.feedbackSurveyState' "$target_file.backup")
                jq --argjson feedback_state "$feedback_state" '.feedbackSurveyState = $feedback_state' "$target_file" > "$target_file.tmp"
                mv "$target_file.tmp" "$target_file"
                echo "  ✓ feedbackSurveyState 병합 완료"
            fi
        else
            echo "  ⚠ jq 없음: 동적 상태 병합 건너뜀"
        fi

        rm -f "$target_file.backup"
    fi
}

# Claude 테스트 환경 설정 (공통)
setup_claude_test_environment() {
    local test_dir="$1"
    local source_base="$2"
    local claude_dir="$3"

    # 디렉토리 구조 생성
    mkdir -p "$source_base/commands" "$source_base/agents" "$source_base/hooks"
    mkdir -p "$claude_dir/commands" "$claude_dir/agents" "$claude_dir/hooks"

    # 테스트용 Claude 설정 파일들 생성
    cat > "$source_base/settings.json" << 'EOF'
{
  "version": "1.0.0",
  "theme": "dark",
  "autoSave": true,
  "debugMode": false
}
EOF

    cat > "$source_base/CLAUDE.md" << 'EOF'
# Test Claude Configuration
Test configuration markdown file for unit testing
EOF

    # 테스트용 명령어 파일들 생성
    mkdir -p "$source_base/commands"
    cat > "$source_base/commands/test-command.md" << 'EOF'
# Test Command
This is a test command for integration testing
EOF

    # 테스트용 에이전트 파일들 생성
    mkdir -p "$source_base/agents"
    cat > "$source_base/agents/test-agent.md" << 'EOF'
# Test Agent
This is a test agent for integration testing
EOF

    # 동적 상태가 있는 기존 settings.json (백업 테스트용)
    cat > "$test_dir/existing_settings.json" << 'EOF'
{
  "version": "0.9.0",
  "theme": "light",
  "autoSave": false,
  "debugMode": true,
  "feedbackSurveyState": {
    "lastShown": "2024-01-15",
    "dismissed": ["survey1", "survey2"],
    "completedSurveys": ["initial"],
    "userPreferences": {
      "showSurveys": true,
      "frequency": "weekly"
    }
  }
}
EOF

    # 잘못된 JSON 형식 테스트용
    cat > "$test_dir/invalid_settings.json" << 'EOF'
{
  "version": "1.0.0",
  "theme": "dark"
  // 잘못된 JSON 형식 (주석)
EOF

    echo "Claude 테스트 환경 설정 완료: $source_base"
}

# 모의 dotfiles 구조 생성 (통합 테스트용)
create_mock_dotfiles_structure() {
    local test_dir="$1"
    local dotfiles_root="$test_dir/dotfiles_mock"
    local config_dir="$dotfiles_root/modules/shared/config/claude"

    # dotfiles 모의 구조 생성
    mkdir -p "$config_dir/commands" "$config_dir/agents" "$config_dir/hooks"

    # 실제 dotfiles에서 설정 파일들 복사 (if available)
    local real_dotfiles_root
    real_dotfiles_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

    if [[ -d "$real_dotfiles_root/modules/shared/config/claude" ]]; then
        # 실제 설정 파일들을 복사
        cp -r "$real_dotfiles_root/modules/shared/config/claude"/* "$config_dir/" 2>/dev/null || {
            # 복사 실패시 기본 설정 생성
            setup_claude_test_environment "$test_dir" "$config_dir" "/dev/null"
        }
    else
        # 기본 테스트 설정 생성
        setup_claude_test_environment "$test_dir" "$config_dir" "/dev/null"
    fi

    echo "$dotfiles_root"
}

# Claude 활성화 스크립트 생성 (테스트용)
generate_claude_activation_script() {
    local source_dir="$1"
    local claude_dir="$2"
    local fallback_sources=("${@:3}")

    cat << EOF
set -euo pipefail

CLAUDE_DIR="$claude_dir"
SOURCE_DIR="$source_dir"
FALLBACK_SOURCES=($(printf '"%s" ' "${fallback_sources[@]}"))

echo "=== Claude 설정 테스트 활성화 시작 ==="
echo "Claude 디렉토리: \$CLAUDE_DIR"
echo "기본 소스 디렉토리: \$SOURCE_DIR"

# 소스 디렉토리 유효성 검사 및 fallback
ACTUAL_SOURCE_DIR=""

if [[ -d "\$SOURCE_DIR" ]]; then
  ACTUAL_SOURCE_DIR="\$SOURCE_DIR"
  echo "✓ 기본 소스 디렉토리 확인됨: \$SOURCE_DIR"
else
  echo "⚠ 기본 소스 디렉토리 없음: \$SOURCE_DIR"
  echo "Fallback 디렉토리들 확인 중..."

  for fallback_dir in "\${FALLBACK_SOURCES[@]}"; do
    echo "  시도 중: \$fallback_dir"
    if [[ -d "\$fallback_dir" ]]; then
      ACTUAL_SOURCE_DIR="\$fallback_dir"
      echo "  ✓ Fallback 소스 발견: \$fallback_dir"
      break
    fi
  done

  if [[ -z "\$ACTUAL_SOURCE_DIR" ]]; then
    echo "❌ 오류: Claude 설정 소스 디렉토리를 찾을 수 없습니다!"
    exit 1
  fi
fi

echo "사용할 소스 디렉토리: \$ACTUAL_SOURCE_DIR"

# Claude 디렉토리 생성
mkdir -p "\$CLAUDE_DIR"

# 기존 설정 파일들 정리
echo "기존 설정 파일들 정리..."
rm -f "\$CLAUDE_DIR"/*.new "\$CLAUDE_DIR"/*.update-notice "\$CLAUDE_DIR"/*.bak

# 폴더 심볼릭 링크 생성 함수
create_folder_symlink() {
  local source_folder="\$1"
  local target_folder="\$2"
  local folder_name=\$(basename "\$source_folder")

  echo "처리 중: \$folder_name/"

  if [[ ! -d "\$source_folder" ]]; then
    echo "  소스 폴더 없음, 건너뜀"
    return 0
  fi

  # 기존 폴더나 링크가 있으면 제거
  if [[ -e "\$target_folder" || -L "\$target_folder" ]]; then
    echo "  기존 \$folder_name 폴더/링크 제거"
    rm -rf "\$target_folder"
  fi

  # 폴더 심볼릭 링크 생성
  ln -sf "\$source_folder" "\$target_folder"
  echo "  폴더 심볼릭 링크 생성: \$target_folder -> \$source_folder"
}

# 개별 파일 심볼릭 링크 생성 함수
create_file_symlink() {
  local source_file="\$1"
  local target_file="\$2"
  local file_name=\$(basename "\$source_file")

  echo "처리 중: \$file_name"

  if [[ ! -f "\$source_file" ]]; then
    echo "  소스 파일 없음, 건너뜀"
    return 0
  fi

  # 기존 파일이나 링크가 있으면 제거
  if [[ -e "\$target_file" || -L "\$target_file" ]]; then
    rm -f "\$target_file"
  fi

  # 심볼릭 링크 생성
  ln -sf "\$source_file" "\$target_file"
  echo "  파일 심볼릭 링크 생성: \$target_file -> \$source_file"
}

echo ""
echo "=== Claude 설정 심볼릭 링크 생성 ==="

# 1. 폴더 단위 심볼릭 링크 생성
create_folder_symlink "\$ACTUAL_SOURCE_DIR/commands" "\$CLAUDE_DIR/commands"
create_folder_symlink "\$ACTUAL_SOURCE_DIR/agents" "\$CLAUDE_DIR/agents"
create_folder_symlink "\$ACTUAL_SOURCE_DIR/hooks" "\$CLAUDE_DIR/hooks"

# 2. 루트 레벨 설정 파일들 (.md, .json)
for source_file in "\$ACTUAL_SOURCE_DIR"/*.md "\$ACTUAL_SOURCE_DIR"/*.json; do
  if [[ -f "\$source_file" ]]; then
    file_name=\$(basename "\$source_file")
    create_file_symlink "\$source_file" "\$CLAUDE_DIR/\$file_name"
  fi
done

# 끊어진 심볼릭 링크 정리
find "\$CLAUDE_DIR" -maxdepth 1 -type l | while read -r link_file; do
  if [[ ! -e "\$link_file" ]]; then
    echo "  끊어진 링크 삭제: \$(basename "\$link_file")"
    rm -f "\$link_file"
  fi
done

echo ""
echo "✅ Claude 설정 테스트 활성화 완료!"
echo "=== Claude 설정 테스트 활성화 완료 ==="
EOF
}

# Claude 테스트 환경 정리
cleanup_claude_test_environment() {
    local test_dir="$1"

    if [[ -n "$test_dir" && -d "$test_dir" && "$test_dir" =~ /tmp/ ]]; then
        rm -rf "$test_dir"
        echo "Claude 테스트 환경 정리 완료: $test_dir"
    else
        echo "⚠️ 안전하지 않은 경로로 정리를 건너뜁니다: $test_dir"
    fi
}

# 공통 어설션 함수 (테스트에서 공통 사용)
assert_claude_test() {
    local condition="$1"
    local test_name="$2"
    local expected="${3:-}"
    local actual="${4:-}"

    # 조건부 평가 실행
    if eval "$condition"; then
        if [[ -n "${log_success:-}" ]] && declare -F log_success >/dev/null; then
            log_success "$test_name"
        else
            echo "✅ $test_name"
        fi
        return 0
    else
        if [[ -n "${log_fail:-}" ]] && declare -F log_fail >/dev/null; then
            log_fail "$test_name"
            if [[ -n "$expected" && -n "$actual" ]]; then
                log_error "  예상: $expected"
                log_error "  실제: $actual"
            fi
        else
            echo "❌ $test_name"
            if [[ -n "$expected" && -n "$actual" ]]; then
                echo "  예상: $expected"
                echo "  실제: $actual"
            fi
        fi
        return 1
    fi
}

# 공통 Claude 설정 검증 함수
verify_claude_activation() {
    local claude_dir="$1"
    local test_name_prefix="${2:-Claude 활성화}"

    # 기본 디렉토리 구조 확인
    assert_claude_test "[[ -d '$claude_dir' ]]" "$test_name_prefix: Claude 디렉토리 존재"
    assert_claude_test "[[ -d '$claude_dir/commands' || -L '$claude_dir/commands' ]]" "$test_name_prefix: commands 폴더/링크 존재"
    assert_claude_test "[[ -d '$claude_dir/agents' || -L '$claude_dir/agents' ]]" "$test_name_prefix: agents 폴더/링크 존재"

    # 설정 파일 확인
    if [[ -f "$claude_dir/settings.json" || -L "$claude_dir/settings.json" ]]; then
        assert_claude_test "[[ -f '$claude_dir/settings.json' || -L '$claude_dir/settings.json' ]]" "$test_name_prefix: settings.json 존재"
    fi

    if [[ -f "$claude_dir/CLAUDE.md" || -L "$claude_dir/CLAUDE.md" ]]; then
        assert_claude_test "[[ -f '$claude_dir/CLAUDE.md' || -L '$claude_dir/CLAUDE.md' ]]" "$test_name_prefix: CLAUDE.md 존재"
    fi
}

# 스크립트가 source될 때 메시지 출력
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Claude 활성화 공통 유틸리티 로드됨: $(basename "${BASH_SOURCE[0]}")"
fi
