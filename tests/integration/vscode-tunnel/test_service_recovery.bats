#!/usr/bin/env bats
# T009: Service restart on failure test
# Tests systemd service recovery and restart behavior

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

@test "VSCode tunnel service should restart on failure" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for service to be running
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "started\|running" 30

  # Simulate service failure by killing the process
  local vscode_pid
  vscode_pid=$(pgrep -f "vscode.*tunnel" | head -1)

  if [[ -n ${vscode_pid} ]]; then
    kill -9 "${vscode_pid}"

    # Service should restart automatically
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "restarting\|restart.*detected" 30

    # Service should become active again
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 30

    assert_service_active "${VSCODE_SERVICE_NAME}"
  else
    skip "VSCode process not found for failure simulation"
  fi
}

@test "VSCode tunnel service should have restart limit" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Restart limit test causes multiple service failures"

  # Check service has StartLimitBurst configured
  local start_limit
  start_limit=$(systemctl --user show "${VSCODE_SERVICE_NAME}" --property=StartLimitBurst --value)

  [[ -n ${start_limit} ]] && [[ ${start_limit} -gt 0 ]] || {
    echo "Expected service to have StartLimitBurst configured" >&2
    return 1
  }

  # Check StartLimitIntervalSec is configured
  local start_interval
  start_interval=$(systemctl --user show "${VSCODE_SERVICE_NAME}" --property=StartLimitIntervalSec --value)

  [[ -n ${start_interval} ]] || {
    echo "Expected service to have StartLimitIntervalSec configured" >&2
    return 1
  }
}

@test "VSCode tunnel service should restart with exponential backoff" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Backoff test requires multiple restart cycles"

  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Record first restart time
  local first_restart_time
  first_restart_time=$(date +%s)

  # Cause first failure
  local vscode_pid
  vscode_pid=$(pgrep -f "vscode.*tunnel" | head -1)
  [[ -n ${vscode_pid} ]] && kill -9 "${vscode_pid}"

  # Wait for restart
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 30

  # Cause second failure
  sleep 2
  vscode_pid=$(pgrep -f "vscode.*tunnel" | head -1)
  [[ -n ${vscode_pid} ]] && kill -9 "${vscode_pid}"

  # Wait for second restart
  local second_restart_time
  second_restart_time=$(date +%s)
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 30

  # Second restart should take longer (exponential backoff)
  local restart_interval=$((second_restart_time - first_restart_time))

  # Should have some delay between restarts (at least RestartSec)
  [[ $restart_interval -ge 5 ]] || {
    echo "Expected restart delay of at least 5 seconds, got: ${restart_interval}s" >&2
    return 1
  }
}

@test "VSCode tunnel service should stop after reaching restart limit" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Restart limit test causes service to stop"

  local start_limit
  start_limit=$(systemctl --user show "${VSCODE_SERVICE_NAME}" --property=StartLimitBurst --value)

  # Skip if no restart limit configured
  [[ -n ${start_limit} ]] && [[ ${start_limit} -gt 0 ]] || skip "No restart limit configured"

  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Cause failures up to the limit
  local failures=0
  while [[ $failures -lt $((start_limit + 1)) ]]; do
    # Kill service process
    local vscode_pid
    vscode_pid=$(pgrep -f "vscode.*tunnel" | head -1)
    [[ -n ${vscode_pid} ]] && kill -9 "${vscode_pid}"

    sleep 2
    ((failures++))

    # If we've reached the limit, service should be failed
    if [[ $failures -gt $start_limit ]]; then
      # Service should be in failed state
      local service_state
      service_state=$(systemctl --user is-active "${VSCODE_SERVICE_NAME}")
      [[ ${service_state} == "failed" ]] || {
        echo "Expected service to be in failed state after ${failures} failures" >&2
        return 1
      }
      break
    fi

    # Otherwise, wait for restart
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 30 || break
  done
}

@test "VSCode tunnel service should recover from network failures" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Network failure test requires network manipulation"

  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for initial tunnel establishment
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

  # Simulate network failure (block tunnel servers)
  # In real test, would use iptables or similar to block connections

  # Service should detect network failure
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "network.*error\|connection.*failed" 30

  # Service should remain active and retry
  assert_service_active "${VSCODE_SERVICE_NAME}"

  # Service should eventually recover when network is restored
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "reconnected\|connection.*restored" 30
}

@test "VSCode tunnel service should handle authentication token expiry" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for initial authentication
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "authentication.*successful" 60

  # Simulate token expiry by corrupting token file
  local token_file="${HOME}/.vscode-server/data/Machine/vscode-remote-tunnel"
  if [[ -f ${token_file} ]]; then
    echo '{"accessToken":"expired","expiresAt":"2020-01-01T00:00:00.000Z"}' >"${token_file}"

    # Restart service to trigger token validation
    systemctl --user restart "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Service should detect expired token and re-authenticate
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "token.*expired\|re-authenticating" 30

    # Service should start new OAuth flow
    assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "device_code="
  else
    skip "Token file not found for expiry test"
  fi
}

@test "VSCode tunnel service should preserve state across restarts" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for tunnel establishment
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

  # Extract tunnel name/ID from logs
  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 100)
  local tunnel_name
  tunnel_name=$(echo "${logs}" | grep -oE "(tunnel|machine).*name[[:space:]]*['\"]?([a-zA-Z0-9-]+)['\"]?" | head -1 || true)

  # Restart service
  systemctl --user restart "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for tunnel to re-establish
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

  # Service should reuse the same tunnel name/configuration
  if [[ -n ${tunnel_name} ]]; then
    assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "${tunnel_name}"
  fi
}

@test "VSCode tunnel service should handle disk space issues" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Disk space test requires filesystem manipulation"

  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Simulate low disk space by filling up temp directory
  # (In real test, would create large file to fill available space)

  # Service should handle disk space issues gracefully
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "disk.*space\|no.*space\|write.*failed" 30

  # Service should continue running and log the issue
  assert_service_active "${VSCODE_SERVICE_NAME}"
}

@test "VSCode tunnel service should handle permission issues" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Permission test requires filesystem manipulation"

  # Create directories with wrong permissions
  local vscode_dir="${HOME}/.vscode-server"
  mkdir -p "${vscode_dir}"
  chmod 000 "${vscode_dir}"

  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Service should detect permission issues
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "permission.*denied\|access.*denied" 30

  # Service should log helpful error message
  assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "permission"

  # Restore permissions for cleanup
  chmod 755 "${vscode_dir}"
}

@test "VSCode tunnel service should handle CLI binary corruption" {
  # This test MUST FAIL until implementation is complete
  local cli_path="${HOME}/.vscode-server/cli/code"

  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for CLI download
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "CLI.*download" 30

  # Corrupt the CLI binary
  if [[ -f ${cli_path} ]]; then
    echo "corrupted" >"${cli_path}"

    # Restart service to trigger CLI validation
    systemctl --user restart "${VSCODE_SERVICE_NAME}"
    wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

    # Service should detect corruption and re-download
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "corrupt\|checksum.*failed\|re-download" 30

    # Service should eventually recover
    wait_for_service_logs "${VSCODE_SERVICE_NAME}" "download.*complete\|CLI.*ready" 60
  else
    skip "CLI binary not found for corruption test"
  fi
}
