#!/usr/bin/env bash
# ABOUTME: Claude activation 간단한 테스트 - 핵심 기능만 테스트
# ABOUTME: create_settings_copy() 함수의 기본 동작만 검증

set -euo pipefail

# 테스트 환경 설정
TEST_DIR=$(mktemp -d)
SOURCE_BASE="$TEST_DIR/source"
TARGET_BASE="$TEST_DIR/target"
CLAUDE_DIR="$TARGET_BASE/.claude"

# 공통 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# 테스트 결과 추적
TESTS_PASSED=0
TESTS_FAILED=0

# 테스트 헬퍼 함수
run_test() {
    local test_name="$1"
    local condition="$2"

    if eval "$condition"; then
        log_success "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "$test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 테스트 환경 설정
setup_environment() {
    log_info "테스트 환경 설정..."

    mkdir -p "$SOURCE_BASE" "$CLAUDE_DIR"

    # 기본 settings.json 생성
    cat > "$SOURCE_BASE/settings.json" << 'EOF'
{
  "version": "1.0.0",
  "theme": "dark",
  "autoSave": true
}
EOF

    log_success "테스트 환경 준비 완료"
}

# claude-activation의 create_settings_copy 함수
create_settings_copy() {
    local source_file="$1"
    local target_file="$2"

    if [[ ! -f "$source_file" ]]; then
        return 0
    fi

    # 기존 파일 백업
    if [[ -f "$target_file" && ! -L "$target_file" ]]; then
        cp "$target_file" "$target_file.backup"
    fi

    # 기존 심볼릭 링크 제거
    if [[ -L "$target_file" ]]; then
        rm -f "$target_file"
    fi

    # 파일 복사 및 권한 설정
    cp "$source_file" "$target_file"
    chmod 644 "$target_file"

    # 동적 상태 병합 (jq가 있을 때만)
    if [[ -f "$target_file.backup" ]] && command -v jq >/dev/null 2>&1; then
        if jq -e '.feedbackSurveyState' "$target_file.backup" >/dev/null 2>&1; then
            local feedback_state=$(jq -c '.feedbackSurveyState' "$target_file.backup")
            jq --argjson feedback_state "$feedback_state" '.feedbackSurveyState = $feedback_state' "$target_file" > "$target_file.tmp"
            mv "$target_file.tmp" "$target_file"
        fi
        rm -f "$target_file.backup"
    fi
}

# 테스트 실행
main() {
    log_header "Claude Activation 간단한 테스트"

    setup_signal_handlers
    setup_environment

    # 테스트 1: 기본 복사
    log_info "테스트 1: 기본 파일 복사"
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"
    run_test "파일이 복사됨" "[[ -f '$CLAUDE_DIR/settings.json' ]]"
    run_test "심볼릭 링크가 아님" "[[ ! -L '$CLAUDE_DIR/settings.json' ]]"

    # 테스트 2: 권한 확인
    log_info "테스트 2: 파일 권한 확인"
    local permissions=$(stat -f "%OLp" "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -c "%a" "$CLAUDE_DIR/settings.json" 2>/dev/null)
    run_test "644 권한 설정됨" "[[ '$permissions' == '644' ]]"

    # 테스트 3: 심볼릭 링크에서 복사본으로 변환
    log_info "테스트 3: 심볼릭 링크 변환"
    rm -f "$CLAUDE_DIR/settings.json"
    ln -sf "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"
    run_test "초기에 심볼릭 링크임" "[[ -L '$CLAUDE_DIR/settings.json' ]]"

    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"
    run_test "복사본으로 변환됨" "[[ ! -L '$CLAUDE_DIR/settings.json' && -f '$CLAUDE_DIR/settings.json' ]]"

    # 결과 출력
    echo
    log_separator
    log_header "테스트 결과"
    log_info "통과: $TESTS_PASSED"
    log_info "실패: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "모든 테스트가 통과했습니다! 🎉"
        exit 0
    else
        log_error "일부 테스트가 실패했습니다."
        exit 1
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
