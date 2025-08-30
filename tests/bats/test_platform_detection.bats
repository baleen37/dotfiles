#!/usr/bin/env bats
# BATS test for platform detection and system utilities

load './test_helper'

setup() {
    export TEST_TEMP_DIR=$(mktemp -d)
    export PROJECT_ROOT="$(git rev-parse --show-toplevel)"
}

teardown() {
    [ -n "$TEST_TEMP_DIR" ] && rm -rf "$TEST_TEMP_DIR"
}

@test "플랫폼 감지: 현재 시스템 아키텍처 확인" {
    run uname -m
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^(x86_64|aarch64|arm64)$ ]]
}

@test "플랫폼 감지: 운영체제 감지" {
    run uname -s
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^(Darwin|Linux)$ ]]
}

@test "Nix 평가: 플랫폼 시스템 라이브러리 로드" {
    cd "$PROJECT_ROOT"
    run nix eval --impure --expr '(import ./lib/platform-system.nix { system = builtins.currentSystem; }).platform'
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^\"(darwin|linux)\"$ ]]
}

@test "빌드 스크립트: 플랫폼별 실행 파일 존재 확인" {
    cd "$PROJECT_ROOT"

    current_system=$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')
    expected_script="./apps/${current_system}/build-switch"

    [ -f "$expected_script" ]
    [ -x "$expected_script" ]
}

@test "환경변수: USER 설정 확인" {
    [ -n "$USER" ]
    [[ "$USER" != "root" ]] || skip "Running as root user"
}

@test "Git 저장소: 유효한 Git 저장소 확인" {
    cd "$PROJECT_ROOT"
    run git rev-parse --is-inside-work-tree
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "패키지 관리: 홈브루 설치 상태 (macOS)" {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        run command -v brew
        [ "$status" -eq 0 ]
    else
        skip "Not running on macOS"
    fi
}

@test "Nix 빌드: 기본 파생 빌드 테스트" {
    cd "$PROJECT_ROOT"
    run nix build --impure .#checks.$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"').smoke-test --no-link
    [ "$status" -eq 0 ]
}
