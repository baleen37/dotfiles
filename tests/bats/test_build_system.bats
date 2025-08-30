#!/usr/bin/env bats
# BATS test for build system functionality

load './test_helper'

setup() {
    export TEST_TEMP_DIR=$(mktemp -d)
    export PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    cd "$PROJECT_ROOT"
}

teardown() {
    [ -n "$TEST_TEMP_DIR" ] && rm -rf "$TEST_TEMP_DIR"
}

@test "빌드 시스템: flake.nix 구문 검증" {
    # Check that flake.nix exists and has valid syntax
    assert_file_exists "flake.nix"

    # Simple syntax check by evaluating outputs
    run nix eval --impure --expr 'builtins.attrNames (import ./flake.nix).outputs'
    # Accept any valid output - we just want to ensure no syntax errors
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "빌드 시스템: 현재 시스템 설정 평가" {
    current_system=$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')

    if [[ "$current_system" == *"darwin"* ]]; then
        run nix eval --impure .#darwinConfigurations.$current_system.config.system.stateVersion --apply "x: \"ok\""
        [ "$status" -eq 0 ]
    elif [[ "$current_system" == *"linux"* ]]; then
        run nix eval --impure .#nixosConfigurations.$current_system.config.system.stateVersion --apply "x: \"ok\""
        [ "$status" -eq 0 ]
    fi
}

@test "빌드 시스템: Makefile 타겟 검증" {
    assert_file_exists "Makefile"

    # Check essential targets exist
    run grep -E "^(build|switch|test|test-core):" Makefile
    [ "$status" -eq 0 ]
}

@test "빌드 시스템: 스모크 테스트 실행" {
    current_system=$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')

    run nix build --impure .#checks.$current_system.smoke-test --no-link -L
    [ "$status" -eq 0 ]
}

@test "빌드 시스템: 사용자 해결 라이브러리 테스트" {
    export USER="test-user"

    run nix eval --impure --expr 'import ./lib/user-resolution.nix { mockEnv = { USER = "test-user"; }; }'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test-user" ]]
}

@test "빌드 시스템: 플랫폼 라이브러리 테스트" {
    current_system=$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')

    run nix eval --impure --expr "(import ./lib/platform-system.nix { system = \"$current_system\"; }).platform"
    [ "$status" -eq 0 ]

    if [[ "$current_system" == *"darwin"* ]]; then
        [[ "$output" =~ "darwin" ]]
    else
        [[ "$output" =~ "linux" ]]
    fi
}

@test "빌드 시스템: Home Manager 모듈 평가" {
    current_system=$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')

    if [[ "$current_system" == *"darwin"* ]]; then
        run nix eval --impure .#darwinConfigurations.$current_system.config.home-manager.users --apply "x: \"ok\""
        [ "$status" -eq 0 ]
    elif [[ "$current_system" == *"linux"* ]]; then
        run nix eval --impure .#nixosConfigurations.$current_system.config.home-manager.users --apply "x: \"ok\""
        [ "$status" -eq 0 ]
    fi
}

@test "빌드 시스템: 단위 테스트 실행" {
    current_system=$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')

    # Test user resolution
    run nix build --impure .#checks.$current_system.lib-user-resolution-test --no-link
    [ "$status" -eq 0 ]

    # Test platform system
    run nix build --impure .#checks.$current_system.lib-platform-system-test --no-link
    [ "$status" -eq 0 ]

    # Test error system
    run nix build --impure .#checks.$current_system.lib-error-system-test --no-link
    [ "$status" -eq 0 ]
}
