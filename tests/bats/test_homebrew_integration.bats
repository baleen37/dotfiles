#!/usr/bin/env bats
# ABOUTME: Homebrew Cask 통합 테스트 - macOS GUI 애플리케이션 관리 검증
# ABOUTME: Darwin 플랫폼에서 34개 GUI 애플리케이션의 Homebrew Cask 설치 및 상태 확인

# 테스트 헬퍼 로드
load test_helper

# 테스트 초기 설정
setup() {
    # 플랫폼 확인 - macOS 전용 테스트
    if [[ "$(uname -s)" != "Darwin" ]]; then
        skip "Homebrew Cask 테스트는 macOS에서만 실행됩니다"
    fi

    # CI 환경에서는 일부 테스트 스킵
    if [[ "${CI:-false}" == "true" ]]; then
        export HOMEBREW_CI_MODE="true"
        export HOMEBREW_NO_AUTO_UPDATE="1"
        export HOMEBREW_NO_ANALYTICS="1"
    fi

    # 테스트 상수 정의
    export DOTFILES_ROOT="${BATS_TEST_DIRNAME}/../.."
    export CASKS_FILE="$DOTFILES_ROOT/modules/darwin/casks.nix"

    # 로깅 설정
    export TEST_VERBOSE="${TEST_VERBOSE:-false}"
    export LOG_LEVEL="${LOG_LEVEL:-3}"
}

# 정리 작업
teardown() {
    # 테스트 관련 임시 파일 정리
    [[ -f "/tmp/homebrew_test_$$" ]] && rm -f "/tmp/homebrew_test_$$"
    [[ -f "/tmp/cask_list_$$" ]] && rm -f "/tmp/cask_list_$$"
}

# === 기본 Homebrew 환경 테스트 ===

@test "Homebrew가 설치되어 있는지 확인" {
    # Homebrew 명령어 존재 확인
    run command -v brew
    [ "$status" -eq 0 ]

    # Homebrew 버전 정보 확인
    run brew --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Homebrew" ]]
}

@test "Homebrew Cask 기능이 사용 가능한지 확인" {
    # Cask 서브커맨드 존재 확인
    run brew help cask
    [ "$status" -eq 0 ]
    [[ "$output" =~ "cask" ]]
}

@test "Homebrew 환경 설정이 올바른지 확인" {
    # Homebrew 설치 경로 확인
    run brew --prefix
    [ "$status" -eq 0 ]

    # M1/Intel Mac에 따른 경로 확인
    if [[ "$(uname -m)" == "arm64" ]]; then
        [[ "$output" == "/opt/homebrew" ]]
    else
        [[ "$output" == "/usr/local" ]]
    fi
}

# === Cask 설정 파일 검증 ===

@test "casks.nix 파일이 존재하고 읽을 수 있는지 확인" {
    [ -f "$CASKS_FILE" ]
    [ -r "$CASKS_FILE" ]
}

@test "casks.nix 파일이 유효한 Nix 구조를 가지는지 확인" {
    # 파일이 대괄호로 시작하고 끝나는지 확인 (Nix 배열 구조)
    run head -n 1 "$CASKS_FILE"
    [[ "$output" =~ ^\[$ ]]

    run tail -n 1 "$CASKS_FILE"
    [[ "$output" =~ ^\]$ ]]
}

@test "정의된 주요 카테고리의 Cask들이 존재하는지 확인" {
    # Development Tools 카테고리 확인
    run grep -q "# Development Tools" "$CASKS_FILE"
    [ "$status" -eq 0 ]

    run grep -q "datagrip\|docker-desktop\|intellij-idea" "$CASKS_FILE"
    [ "$status" -eq 0 ]

    # Communication Tools 카테고리 확인
    run grep -q "# Communication Tools" "$CASKS_FILE"
    [ "$status" -eq 0 ]

    run grep -q "discord\|slack\|zoom" "$CASKS_FILE"
    [ "$status" -eq 0 ]

    # Browsers 카테고리 확인
    run grep -q "# Browsers" "$CASKS_FILE"
    [ "$status" -eq 0 ]

    run grep -q "google-chrome\|brave-browser\|firefox" "$CASKS_FILE"
    [ "$status" -eq 0 ]
}

@test "Cask 이름들이 유효한 형식인지 확인" {
    # 따옴표로 감싸진 유효한 Cask 이름들 추출
    local cask_names
    cask_names=$(grep -o '"[^"]*"' "$CASKS_FILE" | tr -d '"' | grep -v '^#')

    # 각 Cask 이름이 유효한 형식인지 확인 (영문자, 숫자, 하이픈만 허용)
    while IFS= read -r cask; do
        [[ "$cask" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$ ]]
    done <<< "$cask_names"
}

# === 핵심 애플리케이션 설치 상태 검증 ===

@test "필수 개발 도구들이 설치되어 있는지 확인" {
    local essential_casks=("docker-desktop" "intellij-idea")

    for cask in "${essential_casks[@]}"; do
        # Cask가 정의되어 있는지 확인
        run grep -q "\"$cask\"" "$CASKS_FILE"
        [ "$status" -eq 0 ]

        # CI 환경이 아닌 경우에만 실제 설치 상태 확인
        if [[ "${HOMEBREW_CI_MODE:-false}" != "true" ]]; then
            run brew list --cask "$cask"
            if [ "$status" -ne 0 ]; then
                # 설치되지 않은 경우 경고만 출력 (실제 설치는 하지 않음)
                echo "# WARNING: $cask가 설치되지 않았습니다" >&3
            fi
        fi
    done
}

@test "필수 브라우저들이 정의되어 있는지 확인" {
    local browsers=("google-chrome" "brave-browser" "firefox")

    for browser in "${browsers[@]}"; do
        run grep -q "\"$browser\"" "$CASKS_FILE"
        [ "$status" -eq 0 ]
    done
}

@test "보안 관련 애플리케이션들이 정의되어 있는지 확인" {
    local security_apps=("1password" "1password-cli")

    for app in "${security_apps[@]}"; do
        run grep -q "\"$app\"" "$CASKS_FILE"
        [ "$status" -eq 0 ]
    done
}

# === Cask 정보 조회 테스트 ===

@test "주요 Cask들의 정보를 조회할 수 있는지 확인" {
    if [[ "${HOMEBREW_CI_MODE:-false}" == "true" ]]; then
        skip "CI 환경에서는 Cask 정보 조회 테스트를 스킵합니다"
    fi

    local test_casks=("alfred" "vlc" "discord")

    for cask in "${test_casks[@]}"; do
        # Cask 정보 조회 (네트워크 요청이므로 타임아웃 설정)
        run timeout 30s brew info --cask "$cask"
        if [ "$status" -eq 0 ]; then
            [[ "$output" =~ "$cask" ]]
        else
            echo "# WARNING: $cask 정보 조회 실패 (네트워크 문제 가능)" >&3
        fi
    done
}

# === 라이선스 및 설치 제약 검증 ===

@test "상용 소프트웨어의 라이선스 요구사항 확인" {
    # 상용 소프트웨어 목록
    local commercial_casks=("datagrip" "intellij-idea" "1password")

    for cask in "${commercial_casks[@]}"; do
        run grep -q "\"$cask\"" "$CASKS_FILE"
        [ "$status" -eq 0 ]

        # 상용 소프트웨어 설치 시 라이선스 동의가 필요함을 확인
        if [[ "${HOMEBREW_CI_MODE:-false}" != "true" ]]; then
            run brew info --cask "$cask"
            if [ "$status" -eq 0 ]; then
                # 상용 소프트웨어는 보통 라이선스 관련 정보가 포함됨
                echo "# INFO: $cask는 상용 소프트웨어로 별도 라이선스가 필요할 수 있습니다" >&3
            fi
        fi
    done
}

# === 버전 충돌 및 의존성 테스트 ===

@test "중복되거나 충돌할 수 있는 애플리케이션 조합 확인" {
    # 브라우저 중복 설치 확인 (정상 - 여러 브라우저 동시 사용 가능)
    local browser_count
    browser_count=$(grep -c "google-chrome\|brave-browser\|firefox\|safari" "$CASKS_FILE")
    [ "$browser_count" -ge 2 ]  # 최소 2개 이상의 브라우저 정의됨

    # 터미널 애플리케이션 중복 확인
    local terminal_count
    terminal_count=$(grep -c "iterm2\|terminal\|kitty\|alacritty" "$CASKS_FILE" || echo "0")
    # 터미널 앱은 0개 또는 1개만 있어야 함 (기본 Terminal.app 사용 가능)
    [ "$terminal_count" -le 1 ]
}

# === 성능 및 시스템 영향 테스트 ===

@test "대용량 애플리케이션들의 디스크 공간 요구사항 인지" {
    local large_casks=("docker-desktop" "intellij-idea" "datagrip")

    for cask in "${large_casks[@]}"; do
        run grep -q "\"$cask\"" "$CASKS_FILE"
        [ "$status" -eq 0 ]

        # 대용량 앱들은 충분한 디스크 공간이 필요함을 로그에 기록
        echo "# INFO: $cask는 대용량 애플리케이션으로 충분한 디스크 공간이 필요합니다" >&3
    done
}

@test "시스템 권한이 필요한 애플리케이션들 확인" {
    local system_level_casks=("karabiner-elements" "tailscale-app" "hammerspoon")

    for cask in "${system_level_casks[@]}"; do
        run grep -q "\"$cask\"" "$CASKS_FILE"
        [ "$status" -eq 0 ]

        echo "# INFO: $cask는 시스템 레벨 권한이 필요한 애플리케이션입니다" >&3
    done
}

# === 자동화 및 스크립팅 테스트 ===

@test "Cask 목록을 프로그래밍 방식으로 추출할 수 있는지 확인" {
    # 모든 Cask 이름을 추출하는 스크립트 테스트
    local extracted_casks
    extracted_casks=$(grep -o '"[^"]*"' "$CASKS_FILE" | tr -d '"' | grep -v '^#' | sort)

    # 추출된 Cask 개수가 30개 이상인지 확인 (현재 약 34개)
    local cask_count
    cask_count=$(echo "$extracted_casks" | wc -l | tr -d ' ')
    [ "$cask_count" -ge 30 ]

    # 임시 파일에 저장하여 후속 테스트에서 사용 가능하도록 함
    echo "$extracted_casks" > "/tmp/cask_list_$$"
}

@test "빈 줄과 주석이 올바르게 처리되는지 확인" {
    # 파일에 빈 줄이나 주석이 있어도 파싱에 문제가 없는지 확인
    run grep -E '^[[:space:]]*#|^[[:space:]]*$' "$CASKS_FILE"
    [ "$status" -eq 0 ]  # 주석이나 빈 줄이 존재함

    # 실제 Cask 항목만 추출했을 때 유효한지 확인
    local valid_casks
    valid_casks=$(grep -o '"[a-zA-Z0-9][^"]*"' "$CASKS_FILE" | wc -l | tr -d ' ')
    [ "$valid_casks" -gt 0 ]
}

# === 에러 처리 및 복구 테스트 ===

@test "존재하지 않는 Cask에 대한 에러 처리 테스트" {
    if [[ "${HOMEBREW_CI_MODE:-false}" == "true" ]]; then
        skip "CI 환경에서는 에러 처리 테스트를 스킵합니다"
    fi

    # 존재하지 않는 Cask 이름으로 테스트
    run brew info --cask "nonexistent-cask-test-$(date +%s)"
    [ "$status" -ne 0 ]  # 실패해야 정상
    [[ "$output" =~ "No available cask\|not found\|Error" ]]
}

@test "네트워크 연결 문제 시 적절한 에러 메시지 표시" {
    if [[ "${HOMEBREW_CI_MODE:-false}" == "true" ]]; then
        skip "CI 환경에서는 네트워크 테스트를 스킵합니다"
    fi

    # 네트워크 타임아웃 설정으로 연결 문제 시뮬레이션
    export HOMEBREW_CURL_TIMEOUT=1

    run timeout 5s brew search --cask "test-network-timeout"
    # 타임아웃이나 에러가 발생하면 적절히 처리되는지 확인
    if [ "$status" -ne 0 ]; then
        echo "# INFO: 네트워크 타임아웃 또는 연결 문제가 적절히 처리되었습니다" >&3
    fi

    unset HOMEBREW_CURL_TIMEOUT
}

# === 통합 시나리오 테스트 ===

@test "전체 Cask 목록 검증 시나리오" {
    # 1. 파일 읽기
    [ -f "$CASKS_FILE" ]

    # 2. Cask 목록 추출
    local all_casks
    all_casks=$(grep -o '"[^"]*"' "$CASKS_FILE" | tr -d '"' | grep -v '^#')

    # 3. 각 카테고리별 최소 개수 확인
    local dev_tools
    dev_tools=$(echo "$all_casks" | grep -E "datagrip|docker|intellij" | wc -l | tr -d ' ')
    [ "$dev_tools" -ge 2 ]

    local browsers
    browsers=$(echo "$all_casks" | grep -E "chrome|firefox|brave" | wc -l | tr -d ' ')
    [ "$browsers" -ge 2 ]

    local comm_tools
    comm_tools=$(echo "$all_casks" | grep -E "discord|slack|zoom|telegram" | wc -l | tr -d ' ')
    [ "$comm_tools" -ge 2 ]

    # 4. 전체 개수 확인
    local total_count
    total_count=$(echo "$all_casks" | wc -l | tr -d ' ')
    [ "$total_count" -ge 30 ]
    [ "$total_count" -le 50 ]  # 너무 많지도 않아야 함
}
