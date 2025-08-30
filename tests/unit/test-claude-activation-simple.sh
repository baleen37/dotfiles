#!/usr/bin/env bash
# ABOUTME: Claude activation 간단한 테스트 - 핵심 기능만 테스트
# ABOUTME: create_settings_copy() 함수의 기본 동작만 검증

set -euo pipefail

# 공통 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# 테스트별 커스텀 setup/teardown 함수
setup_custom() {
    log_debug "Claude activation 테스트 커스텀 setup 실행"

    # 테스트 전용 디렉토리 생성
    SOURCE_BASE="$TEST_CASE_TEMP_DIR/source"
    TARGET_BASE="$TEST_CASE_TEMP_DIR/target"
    CLAUDE_DIR="$TARGET_BASE/.claude"

    # 전역으로 내보내기
    export SOURCE_BASE TARGET_BASE CLAUDE_DIR

    mkdir -p "$SOURCE_BASE" "$CLAUDE_DIR"

    # 기본 settings.json 생성
    cat > "$SOURCE_BASE/settings.json" << 'EOF'
{
  "version": "1.0.0",
  "theme": "dark",
  "autoSave": true
}
EOF

    log_debug "Claude activation 테스트 환경 준비 완료"
}

teardown_custom() {
    log_debug "Claude activation 테스트 커스텀 teardown 실행"
    # 특별히 정리할 리소스가 있다면 여기에 추가
    # 기본 teardown_test_case에서 임시 디렉토리는 자동으로 정리됨
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

# 개별 테스트 함수들
test_basic_file_copy() {
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"
    assert_file_exists "$CLAUDE_DIR/settings.json" "파일이 복사됨"
    if [[ -L "$CLAUDE_DIR/settings.json" ]]; then
        return 1  # 심볼릭 링크이면 실패
    fi
    assert_not_empty "regular_file_test" "심볼릭 링크가 아닌 일반 파일임"
}

test_file_permissions() {
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"
    local permissions=$(stat -f "%OLp" "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -c "%a" "$CLAUDE_DIR/settings.json" 2>/dev/null)
    assert_equals "644" "$permissions" "644 권한 설정됨"
}

test_symlink_to_copy_conversion() {
    # 먼저 심볼릭 링크 생성
    ln -sf "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"
    assert_symlink "$CLAUDE_DIR/settings.json" "초기에 심볼릭 링크임"

    # 복사본으로 변환
    create_settings_copy "$SOURCE_BASE/settings.json" "$CLAUDE_DIR/settings.json"
    assert_file_exists "$CLAUDE_DIR/settings.json" "복사본으로 변환됨"

    # 심볼릭 링크가 아님을 확인
    if [[ -L "$CLAUDE_DIR/settings.json" ]]; then
        return 1  # 여전히 심볼릭 링크이면 실패
    fi
    return 0
}

# 테스트 실행
main() {
    begin_test_suite "Claude Activation 간단한 테스트"

    # 환경 검증
    validate_test_environment || {
        log_error "테스트 환경 검증 실패"
        exit 1
    }

    # 개별 테스트 실행
    run_test "기본 파일 복사" test_basic_file_copy
    run_test "파일 권한 확인" test_file_permissions
    run_test "심볼릭 링크 변환" test_symlink_to_copy_conversion

    # 테스트 결과 반환
    end_test_suite "Claude Activation 간단한 테스트"
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
