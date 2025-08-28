#!/usr/bin/env bash
# ABOUTME: platform-system.nix 핵심 기능 테스트 - 새로운 테스트 코어 사용 예제
# ABOUTME: 기존 테스트를 새로운 통합 프레임워크로 마이그레이션한 예제

set -euo pipefail

# 새로운 테스트 코어 로드 (단일 진입점)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test-core.sh"

# 테스트 스위트 초기화
test_suite_init "Platform System Tests (New Framework)"

# 표준 테스트 환경 설정
setup_standard_test_environment "platform-system-new"

# platform-system.nix 평가 헬퍼 함수 (기존과 동일)
eval_platform_system() {
    local system="${1:-aarch64-darwin}"
    local attribute="$2"
    nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"$system\"; }).${attribute}" 2>/dev/null | tr -d '"'
}

# === 테스트 케이스들 ===

test_platform_detection() {
    start_test_group "플랫폼 감지 테스트"

    # Darwin 플랫폼 감지 테스트 (새로운 assert 함수 사용)
    local darwin_platform=$(eval_platform_system "aarch64-darwin" "platform")
    assert_equals "darwin" "$darwin_platform" "aarch64-darwin에서 Darwin 감지"

    local darwin_arch=$(eval_platform_system "aarch64-darwin" "arch")
    assert_equals "aarch64" "$darwin_arch" "aarch64-darwin에서 아키텍처 감지"

    # Linux 플랫폼 감지 테스트
    local linux_platform=$(eval_platform_system "x86_64-linux" "platform")
    assert_equals "linux" "$linux_platform" "x86_64-linux에서 Linux 감지"

    local linux_arch=$(eval_platform_system "x86_64-linux" "arch")
    assert_equals "x86_64" "$linux_arch" "x86_64-linux에서 아키텍처 감지"

    end_test_group
}

test_platform_utilities() {
    start_test_group "플랫폼 유틸리티 함수 테스트"

    # isDarwin 함수 테스트
    local is_darwin=$(eval_platform_system "aarch64-darwin" "isDarwin")
    assert_equals "true" "$is_darwin" "Darwin에서 isDarwin = true"

    local is_not_darwin=$(eval_platform_system "x86_64-linux" "isDarwin")
    assert_equals "false" "$is_not_darwin" "Linux에서 isDarwin = false"

    # isLinux 함수 테스트
    local is_linux=$(eval_platform_system "x86_64-linux" "isLinux")
    assert_equals "true" "$is_linux" "Linux에서 isLinux = true"

    local is_not_linux=$(eval_platform_system "aarch64-darwin" "isLinux")
    assert_equals "false" "$is_not_linux" "Darwin에서 isLinux = false"

    end_test_group
}

test_system_strings() {
    start_test_group "시스템 문자열 생성 테스트"

    # 시스템 문자열 매칭 테스트 (정규표현식 사용)
    local darwin_system=$(eval_platform_system "aarch64-darwin" "system")
    assert_matches_pattern "$darwin_system" "^aarch64-darwin$" "Darwin 시스템 문자열 형식"

    local linux_system=$(eval_platform_system "x86_64-linux" "system")
    assert_matches_pattern "$linux_system" "^x86_64-linux$" "Linux 시스템 문자열 형식"

    end_test_group
}

test_nix_file_evaluation() {
    start_test_group "Nix 파일 평가 테스트"

    # 새로운 assert_nix_file_eval 함수 사용
    assert_nix_file_eval "$PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; }" "platform" "darwin" "Nix 파일 직접 평가"

    end_test_group
}

# === 플랫폼별 조건부 테스트 ===

test_platform_specific_features() {
    start_test_group "플랫폼별 특화 기능 테스트"

    # Darwin 전용 테스트
    darwin_only_test test_darwin_specific

    # Linux 전용 테스트
    linux_only_test test_linux_specific

    end_test_group
}

test_darwin_specific() {
    log_info "Darwin 전용 기능 테스트 실행"
    # Darwin에서만 실행되는 테스트
    local darwin_specific=$(eval_platform_system "$(uname -m)-darwin" "isDarwin")
    assert_equals "true" "$darwin_specific" "현재 Darwin 시스템에서 isDarwin 확인"
}

test_linux_specific() {
    log_info "Linux 전용 기능 테스트 실행"
    # Linux에서만 실행되는 테스트
    local linux_specific=$(eval_platform_system "$(uname -m)-linux" "isLinux")
    assert_equals "true" "$linux_specific" "현재 Linux 시스템에서 isLinux 확인"
}

# === 성능 테스트 ===

test_performance() {
    start_test_group "성능 테스트"

    # Nix 평가 성능 측정 (500ms 이하)
    performance_test_platform_eval() {
        eval_platform_system "aarch64-darwin" "platform" >/dev/null
    }
    performance_test "performance_test_platform_eval" 500 "플랫폼 감지 성능"

    end_test_group
}

# === 테스트 실행 ===

# 모든 테스트 실행
test_platform_detection
test_platform_utilities
test_system_strings
test_nix_file_evaluation
test_platform_specific_features
test_performance

# 테스트 스위트 완료
test_suite_finish
