#!/usr/bin/env bats

# IntelliJ IDEA 시스템 통합 테스트

setup() {
    export TEST_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/intellij-plugin-health-check"
    export TEMP_DIR="${BATS_TMPDIR}/intellij-integration-test"
    mkdir -p "$TEMP_DIR"
}

teardown() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

@test "실제 시스템에서 IntelliJ IDEA 설치 경로 감지" {
    source "$TEST_SCRIPT"

    # 실제 IntelliJ IDEA가 설치되어 있는 경우에만 테스트
    if detect_intellij_paths >/dev/null 2>&1; then
        run detect_intellij_paths
        [ "$status" -eq 0 ]
        [[ "$output" == *"IntelliJ IDEA"* ]]
    else
        skip "IntelliJ IDEA가 설치되지 않음"
    fi
}

@test "실제 Homebrew 환경에서 cask 정보 확인" {
    if command -v brew >/dev/null 2>&1; then
        run brew info --cask intellij-idea
        # brew info 명령어가 성공하거나 패키지가 없을 수 있음
        [[ "$status" -eq 0 ]] || [[ "$output" == *"No available formula"* ]]
    else
        skip "Homebrew가 설치되지 않음"
    fi
}

@test "nix flake에서 intellij-health-check 패키지 빌드 가능성 확인" {
    # nix flake check를 통한 구문 검증
    cd "${BATS_TEST_DIRNAME}/../.."

    # flake.nix 파일 존재 확인
    [ -f "flake.nix" ]

    # nix flake 구문 검사 (실제 빌드하지 않고 구문만 확인)
    if command -v nix >/dev/null 2>&1; then
        run timeout 30 nix flake check --dry-run
        # 구문 오류가 없어야 함
        [[ "$status" -eq 0 ]] || [[ "$output" != *"syntax error"* ]]
    else
        skip "nix가 설치되지 않음"
    fi
}

@test "스크립트의 실제 실행 가능성 확인" {
    [ -f "$TEST_SCRIPT" ]
    [ -x "$TEST_SCRIPT" ]

    # 실제 환경에서 기본 동작 테스트 (체크 모드)
    run timeout 30 "$TEST_SCRIPT" check

    # 스크립트가 정상적으로 실행되고 종료되어야 함
    [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]

    # 오류 메시지가 심각한 것이 아닌지 확인
    [[ "$output" != *"Permission denied"* ]]
    [[ "$output" != *"command not found"* ]]
}

@test "macOS 플랫폼별 기능 확인" {
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS에서만 실행되는 테스트

        # /usr/libexec/PlistBuddy 존재 확인
        [ -x "/usr/libexec/PlistBuddy" ]

        # Applications 디렉토리 접근 가능성
        [ -d "/Applications" ]

        # Library/Application Support 디렉토리 구조
        [ -d "$HOME/Library/Application Support" ]

    else
        skip "macOS가 아닌 환경"
    fi
}

@test "플러그인 디렉토리 패턴 매칭 테스트" {
    if [[ "$(uname)" == "Darwin" ]]; then
        source "$TEST_SCRIPT"

        # 실제 JetBrains 플러그인 디렉토리가 있는지 확인
        local plugin_dirs
        readarray -t plugin_dirs < <(get_plugin_directories)

        # 플러그인 디렉토리가 올바른 패턴인지 확인
        for dir in "${plugin_dirs[@]}"; do
            [[ "$dir" == *"JetBrains"* ]]
            [[ "$dir" == *"plugins"* ]]
        done
    else
        skip "macOS가 아닌 환경"
    fi
}

@test "실제 IntelliJ IDEA 버전 정보 추출 테스트" {
    if [[ "$(uname)" == "Darwin" ]]; then
        source "$TEST_SCRIPT"

        # IntelliJ IDEA가 설치되어 있는 경우에만 테스트
        if intellij_path=$(detect_intellij_paths 2>/dev/null); then
            run get_intellij_version "$intellij_path"
            [ "$status" -eq 0 ]

            # 버전 형식이 올바른지 확인 (다양한 JetBrains 버전 형식 지원)
            [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || \
            [[ "$output" =~ ^[A-Z]+-[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || \
            [[ "$output" == "unknown" ]]
        else
            skip "IntelliJ IDEA가 설치되지 않음"
        fi
    else
        skip "macOS가 아닌 환경"
    fi
}

@test "로깅 함수들의 색상 출력 확인" {
    source "$TEST_SCRIPT"

    # 로깅 함수들이 정의되어 있는지 확인
    type log_info >/dev/null 2>&1
    type log_success >/dev/null 2>&1
    type log_warning >/dev/null 2>&1
    type log_error >/dev/null 2>&1

    # 각 로깅 함수가 정상 실행되는지 확인
    run log_info "테스트 메시지"
    [ "$status" -eq 0 ]

    run log_success "성공 메시지"
    [ "$status" -eq 0 ]

    run log_warning "경고 메시지"
    [ "$status" -eq 0 ]

    run log_error "오류 메시지"
    [ "$status" -eq 0 ]
}

@test "환경 변수 및 경로 처리 안정성" {
    source "$TEST_SCRIPT"

    # 공백이 포함된 경로 처리
    local test_path="$TEMP_DIR/Test Path With Spaces/IntelliJ IDEA.app"
    mkdir -p "$test_path/Contents"

    # 공백 경로에서도 정상 동작하는지 확인
    run get_intellij_version "$test_path"
    [ "$status" -eq 0 ]
}

@test "오류 상황에서의 graceful 처리" {
    source "$TEST_SCRIPT"

    # 존재하지 않는 경로에 대한 처리
    run get_intellij_version "/nonexistent/path"
    [ "$status" -eq 0 ]
    [[ "$output" == "unknown" ]]

    # 읽기 권한이 없는 파일에 대한 처리
    local test_file="$TEMP_DIR/no_permission.plist"
    touch "$test_file"
    chmod 000 "$test_file"

    run get_intellij_version "${test_file%/*}"
    [ "$status" -eq 0 ]

    # 권한 복구
    chmod 644 "$test_file"
}
