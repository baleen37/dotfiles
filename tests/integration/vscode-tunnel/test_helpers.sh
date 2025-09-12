#!/usr/bin/env bash
# Test helpers for VSCode Remote Tunnel systemd service testing
# Provides common functions for NixOS systemd service testing

set -euo pipefail

# Test configuration
VSCODE_SERVICE_NAME="vscode-tunnel"
VSCODE_CLI_PATH="/tmp/vscode-cli"
VSCODE_TUNNEL_DIR="/tmp/vscode-tunnel-test"
TEST_TIMEOUT=30
GITHUB_AUTH_URL_PATTERN="https://github.com/login/device"

# Helper functions for systemd service testing
is_service_active() {
    local service_name="$1"
    systemctl --user is-active "${service_name}" >/dev/null 2>&1
}

is_service_enabled() {
    local service_name="$1"
    systemctl --user is-enabled "${service_name}" >/dev/null 2>&1
}

wait_for_service_state() {
    local service_name="$1"
    local expected_state="$2"
    local timeout="${3:-$TEST_TIMEOUT}"

    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if systemctl --user is-active "${service_name}" | grep -q "${expected_state}"; then
            return 0
        fi
        sleep 1
        ((elapsed++))
    done
    return 1
}

get_service_logs() {
    local service_name="$1"
    local lines="${2:-50}"
    journalctl --user -u "${service_name}" -n "${lines}" --no-pager
}

check_process_running() {
    local process_name="$1"
    pgrep -f "${process_name}" >/dev/null 2>&1
}

# VSCode CLI specific helpers
download_vscode_cli() {
    local cli_path="$1"
    local arch="linux-x64"
    local url="https://update.code.visualstudio.com/commit:stable/cli-alpine-${arch}/stable"

    mkdir -p "$(dirname "${cli_path}")"
    if ! curl -Ls "${url}" --output "${cli_path}"; then
        echo "Failed to download VSCode CLI" >&2
        return 1
    fi
    chmod +x "${cli_path}"
}

cleanup_vscode_cli() {
    local cli_path="$1"
    [[ -f "${cli_path}" ]] && rm -f "${cli_path}"
    [[ -d "${VSCODE_TUNNEL_DIR}" ]] && rm -rf "${VSCODE_TUNNEL_DIR}"
}

# Network and tunnel specific helpers
check_tunnel_port() {
    local port="${1:-8000}"
    netstat -tuln | grep -q ":${port}" 2>/dev/null
}

wait_for_tunnel_connection() {
    local timeout="${1:-$TEST_TIMEOUT}"
    local elapsed=0

    while [[ $elapsed -lt $timeout ]]; do
        if check_tunnel_port; then
            return 0
        fi
        sleep 1
        ((elapsed++))
    done
    return 1
}

# Authentication helpers
extract_device_code() {
    local log_output="$1"
    echo "${log_output}" | grep -o "device_code=[a-zA-Z0-9-]*" | cut -d= -f2 || true
}

extract_user_code() {
    local log_output="$1"
    echo "${log_output}" | grep -o "user_code=[A-Z0-9-]*" | cut -d= -f2 || true
}

# Test validation helpers
validate_structured_logs() {
    local service_name="$1"
    local log_output
    log_output=$(get_service_logs "${service_name}")

    # Check for structured logging with timestamp and level
    echo "${log_output}" | grep -q '\[INFO\]\|INFO:' || return 1
    echo "${log_output}" | grep -q '^\w\+\s\+\d\+\s\+\d\+:\d\+:\d\+' || return 1
}

validate_service_contract() {
    local service_name="$1"

    # Check service is user service
    systemctl --user show "${service_name}" --property=UnitFileState >/dev/null 2>&1 || return 1

    # Check service has proper restart policy
    local restart_policy
    restart_policy=$(systemctl --user show "${service_name}" --property=Restart --value)
    [[ "${restart_policy}" == "on-failure" ]] || return 1

    # Check service depends on network
    local after_units
    after_units=$(systemctl --user show "${service_name}" --property=After --value)
    echo "${after_units}" | grep -q "network" || return 1
}

# Cleanup function for tests
cleanup_test_environment() {
    # Stop service if running
    systemctl --user stop "${VSCODE_SERVICE_NAME}" 2>/dev/null || true

    # Clean up temporary files
    cleanup_vscode_cli "${VSCODE_CLI_PATH}"

    # Kill any remaining vscode processes
    pkill -f "vscode.*tunnel" 2>/dev/null || true
}

# Setup function for tests
setup_test_environment() {
    cleanup_test_environment
    mkdir -p "${VSCODE_TUNNEL_DIR}"
}
