#!/usr/bin/env bats
# T004: Service startup contract test for VSCode Remote Tunnel
# Tests systemd service lifecycle and startup behavior

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

@test "VSCode tunnel service should be defined in systemd" {
  # This test MUST FAIL until implementation is complete
  assert_service_exists "${VSCODE_SERVICE_NAME}"
}

@test "VSCode tunnel service should be enabled by default" {
  # This test MUST FAIL until implementation is complete
  assert_service_enabled "${VSCODE_SERVICE_NAME}"
}

@test "VSCode tunnel service should start successfully" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Service startup test requires systemd"

  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  assert_service_active "${VSCODE_SERVICE_NAME}"
}

@test "VSCode tunnel service should stop successfully" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Service control test requires systemd"

  # Start service first
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Then stop it
  systemctl --user stop "${VSCODE_SERVICE_NAME}"

  # Wait for service to become inactive
  local elapsed=0
  while [[ $elapsed -lt $TEST_TIMEOUT ]]; do
    if ! systemctl --user is-active "${VSCODE_SERVICE_NAME}" >/dev/null 2>&1; then
      break
    fi
    sleep 1
    ((elapsed++))
  done

  assert_service_inactive "${VSCODE_SERVICE_NAME}"
}

@test "VSCode tunnel service should have proper restart policy" {
  # This test MUST FAIL until implementation is complete
  local restart_policy
  restart_policy=$(systemctl --user show "${VSCODE_SERVICE_NAME}" --property=Restart --value)

  [[ ${restart_policy} == "on-failure" ]] || {
    echo "Expected restart policy to be 'on-failure', got: ${restart_policy}" >&2
    return 1
  }
}

@test "VSCode tunnel service should depend on network" {
  # This test MUST FAIL until implementation is complete
  local after_units
  after_units=$(systemctl --user show "${VSCODE_SERVICE_NAME}" --property=After --value)

  echo "${after_units}" | grep -q "network" || {
    echo "Expected service to depend on network, After units: ${after_units}" >&2
    return 1
  }
}

@test "VSCode tunnel service should be a user service" {
  # This test MUST FAIL until implementation is complete
  # Verify service exists in user context, not system context
  systemctl --user list-unit-files | grep -q "${VSCODE_SERVICE_NAME}.service" || {
    echo "Service should exist in user systemd context" >&2
    return 1
  }

  # Should NOT exist in system context
  ! systemctl list-unit-files | grep -q "${VSCODE_SERVICE_NAME}.service" || {
    echo "Service should NOT exist in system systemd context" >&2
    return 1
  }
}

@test "VSCode tunnel service should have working directory configured" {
  # This test MUST FAIL until implementation is complete
  local working_dir
  working_dir=$(systemctl --user show "${VSCODE_SERVICE_NAME}" --property=WorkingDirectory --value)

  [[ -n ${working_dir} ]] || {
    echo "Expected service to have WorkingDirectory configured" >&2
    return 1
  }

  # Working directory should be user's home or a subdirectory
  [[ ${working_dir} == "/home/"* ]] || [[ ${working_dir} == '${HOME}'* ]] || {
    echo "Expected WorkingDirectory to be in user home, got: ${working_dir}" >&2
    return 1
  }
}
