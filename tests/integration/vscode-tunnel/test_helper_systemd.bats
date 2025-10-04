#!/usr/bin/env bats
# BATS helper for systemd service testing
# Load with: load "$BATS_TEST_DIRNAME/test_helper_systemd.bats"

# Import common test helpers
load "../../bats/test_helper"

# VSCode tunnel test-specific configuration
export VSCODE_SERVICE_NAME="vscode-tunnel"
export VSCODE_CLI_PATH="/tmp/vscode-cli"
export VSCODE_TUNNEL_DIR="/tmp/vscode-tunnel-test"
export TEST_TIMEOUT=30

# Systemd service assertions
assert_service_exists() {
  local service_name="$1"
  systemctl --user list-unit-files | grep -q "${service_name}.service" || {
    echo "Expected systemd service to exist: ${service_name}" >&2
    return 1
  }
}

assert_service_active() {
  local service_name="$1"
  systemctl --user is-active "${service_name}" >/dev/null 2>&1 || {
    echo "Expected service to be active: ${service_name}" >&2
    echo "Service status: $(systemctl --user is-active "${service_name}")" >&2
    return 1
  }
}

assert_service_inactive() {
  local service_name="$1"
  ! systemctl --user is-active "${service_name}" >/dev/null 2>&1 || {
    echo "Expected service to be inactive: ${service_name}" >&2
    echo "Service status: $(systemctl --user is-active "${service_name}")" >&2
    return 1
  }
}

assert_service_enabled() {
  local service_name="$1"
  systemctl --user is-enabled "${service_name}" >/dev/null 2>&1 || {
    echo "Expected service to be enabled: ${service_name}" >&2
    echo "Service enabled status: $(systemctl --user is-enabled "${service_name}")" >&2
    return 1
  }
}

assert_service_logs_contain() {
  local service_name="$1"
  local pattern="$2"
  local logs
  logs=$(journalctl --user -u "${service_name}" --no-pager -n 50)
  echo "${logs}" | grep -q "${pattern}" || {
    echo "Expected service logs to contain: ${pattern}" >&2
    echo "Service logs:" >&2
    echo "${logs}" >&2
    return 1
  }
}

assert_process_running() {
  local process_pattern="$1"
  pgrep -f "${process_pattern}" >/dev/null 2>&1 || {
    echo "Expected process to be running: ${process_pattern}" >&2
    echo "Running processes:" >&2
    pgrep -f "${process_pattern}" || echo "No matching processes found" >&2
    return 1
  }
}

assert_port_listening() {
  local port="$1"
  netstat -tuln | grep -q ":${port} " || {
    echo "Expected port to be listening: ${port}" >&2
    echo "Listening ports:" >&2
    netstat -tuln | grep LISTEN >&2
    return 1
  }
}

# Wait helpers with timeout
wait_for_service_active() {
  local service_name="$1"
  local timeout="${2:-$TEST_TIMEOUT}"
  local elapsed=0

  while [[ $elapsed -lt $timeout ]]; do
    if systemctl --user is-active "${service_name}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    ((elapsed++))
  done

  echo "Timeout waiting for service to become active: ${service_name}" >&2
  echo "Final service status: $(systemctl --user is-active "${service_name}")" >&2
  return 1
}

wait_for_service_logs() {
  local service_name="$1"
  local pattern="$2"
  local timeout="${3:-$TEST_TIMEOUT}"
  local elapsed=0

  while [[ $elapsed -lt $timeout ]]; do
    if journalctl --user -u "${service_name}" --no-pager -n 50 | grep -q "${pattern}"; then
      return 0
    fi
    sleep 1
    ((elapsed++))
  done

  echo "Timeout waiting for log pattern: ${pattern}" >&2
  echo "Service logs:" >&2
  journalctl --user -u "${service_name}" --no-pager -n 50 >&2
  return 1
}

# Setup/teardown helpers
setup_systemd_test() {
  log_info "Setting up systemd service test environment"

  # Clean up any existing test state
  cleanup_systemd_test

  # Create test directories
  mkdir -p "${VSCODE_TUNNEL_DIR}"

  # Ensure systemd user session is running
  if ! systemctl --user is-active default.target >/dev/null 2>&1; then
    skip "systemd user session not available"
  fi
}

cleanup_systemd_test() {
  log_info "Cleaning up systemd service test environment"

  # Stop and disable service if it exists
  if systemctl --user list-unit-files | grep -q "${VSCODE_SERVICE_NAME}.service"; then
    systemctl --user stop "${VSCODE_SERVICE_NAME}" 2>/dev/null || true
    systemctl --user disable "${VSCODE_SERVICE_NAME}" 2>/dev/null || true
  fi

  # Clean up test files
  [[ -f ${VSCODE_CLI_PATH} ]] && rm -f "${VSCODE_CLI_PATH}"
  [[ -d ${VSCODE_TUNNEL_DIR} ]] && rm -rf "${VSCODE_TUNNEL_DIR}"

  # Kill any remaining vscode processes
  pkill -f "vscode.*tunnel" 2>/dev/null || true

  # Reload systemd to clear any unit file changes
  systemctl --user daemon-reload 2>/dev/null || true
}

# VSCode CLI specific helpers
download_vscode_cli_for_test() {
  local cli_path="${1:-$VSCODE_CLI_PATH}"
  log_info "Downloading VSCode CLI to ${cli_path}"

  # Create a mock VSCode CLI for testing (actual download would be too slow)
  mkdir -p "$(dirname "${cli_path}")"
  cat >"${cli_path}" <<'EOF'
#!/usr/bin/env bash
# Mock VSCode CLI for testing
case "$1" in
    "tunnel")
        echo "[INFO] Starting tunnel mode..."
        echo "device_code=TEST_DEVICE_CODE"
        echo "user_code=TEST_USER_CODE"
        echo "Visit: https://github.com/login/device"
        # Keep running for tests
        sleep 3600 &
        wait
        ;;
    "--version")
        echo "1.84.0"
        ;;
    *)
        echo "Mock VSCode CLI - command not implemented: $*" >&2
        exit 1
        ;;
esac
EOF
  chmod +x "${cli_path}"
}

# NixOS integration helpers
assert_nixos_service_config() {
  local config_path="/Users/baleen/dev/dotfiles/hosts/nixos/default.nix"
  assert_file_exists "${config_path}"

  local config_content
  config_content=$(cat "${config_path}")

  # Check that VSCode tunnel service is defined
  echo "${config_content}" | grep -q "vscode-tunnel" || {
    echo "Expected NixOS config to contain VSCode tunnel service definition" >&2
    return 1
  }
}
