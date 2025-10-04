#!/usr/bin/env bash
# Test environment setup for VSCode Remote Tunnel NixOS testing
# Provides mock NixOS environment for testing on non-NixOS systems

set -euo pipefail

# Test environment configuration
export TEST_ENV_ROOT="${TEST_ENV_ROOT:-/tmp/nixos-vscode-tunnel-test}"
export MOCK_SYSTEMCTL_PATH="${TEST_ENV_ROOT}/bin"
export MOCK_JOURNALCTL_PATH="${TEST_ENV_ROOT}/bin"
export ORIGINAL_PATH="$PATH"

# Ensure test environment exists
setup_mock_nixos_environment() {
  echo "[INFO] Setting up mock NixOS test environment"

  # Create test directory structure
  mkdir -p "${TEST_ENV_ROOT}/bin"
  mkdir -p "${TEST_ENV_ROOT}/etc/systemd/user"
  mkdir -p "${TEST_ENV_ROOT}/var/log/journal"
  mkdir -p "${TEST_ENV_ROOT}/home/user/.config/systemd/user"

  # Create mock systemctl if on non-Linux system
  if [[ "$(uname -s)" != "Linux" ]] || ! command -v systemctl >/dev/null 2>&1; then
    create_mock_systemctl
    create_mock_journalctl
    # Prepend mock binaries to PATH
    export PATH="${MOCK_SYSTEMCTL_PATH}:${PATH}"
  fi

  # Set up test service files directory
  export XDG_CONFIG_HOME="${TEST_ENV_ROOT}/home/user/.config"
  mkdir -p "${XDG_CONFIG_HOME}/systemd/user"

  echo "[INFO] Mock NixOS environment ready at ${TEST_ENV_ROOT}"
}

create_mock_systemctl() {
  local systemctl_script="${MOCK_SYSTEMCTL_PATH}/systemctl"

  cat >"${systemctl_script}" <<'EOF'
#!/usr/bin/env bash
# Mock systemctl for VSCode tunnel testing

STATE_DIR="${TEST_ENV_ROOT:-/tmp/nixos-vscode-tunnel-test}/systemd-state"
mkdir -p "${STATE_DIR}"

# Service state files
SERVICE_STATE_FILE="${STATE_DIR}/service-states"
SERVICE_ENABLED_FILE="${STATE_DIR}/service-enabled"

# Initialize state files if they don't exist
[[ -f "${SERVICE_STATE_FILE}" ]] || touch "${SERVICE_STATE_FILE}"
[[ -f "${SERVICE_ENABLED_FILE}" ]] || touch "${SERVICE_ENABLED_FILE}"

get_service_state() {
    local service="$1"
    grep "^${service}:" "${SERVICE_STATE_FILE}" 2>/dev/null | cut -d: -f2 || echo "inactive"
}

set_service_state() {
    local service="$1"
    local state="$2"
    # Remove existing entry and add new one
    grep -v "^${service}:" "${SERVICE_STATE_FILE}" > "${SERVICE_STATE_FILE}.tmp" 2>/dev/null || true
    echo "${service}:${state}" >> "${SERVICE_STATE_FILE}.tmp"
    mv "${SERVICE_STATE_FILE}.tmp" "${SERVICE_STATE_FILE}"
}

is_service_enabled() {
    local service="$1"
    grep -q "^${service}$" "${SERVICE_ENABLED_FILE}" 2>/dev/null
}

# Parse command line arguments
USER_MODE=false
if [[ "${1:-}" == "--user" ]]; then
    USER_MODE=true
    shift
fi

COMMAND="${1:-}"
SERVICE="${2:-}"

case "${COMMAND}" in
    "start")
        echo "[MOCK] Starting service: ${SERVICE}"
        set_service_state "${SERVICE}" "active"
        # Simulate service startup delay
        sleep 0.1
        ;;
    "stop")
        echo "[MOCK] Stopping service: ${SERVICE}"
        set_service_state "${SERVICE}" "inactive"
        ;;
    "restart")
        echo "[MOCK] Restarting service: ${SERVICE}"
        set_service_state "${SERVICE}" "inactive"
        sleep 0.1
        set_service_state "${SERVICE}" "active"
        ;;
    "enable")
        echo "[MOCK] Enabling service: ${SERVICE}"
        echo "${SERVICE}" >> "${SERVICE_ENABLED_FILE}"
        ;;
    "disable")
        echo "[MOCK] Disabling service: ${SERVICE}"
        grep -v "^${SERVICE}$" "${SERVICE_ENABLED_FILE}" > "${SERVICE_ENABLED_FILE}.tmp" 2>/dev/null || true
        mv "${SERVICE_ENABLED_FILE}.tmp" "${SERVICE_ENABLED_FILE}" 2>/dev/null || true
        ;;
    "is-active")
        state=$(get_service_state "${SERVICE}")
        echo "${state}"
        [[ "${state}" == "active" ]] || exit 3
        ;;
    "is-enabled")
        if is_service_enabled "${SERVICE}"; then
            echo "enabled"
            exit 0
        else
            echo "disabled"
            exit 1
        fi
        ;;
    "show")
        # Handle property queries
        if [[ "${3:-}" == "--property=UnitFileState" ]]; then
            if is_service_enabled "${SERVICE}"; then
                echo "UnitFileState=enabled"
            else
                echo "UnitFileState=disabled"
            fi
        elif [[ "${3:-}" == "--property=Restart" ]]; then
            echo "Restart=on-failure"
        elif [[ "${3:-}" == "--property=After" ]]; then
            echo "After=network-online.target"
        elif [[ "${3:-}" == "--property=Restart" && "${4:-}" == "--value" ]]; then
            echo "on-failure"
        elif [[ "${3:-}" == "--property=After" && "${4:-}" == "--value" ]]; then
            echo "network-online.target"
        fi
        ;;
    "list-unit-files")
        echo "UNIT FILE                               STATE   VENDOR PRESET"
        if is_service_enabled "vscode-tunnel"; then
            echo "vscode-tunnel.service                   enabled enabled"
        fi
        ;;
    "daemon-reload")
        echo "[MOCK] Reloading systemd daemon"
        ;;
    *)
        echo "[MOCK systemctl] Unsupported command: ${COMMAND}" >&2
        exit 1
        ;;
esac
EOF

  chmod +x "${systemctl_script}"
  echo "[INFO] Created mock systemctl at ${systemctl_script}"
}

create_mock_journalctl() {
  local journalctl_script="${MOCK_JOURNALCTL_PATH}/journalctl"

  cat >"${journalctl_script}" <<'EOF'
#!/usr/bin/env bash
# Mock journalctl for VSCode tunnel testing

LOG_DIR="${TEST_ENV_ROOT:-/tmp/nixos-vscode-tunnel-test}/logs"
mkdir -p "${LOG_DIR}"

# Parse arguments
USER_MODE=false
SERVICE=""
LINES=50
NO_PAGER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            USER_MODE=true
            shift
            ;;
        -u|--unit)
            SERVICE="$2"
            shift 2
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        --no-pager)
            NO_PAGER=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Generate mock logs for VSCode tunnel service
if [[ "${SERVICE}" == "vscode-tunnel" ]]; then
    cat << 'LOGS'
Oct 12 10:30:15 nixos systemd[1000]: Starting VSCode Remote Tunnel Service...
Oct 12 10:30:16 nixos vscode-tunnel[12345]: [INFO] VSCode CLI version 1.84.0
Oct 12 10:30:16 nixos vscode-tunnel[12345]: [INFO] Starting tunnel mode...
Oct 12 10:30:17 nixos vscode-tunnel[12345]: device_code=TEST_DEVICE_CODE
Oct 12 10:30:17 nixos vscode-tunnel[12345]: user_code=TEST_USER_CODE
Oct 12 10:30:17 nixos vscode-tunnel[12345]: Visit: https://github.com/login/device
Oct 12 10:30:18 nixos vscode-tunnel[12345]: [INFO] Waiting for authentication...
Oct 12 10:30:20 nixos vscode-tunnel[12345]: [INFO] Authentication successful
Oct 12 10:30:21 nixos vscode-tunnel[12345]: [INFO] Tunnel established successfully
Oct 12 10:30:21 nixos systemd[1000]: Started VSCode Remote Tunnel Service.
LOGS
else
    echo "-- No entries --"
fi
EOF

  chmod +x "${journalctl_script}"
  echo "[INFO] Created mock journalctl at ${journalctl_script}"
}

# Clean up test environment
cleanup_mock_nixos_environment() {
  echo "[INFO] Cleaning up mock NixOS test environment"

  # Restore original PATH
  export PATH="${ORIGINAL_PATH}"

  # Remove test directory
  [[ -d ${TEST_ENV_ROOT} ]] && rm -rf "${TEST_ENV_ROOT}"

  # Clean up any running mock processes
  pkill -f "mock.*vscode" 2>/dev/null || true
}

# Validate test environment is ready
validate_test_environment() {
  local errors=0

  echo "[INFO] Validating test environment..."

  # Check systemctl is available (real or mock)
  if ! command -v systemctl >/dev/null 2>&1; then
    echo "[ERROR] systemctl not available" >&2
    ((errors++))
  fi

  # Check journalctl is available (real or mock)
  if ! command -v journalctl >/dev/null 2>&1; then
    echo "[ERROR] journalctl not available" >&2
    ((errors++))
  fi

  # Check test directories exist
  if [[ ! -d ${TEST_ENV_ROOT} ]]; then
    echo "[ERROR] Test environment root not found: ${TEST_ENV_ROOT}" >&2
    ((errors++))
  fi

  if [[ $errors -gt 0 ]]; then
    echo "[ERROR] Test environment validation failed with ${errors} errors" >&2
    return 1
  fi

  echo "[INFO] Test environment validation passed"
  return 0
}

# Export functions for use in tests
export -f setup_mock_nixos_environment
export -f cleanup_mock_nixos_environment
export -f validate_test_environment
