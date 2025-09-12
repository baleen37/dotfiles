#!/usr/bin/env bats
# T005: VSCode CLI download test
# Tests VSCode CLI binary download and installation process

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

@test "VSCode CLI download script should exist" {
    # This test MUST FAIL until implementation is complete
    local download_script="/nix/store/*/libexec/vscode-tunnel-download.sh"

    # In actual implementation, this would be installed by Nix
    # For now, check if the script would be created by the service
    [[ -f "${download_script}" ]] || {
        echo "Expected VSCode CLI download script to exist at: ${download_script}" >&2
        return 1
    }
}

@test "VSCode CLI should be downloaded to correct location" {
    # This test MUST FAIL until implementation is complete
    local cli_path="${HOME}/.vscode-server/cli/code"

    # Start the service which should trigger CLI download
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for CLI to be downloaded
    local elapsed=0
    while [[ $elapsed -lt 30 ]] && [[ ! -f "${cli_path}" ]]; do
        sleep 1
        ((elapsed++))
    done

    assert_file_exists "${cli_path}"

    # Verify CLI is executable
    [[ -x "${cli_path}" ]] || {
        echo "VSCode CLI should be executable" >&2
        return 1
    }
}

@test "VSCode CLI should have correct version" {
    # This test MUST FAIL until implementation is complete
    local cli_path="${HOME}/.vscode-server/cli/code"

    # Start service to trigger download
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for CLI download
    local elapsed=0
    while [[ $elapsed -lt 30 ]] && [[ ! -f "${cli_path}" ]]; do
        sleep 1
        ((elapsed++))
    done

    # Check version
    local version_output
    version_output=$("${cli_path}" --version 2>/dev/null)

    [[ -n "${version_output}" ]] || {
        echo "VSCode CLI should report version" >&2
        return 1
    }

    # Version should be in format like "1.84.0"
    echo "${version_output}" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+' || {
        echo "Expected version format X.Y.Z, got: ${version_output}" >&2
        return 1
    }
}

@test "VSCode CLI download should handle network failures" {
    # This test MUST FAIL until implementation is complete
    skip_if_ci "Network failure simulation requires special setup"

    # Simulate network failure by blocking the download URL
    local iptables_rule="OUTPUT -d update.code.visualstudio.com -j DROP"

    # Start service - should fail gracefully
    systemctl --user start "${VSCODE_SERVICE_NAME}"

    # Wait for service to detect failure
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "download.*failed\|network.*error\|connection.*refused" 15

    # Service should still be running and retry
    assert_service_active "${VSCODE_SERVICE_NAME}"

    # Service logs should indicate retry attempts
    assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "retry\|retrying"
}

@test "VSCode CLI download should verify checksum" {
    # This test MUST FAIL until implementation is complete
    local cli_path="${HOME}/.vscode-server/cli/code"

    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for download
    local elapsed=0
    while [[ $elapsed -lt 30 ]] && [[ ! -f "${cli_path}" ]]; do
        sleep 1
        ((elapsed++))
    done

    # Check service logs for checksum verification
    assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "checksum.*verified\|sha256.*ok"
}

@test "VSCode CLI should be updated when service restarts" {
    # This test MUST FAIL until implementation is complete
    skip_if_ci "Update test requires multiple service cycles"

    local cli_path="${HOME}/.vscode-server/cli/code"

    # Start service first time
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait for initial download
    local elapsed=0
    while [[ $elapsed -lt 30 ]] && [[ ! -f "${cli_path}" ]]; do
        sleep 1
        ((elapsed++))
    done

    local initial_mtime
    initial_mtime=$(stat -c %Y "${cli_path}" 2>/dev/null || stat -f %m "${cli_path}")

    # Restart service (should check for updates)
    systemctl --user restart "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Wait a moment for update check
    sleep 2

    # Service should log update check
    assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "checking.*update\|version.*check"
}

@test "VSCode CLI download should create necessary directories" {
    # This test MUST FAIL until implementation is complete
    local cli_dir="${HOME}/.vscode-server/cli"

    # Remove directory if it exists
    [[ -d "${cli_dir}" ]] && rm -rf "${cli_dir}"

    # Start service
    systemctl --user start "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Directory should be created
    assert_directory_exists "${cli_dir}"

    # Directory should have correct permissions (user readable/writable)
    local perms
    perms=$(stat -c %a "${cli_dir}" 2>/dev/null || stat -f %A "${cli_dir}")
    [[ "${perms}" =~ ^7[0-7][0-7]$ ]] || {
        echo "Expected directory permissions 7xx, got: ${perms}" >&2
        return 1
    }
}
