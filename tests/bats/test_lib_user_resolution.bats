#!/usr/bin/env bats
# BATS test for lib/user-resolution.nix functionality

load './test_helper'

setup() {
    export TEST_TEMP_DIR=$(mktemp -d)
    export PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    cd "$PROJECT_ROOT"
}

teardown() {
    [ -n "$TEST_TEMP_DIR" ] && rm -rf "$TEST_TEMP_DIR"
}

@test "사용자 해결: 기본 사용자 해결 테스트" {
    # Test basic user resolution with mock environment
    run nix eval --impure --expr 'import ./lib/user-resolution.nix { mockEnv = { USER = "test-user"; }; }'

    [ "$status" -eq 0 ]
    assert_contains "$output" "test-user"
}

@test "사용자 해결: 확장된 형식으로 해결" {
    # Test extended format resolution
    run nix eval --impure --expr '
        let result = import ./lib/user-resolution.nix {
            mockEnv = { USER = "test-user"; };
            returnFormat = "extended";
        }; in result.user'

    [ "$status" -eq 0 ]
    assert_contains "$output" "test-user"
}

@test "사용자 해결: SUDO_USER 우선순위 테스트" {
    # Test SUDO_USER takes priority over USER
    run nix eval --impure --expr 'import ./lib/user-resolution.nix {
        mockEnv = {
            USER = "root";
            SUDO_USER = "actual-user";
        };
    }'

    [ "$status" -eq 0 ]
    assert_contains "$output" "actual-user"
}

@test "사용자 해결: CI 환경 폴백 테스트" {
    # Test CI environment fallback
    run nix eval --impure --expr 'import ./lib/user-resolution.nix {
        mockEnv = {
            CI = "true";
            GITHUB_ACTOR = "ci-user";
        };
    }'

    [ "$status" -eq 0 ]
    # CI should fall back to detected user or default
    [[ "$output" =~ ^\"[a-zA-Z0-9_-]+\"$ ]]
}

@test "사용자 해결: 홈 경로 생성 테스트" {
    # Test home path generation
    run nix eval --impure --expr '
        let result = import ./lib/user-resolution.nix {
            mockEnv = { USER = "test-user"; };
            returnFormat = "extended";
        }; in result.homePath'

    [ "$status" -eq 0 ]

    if [[ "$(uname -s)" == "Darwin" ]]; then
        assert_contains "$output" "/Users/test-user"
    else
        assert_contains "$output" "/home/test-user"
    fi
}

@test "사용자 해결: 플랫폼별 홈 경로" {
    # Test platform-specific home path logic
    current_system=$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')

    run nix eval --impure --expr "
        let result = import ./lib/user-resolution.nix {
            mockEnv = { USER = \"test-user\"; };
            platform = if builtins.match \".*darwin.*\" \"$current_system\" != null then \"darwin\" else \"linux\";
            returnFormat = \"extended\";
        }; in result.homePath"

    [ "$status" -eq 0 ]

    if [[ "$current_system" == *"darwin"* ]]; then
        assert_contains "$output" "/Users/"
    else
        assert_contains "$output" "/home/"
    fi
}

@test "사용자 해결: 현재 실제 사용자 감지" {
    # Test real user detection (without mocking)
    run nix eval --impure --expr 'import ./lib/user-resolution.nix { }'

    [ "$status" -eq 0 ]
    # Should return current user
    [[ "$output" =~ ^\"[a-zA-Z0-9_-]+\"$ ]]

    # Should not be empty or null
    [[ "$output" != '""' ]]
    [[ "$output" != "null" ]]
}

@test "사용자 해결: 확장 형식 구조 검증" {
    # Test extended format structure
    run nix eval --impure --expr '
        let result = import ./lib/user-resolution.nix {
            mockEnv = { USER = "test-user"; };
            returnFormat = "extended";
        };
        in builtins.attrNames result'

    [ "$status" -eq 0 ]

    # Should contain expected attributes
    assert_contains "$output" "user"
    assert_contains "$output" "homePath"
}

@test "사용자 해결: 오류 처리 - USER 없음" {
    # Test error handling when no USER is available
    run nix eval --impure --expr 'import ./lib/user-resolution.nix { mockEnv = {}; }'

    # Should either succeed with fallback or fail gracefully
    if [ "$status" -ne 0 ]; then
        # Expected to fail - should contain error message
        assert_contains "$output" "USER"
    else
        # Succeeded with fallback - should have valid user
        [[ "$output" =~ ^\"[a-zA-Z0-9_-]+\"$ ]]
    fi
}

@test "사용자 해결: 성능 테스트" {
    # Test performance - should complete quickly
    start_timer

    run nix eval --impure --expr 'import ./lib/user-resolution.nix { mockEnv = { USER = "perf-test"; }; }'

    end_timer

    [ "$status" -eq 0 ]
    assert_contains "$output" "perf-test"

    # Performance should be reasonable (this is mainly for logging)
    log_info "User resolution completed in timer duration"
}
