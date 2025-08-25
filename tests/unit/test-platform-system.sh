#!/usr/bin/env bash
# ABOUTME: platform-system.nix 핵심 기능 포괄적 테스트
# ABOUTME: 플랫폼 감지, 유틸리티 함수, 크로스 플랫폼 기능 검증

set -euo pipefail

# 테스트 환경 설정
TEST_DIR=$(mktemp -d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 공통 라이브러리 로드
source "$SCRIPT_DIR/../lib/common.sh"

# 테스트 결과 추적
TESTS_PASSED=0
TESTS_FAILED=0

# 테스트 헬퍼 함수
assert_test() {
    local condition="$1"
    local test_name="$2"
    local expected="${3:-}"
    local actual="${4:-}"

    if eval "$condition"; then
        log_success "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        if [[ -n "$expected" && -n "$actual" ]]; then
            log_fail "$test_name"
            log_error "  예상: $expected"
            log_error "  실제: $actual"
        else
            log_fail "$test_name"
            log_debug "  실패한 조건: $condition"
        fi
        ((TESTS_FAILED++))
        return 1
    fi
}

# platform-system.nix 평가 헬퍼 함수
eval_platform_system() {
    local system="${1:-aarch64-darwin}"
    local attribute="$2"
    nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"$system\"; }).${attribute}" 2>/dev/null | tr -d '"'
}

# 플랫폼 감지 테스트
test_platform_detection() {
    log_header "플랫폼 감지 테스트"

    # Darwin 플랫폼 감지 테스트
    local darwin_platform=$(eval_platform_system "aarch64-darwin" "platform")
    assert_test "[[ '$darwin_platform' == 'darwin' ]]" "aarch64-darwin에서 Darwin 감지" "darwin" "$darwin_platform"

    local darwin_arch=$(eval_platform_system "aarch64-darwin" "arch")
    assert_test "[[ '$darwin_arch' == 'aarch64' ]]" "aarch64-darwin에서 아키텍처 감지" "aarch64" "$darwin_arch"

    # Linux 플랫폼 감지 테스트
    local linux_platform=$(eval_platform_system "x86_64-linux" "platform")
    assert_test "[[ '$linux_platform' == 'linux' ]]" "x86_64-linux에서 Linux 감지" "linux" "$linux_platform"

    local linux_arch=$(eval_platform_system "x86_64-linux" "arch")
    assert_test "[[ '$linux_arch' == 'x86_64' ]]" "x86_64-linux에서 아키텍처 감지" "x86_64" "$linux_arch"

    # 플랫폼별 플래그 테스트
    local is_darwin=$(eval_platform_system "aarch64-darwin" "isDarwin")
    assert_test "[[ '$is_darwin' == 'true' ]]" "Darwin에서 isDarwin 플래그" "true" "$is_darwin"

    local is_linux=$(eval_platform_system "x86_64-linux" "isLinux")
    assert_test "[[ '$is_linux' == 'true' ]]" "Linux에서 isLinux 플래그" "true" "$is_linux"
}

# 유효성 검증 테스트
test_validation_functions() {
    log_header "플랫폼 유효성 검증 테스트"

    # 지원되는 시스템 확인
    local supported_systems=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; }).supportedSystems" 2>/dev/null)
    assert_test "[[ '$supported_systems' =~ 'aarch64-darwin' ]]" "지원 시스템 목록에 aarch64-darwin 포함"
    assert_test "[[ '$supported_systems' =~ 'x86_64-linux' ]]" "지원 시스템 목록에 x86_64-linux 포함"

    # 플랫폼 유효성 검증
    local darwin_valid=$(eval_platform_system "aarch64-darwin" "isValidPlatform")
    assert_test "[[ '$darwin_valid' == 'true' ]]" "Darwin 플랫폼 유효성" "true" "$darwin_valid"

    local linux_valid=$(eval_platform_system "x86_64-linux" "isValidPlatform")
    assert_test "[[ '$linux_valid' == 'true' ]]" "Linux 플랫폼 유효성" "true" "$linux_valid"
}

# 플랫폼별 설정 테스트
test_platform_configs() {
    log_header "플랫폼별 설정 테스트"

    # Darwin 설정 확인
    local darwin_pkg_mgr=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; }).currentConfig.packageManager" 2>/dev/null | tr -d '"')
    assert_test "[[ '$darwin_pkg_mgr' == 'brew' ]]" "Darwin 패키지 매니저" "brew" "$darwin_pkg_mgr"

    local darwin_homebrew=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; }).currentConfig.hasHomebrew" 2>/dev/null)
    assert_test "[[ '$darwin_homebrew' == 'true' ]]" "Darwin Homebrew 지원" "true" "$darwin_homebrew"

    # Linux 설정 확인
    local linux_pkg_mgr=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"x86_64-linux\"; }).currentConfig.packageManager" 2>/dev/null | tr -d '"')
    assert_test "[[ '$linux_pkg_mgr' == 'nix' ]]" "Linux 패키지 매니저" "nix" "$linux_pkg_mgr"

    local linux_homebrew=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"x86_64-linux\"; }).currentConfig.hasHomebrew" 2>/dev/null)
    assert_test "[[ '$linux_homebrew' == 'false' ]]" "Linux Homebrew 비지원" "false" "$linux_homebrew"
}

# 경로 유틸리티 테스트
test_path_utils() {
    log_header "경로 유틸리티 테스트"

    # Darwin 셸 경로
    local darwin_shell=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; }).utils.pathUtils.getShellPath" 2>/dev/null | tr -d '"')
    assert_test "[[ '$darwin_shell' == '/bin/zsh' ]]" "Darwin 셸 경로" "/bin/zsh" "$darwin_shell"

    # Linux 셸 경로
    local linux_shell=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"x86_64-linux\"; }).utils.pathUtils.getShellPath" 2>/dev/null | tr -d '"')
    assert_test "[[ '$linux_shell' == '/run/current-system/sw/bin/zsh' ]]" "Linux 셸 경로" "/run/current-system/sw/bin/zsh" "$linux_shell"
}

# 크로스 플랫폼 유틸리티 테스트
test_cross_platform_utils() {
    log_header "크로스 플랫폼 유틸리티 테스트"

    # 플랫폼별 값 반환 테스트
    local darwin_specific=$(nix eval --impure --expr "
        let ps = import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; };
        in ps.crossPlatform.platformSpecific { darwin = \"mac-value\"; linux = \"linux-value\"; }
    " 2>/dev/null | tr -d '"')
    assert_test "[[ '$darwin_specific' == 'mac-value' ]]" "Darwin용 플랫폼별 값" "mac-value" "$darwin_specific"

    # 플랫폼 조건부 값 테스트
    local darwin_conditional=$(nix eval --impure --expr "
        let ps = import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; };
        in ps.crossPlatform.whenPlatform \"darwin\" \"darwin-only\"
    " 2>/dev/null | tr -d '"')
    assert_test "[[ '$darwin_conditional' == 'darwin-only' ]]" "Darwin 조건부 값" "darwin-only" "$darwin_conditional"

    # 아키텍처 조건부 값 테스트
    local aarch64_conditional=$(nix eval --impure --expr "
        let ps = import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; };
        in ps.crossPlatform.whenArch \"aarch64\" \"arm-only\"
    " 2>/dev/null | tr -d '"')
    assert_test "[[ '$aarch64_conditional' == 'arm-only' ]]" "aarch64 조건부 값" "arm-only" "$aarch64_conditional"
}

# 에러 처리 테스트
test_error_handling() {
    log_header "에러 처리 테스트"

    # 지원되지 않는 시스템으로 테스트 (에러가 발생해야 함)
    if nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"unsupported-system\"; }).platform" 2>/dev/null; then
        log_fail "지원되지 않는 시스템에서 에러 발생"
        ((TESTS_FAILED++))
    else
        log_success "지원되지 않는 시스템에서 적절한 에러 발생"
        ((TESTS_PASSED++))
    fi
}

# 성능 테스트
test_performance() {
    log_header "성능 테스트"

    local start_time=$(date +%s%N)
    for i in {1..10}; do
        eval_platform_system "aarch64-darwin" "platform" >/dev/null
    done
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 )) # 밀리초 변환

    # 평가가 100ms 이하여야 함 (평균 10ms per call)
    assert_test "[[ $duration -lt 100 ]]" "10회 평가가 100ms 이내 완료" "<100ms" "${duration}ms"
}

# 정리 함수
cleanup_test_environment() {
    log_debug "테스트 환경 정리: $TEST_DIR"
    rm -rf "$TEST_DIR"
}

# 메인 테스트 실행
main() {
    log_header "Platform System 포괄적 테스트 시작"
    log_info "테스트 디렉토리: $TEST_DIR"
    log_info "프로젝트 루트: $PROJECT_ROOT"

    # 신호 핸들러 설정
    setup_signal_handlers

    # Nix 명령어 확인
    if ! command -v nix >/dev/null 2>&1; then
        log_error "nix 명령어를 찾을 수 없습니다"
        exit 1
    fi

    # 단위 테스트 실행
    test_platform_detection
    test_validation_functions
    test_platform_configs
    test_path_utils
    test_cross_platform_utils
    test_error_handling
    test_performance

    # 결과 출력
    log_separator
    log_header "테스트 결과"
    log_info "통과: $TESTS_PASSED"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "실패: $TESTS_FAILED"
        log_error "일부 테스트가 실패했습니다."
        exit 1
    else
        log_success "모든 테스트가 통과했습니다! 🎉"
        exit 0
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
