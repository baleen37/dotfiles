#!/usr/bin/env bash
# ABOUTME: platform-system.nix 핵심 기능 포괄적 테스트 (리팩토링됨)
# ABOUTME: 플랫폼 감지, 유틸리티 함수, 크로스 플랫폼 기능 검증 - 새로운 테스트 프레임워크 사용

set -euo pipefail

# 테스트 환경 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 테스트 라이브러리들 로드
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/test-framework.sh"
source "$SCRIPT_DIR/../lib/mock-environment.sh"

# 테스트 초기화
TEST_SUITE_NAME="Platform System Tests"
test_framework_init

# 테스트 디렉토리 설정
TEST_DIR=$(create_test_directory "platform-system")
register_cleanup_dir "$TEST_DIR"

# platform-system.nix 평가 헬퍼 함수
eval_platform_system() {
    local system="${1:-aarch64-darwin}"
    local attribute="$2"
    nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"$system\"; }).${attribute}" 2>/dev/null | tr -d '"'
}

# 플랫폼 감지 테스트 그룹
test_platform_detection() {
    start_test_group "플랫폼 감지 테스트"

    # Darwin 플랫폼 감지 테스트
    local darwin_platform=$(eval_platform_system "aarch64-darwin" "platform")
    assert_equals "darwin" "$darwin_platform" "aarch64-darwin에서 Darwin 감지"

    local darwin_arch=$(eval_platform_system "aarch64-darwin" "arch")
    assert_equals "aarch64" "$darwin_arch" "aarch64-darwin에서 아키텍처 감지"

    # Linux 플랫폼 감지 테스트
    local linux_platform=$(eval_platform_system "x86_64-linux" "platform")
    assert_equals "linux" "$linux_platform" "x86_64-linux에서 Linux 감지"

    local linux_arch=$(eval_platform_system "x86_64-linux" "arch")
    assert_equals "x86_64" "$linux_arch" "x86_64-linux에서 아키텍처 감지"

    # 플랫폼별 플래그 테스트
    local is_darwin=$(eval_platform_system "aarch64-darwin" "isDarwin")
    assert_equals "true" "$is_darwin" "Darwin에서 isDarwin 플래그"

    local is_linux=$(eval_platform_system "x86_64-linux" "isLinux")
    assert_equals "true" "$is_linux" "Linux에서 isLinux 플래그"

    end_test_group
}

# 유효성 검증 테스트 그룹
test_validation_functions() {
    start_test_group "플랫폼 유효성 검증 테스트"

    # 지원되는 시스템 확인
    local supported_systems=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; }).supportedSystems" 2>/dev/null)
    assert_contains "$supported_systems" "aarch64-darwin" "지원 시스템 목록에 aarch64-darwin 포함"
    assert_contains "$supported_systems" "x86_64-linux" "지원 시스템 목록에 x86_64-linux 포함"

    # 플랫폼 유효성 검증
    local darwin_valid=$(eval_platform_system "aarch64-darwin" "isValidPlatform")
    assert_equals "true" "$darwin_valid" "Darwin 플랫폼 유효성"

    local linux_valid=$(eval_platform_system "x86_64-linux" "isValidPlatform")
    assert_equals "true" "$linux_valid" "Linux 플랫폼 유효성"

    end_test_group
}

# 플랫폼별 설정 테스트 그룹
test_platform_configs() {
    start_test_group "플랫폼별 설정 테스트"

    # Darwin 설정 확인
    local darwin_pkg_mgr=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; }).currentConfig.packageManager" 2>/dev/null | tr -d '"')
    assert_equals "brew" "$darwin_pkg_mgr" "Darwin 패키지 매니저"

    local darwin_homebrew=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; }).currentConfig.hasHomebrew" 2>/dev/null)
    assert_equals "true" "$darwin_homebrew" "Darwin Homebrew 지원"

    # Linux 설정 확인
    local linux_pkg_mgr=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"x86_64-linux\"; }).currentConfig.packageManager" 2>/dev/null | tr -d '"')
    assert_equals "nix" "$linux_pkg_mgr" "Linux 패키지 매니저"

    local linux_homebrew=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"x86_64-linux\"; }).currentConfig.hasHomebrew" 2>/dev/null)
    assert_equals "false" "$linux_homebrew" "Linux Homebrew 비지원"

    end_test_group
}

# 경로 유틸리티 테스트 그룹
test_path_utils() {
    start_test_group "경로 유틸리티 테스트"

    # Darwin 셸 경로
    local darwin_shell=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; }).utils.pathUtils.getShellPath" 2>/dev/null | tr -d '"')
    assert_equals "/bin/zsh" "$darwin_shell" "Darwin 셸 경로"

    # Linux 셸 경로
    local linux_shell=$(nix eval --impure --expr "(import $PROJECT_ROOT/lib/platform-system.nix { system = \"x86_64-linux\"; }).utils.pathUtils.getShellPath" 2>/dev/null | tr -d '"')
    assert_equals "/run/current-system/sw/bin/zsh" "$linux_shell" "Linux 셸 경로"

    end_test_group
}

# 크로스 플랫폼 유틸리티 테스트 그룹
test_cross_platform_utils() {
    start_test_group "크로스 플랫폼 유틸리티 테스트"

    # 플랫폼별 값 반환 테스트
    local darwin_specific=$(nix eval --impure --expr "
        let ps = import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; };
        in ps.crossPlatform.platformSpecific { darwin = \"mac-value\"; linux = \"linux-value\"; }
    " 2>/dev/null | tr -d '"')
    assert_equals "mac-value" "$darwin_specific" "Darwin용 플랫폼별 값"

    # 플랫폼 조건부 값 테스트
    local darwin_conditional=$(nix eval --impure --expr "
        let ps = import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; };
        in ps.crossPlatform.whenPlatform \"darwin\" \"darwin-only\"
    " 2>/dev/null | tr -d '"')
    assert_equals "darwin-only" "$darwin_conditional" "Darwin 조건부 값"

    # 아키텍처 조건부 값 테스트
    local aarch64_conditional=$(nix eval --impure --expr "
        let ps = import $PROJECT_ROOT/lib/platform-system.nix { system = \"aarch64-darwin\"; };
        in ps.crossPlatform.whenArch \"aarch64\" \"arm-only\"
    " 2>/dev/null | tr -d '"')
    assert_equals "arm-only" "$aarch64_conditional" "aarch64 조건부 값"

    end_test_group
}

# 에러 처리 테스트 그룹
test_error_handling() {
    start_test_group "에러 처리 테스트"

    # 지원되지 않는 시스템으로 테스트 (명령 실패가 예상됨)
    assert_command_fails "nix eval --impure --expr \"(import $PROJECT_ROOT/lib/platform-system.nix { system = \\\"unsupported-system\\\"; }).platform\" 2>/dev/null" \
        "지원되지 않는 시스템에서 적절한 에러 발생"

    end_test_group
}

# 성능 테스트 그룹
test_performance() {
    start_test_group "성능 테스트"

    # 10회 평가 성능 테스트
    measure_execution_time "
        for i in {1..10}; do
            eval_platform_system \"aarch64-darwin\" \"platform\" >/dev/null
        done
    " "10회 플랫폼 평가 성능 테스트" 100

    end_test_group
}

# 메인 테스트 실행
main() {
    log_header "Platform System 포괄적 테스트 시작 (리팩토링됨)"
    log_info "테스트 디렉토리: $TEST_DIR"
    log_info "프로젝트 루트: $PROJECT_ROOT"

    # 신호 핸들러 설정
    setup_signal_handlers

    # 필수 도구 확인
    local required_tools=("nix")
    if ! check_required_tools "${required_tools[@]}"; then
        exit 1
    fi

    # 테스트 그룹들 실행
    test_platform_detection
    test_validation_functions
    test_platform_configs
    test_path_utils
    test_cross_platform_utils
    test_error_handling
    test_performance

    # 최종 결과 출력
    if report_test_results; then
        exit 0
    else
        exit 1
    fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi