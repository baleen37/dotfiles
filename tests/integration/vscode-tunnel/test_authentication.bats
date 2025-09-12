#!/usr/bin/env bats
# T006: GitHub OAuth flow test
# Tests GitHub authentication process for VSCode tunnel

load "test_helper_systemd.bats"

setup() {
    setup_systemd_test
    source "${BATS_TEST_DIRNAME}/test_environment_setup.sh"
    setup_mock_nixos_environment
}

teardown() {
    cleanup_systemd_test
    cleanup_mock_nixos_environment
}

@test "VSCode tunnel should initiate GitHub OAuth flow" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Service should log OAuth initiation within 30 seconds
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "device_code\|authentication.*started" 30

    # Logs should contain device code
    assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "device_code="
}

@test "VSCode tunnel should output GitHub login URL" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for authentication flow to start
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "https://github.com/login/device" 30

    # Verify GitHub device login URL is in logs
    assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "https://github.com/login/device"
}

@test "VSCode tunnel should generate user code for authentication" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for user code generation
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "user_code=" 30

    local logs
    logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 50)

    # Extract user code from logs
    local user_code
    user_code=$(echo "${logs}" | grep -o "user_code=[A-Z0-9-]*" | cut -d= -f2 || true)

    [[ -n "${user_code}" ]] || {
        echo "Expected user code in service logs" >&2
        echo "Service logs:" >&2
        echo "${logs}" >&2
        return 1
    }

    # User code should be in expected format (alphanumeric, possibly with dashes)
    [[ "${user_code}" =~ ^[A-Z0-9-]+$ ]] || {
        echo "Expected user code format [A-Z0-9-]+, got: ${user_code}" >&2
        return 1
    }
}

@test "VSCode tunnel should wait for user authentication" {
    # This test MUST FAIL until implementation is complete
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Service should indicate it's waiting for authentication
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "waiting.*authentication\|polling.*auth" 30

    assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "waiting\|polling"
}

@test "VSCode tunnel should handle authentication timeout" {
    # This test MUST FAIL until implementation is complete
    skip_if_ci "Authentication timeout test takes too long"

    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait longer than typical auth timeout (usually 15 minutes)
    # For testing, we'll wait 2 minutes and check logs indicate timeout handling
    sleep 120

    # Service should log timeout and retry behavior
    local logs
    logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 100)

    # Should see timeout or retry messages
    echo "${logs}" | grep -qE "timeout|expired|retry|restarting.*auth" || {
        echo "Expected timeout or retry handling in logs" >&2
        echo "Service logs:" >&2
        echo "${logs}" >&2
        return 1
    }
}

@test "VSCode tunnel should persist authentication token" {
    # This test MUST FAIL until implementation is complete
    local token_dir="${HOME}/.vscode-server/data/Machine"
    local token_file="${token_dir}/vscode-remote-tunnel"

    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for authentication flow (in real scenario, user would authenticate)
    # For test, we simulate successful authentication
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "authentication.*successful\|token.*saved" 60

    # Token directory should be created
    assert_directory_exists "${token_dir}"

    # Token file should exist
    assert_file_exists "${token_file}"

    # Token file should have restricted permissions (600)
    local perms
    perms=$(stat -c %a "${token_file}" 2>/dev/null || stat -f %A "${token_file}")
    [[ "${perms}" == "600" ]] || {
        echo "Expected token file permissions 600, got: ${perms}" >&2
        return 1
    }
}

@test "VSCode tunnel should reuse existing authentication token" {
    # This test MUST FAIL until implementation is complete
    local token_dir="${HOME}/.vscode-server/data/Machine"
    local token_file="${token_dir}/vscode-remote-tunnel"

    # Create mock token file
    mkdir -p "${token_dir}"
    echo '{"accessToken":"mock_token","refreshToken":"mock_refresh","expiresAt":"2024-12-31T23:59:59.000Z"}' > "${token_file}"
    chmod 600 "${token_file}"

    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Service should detect existing token and skip OAuth flow
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "token.*found\|authentication.*skipped\|reusing.*token" 15

    # Should NOT see new OAuth flow
    local logs
    logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 50)

    ! echo "${logs}" | grep -q "device_code=\|user_code=" || {
        echo "Expected to skip OAuth flow with existing token" >&2
        echo "Service logs:" >&2
        echo "${logs}" >&2
        return 1
    }
}

@test "VSCode tunnel should handle invalid authentication token" {
    # This test MUST FAIL until implementation is complete
    local token_dir="${HOME}/.vscode-server/data/Machine"
    local token_file="${token_dir}/vscode-remote-tunnel"

    # Create invalid token file
    mkdir -p "${token_dir}"
    echo '{"accessToken":"expired_token","refreshToken":"invalid","expiresAt":"2020-01-01T00:00:00.000Z"}' > "${token_file}"
    chmod 600 "${token_file}"

    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Service should detect invalid token and start new OAuth flow
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "token.*invalid\|authentication.*expired\|refreshing.*token" 30

    # Should see new OAuth flow initiated
    assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "device_code="
}

@test "VSCode tunnel should refresh expired authentication token" {
    # This test MUST FAIL until implementation is complete
    local token_dir="${HOME}/.vscode-server/data/Machine"
    local token_file="${token_dir}/vscode-remote-tunnel"

    # Create token that needs refresh
    mkdir -p "${token_dir}"
    echo '{"accessToken":"expired_token","refreshToken":"valid_refresh","expiresAt":"2020-01-01T00:00:00.000Z"}' > "${token_file}"
    chmod 600 "${token_file}"

    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Service should attempt token refresh
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "refreshing.*token\|token.*refresh" 30

    assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "refresh"
}
