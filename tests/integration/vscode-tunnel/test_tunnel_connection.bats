#!/usr/bin/env bats
# T007: Tunnel connection test
# Tests VSCode tunnel network connection establishment

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

@test "VSCode tunnel should establish connection after authentication" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for authentication to complete and tunnel to establish
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established\|connection.*successful" 60

  assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "tunnel.*established\|connection.*successful"
}

@test "VSCode tunnel should bind to localhost interface" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for tunnel to establish
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

  # Check that VSCode process is listening on localhost
  local listening_ports
  listening_ports=$(netstat -tuln 2>/dev/null | grep "127.0.0.1:" || ss -tuln 2>/dev/null | grep "127.0.0.1:" || true)

  [[ -n ${listening_ports} ]] || {
    echo "Expected VSCode tunnel to bind to localhost interface" >&2
    echo "Listening ports:" >&2
    netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null || echo "No netstat/ss available" >&2
    return 1
  }
}

@test "VSCode tunnel should use secure connection (HTTPS)" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for tunnel establishment
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

  # Service logs should indicate secure connection
  assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "https\|SSL\|TLS\|secure"
}

@test "VSCode tunnel should generate unique tunnel name" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for tunnel establishment
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*name\|machine.*name" 60

  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 100)

  # Extract tunnel/machine name from logs
  local tunnel_name
  tunnel_name=$(echo "${logs}" | grep -oE "(tunnel|machine).*name[[:space:]]*['\"]?([a-zA-Z0-9-]+)['\"]?" | head -1 || true)

  [[ -n ${tunnel_name} ]] || {
    echo "Expected tunnel name in service logs" >&2
    echo "Service logs:" >&2
    echo "${logs}" >&2
    return 1
  }
}

@test "VSCode tunnel should handle connection failures gracefully" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Connection failure simulation requires network manipulation"

  # Start service
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Simulate network interruption by blocking VSCode tunnel servers
  # (In real test, would block *.vscode-cdn.net, *.microsoft.com, etc.)

  # Service should detect connection failure and attempt reconnection
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "connection.*failed\|reconnecting\|retry" 30

  # Service should remain active and continue retry attempts
  assert_service_active "${VSCODE_SERVICE_NAME}"
}

@test "VSCode tunnel should reconnect after network interruption" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Reconnection test requires network manipulation"

  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for initial connection
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

  # Simulate brief network interruption
  # (In real test, would temporarily block network access)

  # Service should detect disconnection and reconnect
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "reconnected\|connection.*restored" 30

  assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "reconnected\|connection.*restored"
}

@test "VSCode tunnel should expose connection URL" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for tunnel establishment
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 100)

  # Logs should contain tunnel URL
  local tunnel_url
  tunnel_url=$(echo "${logs}" | grep -oE "https://[a-zA-Z0-9.-]+\.vscode-cdn\.net[^[:space:]]*" | head -1 || true)

  [[ -n ${tunnel_url} ]] || {
    echo "Expected tunnel URL in service logs" >&2
    echo "Service logs:" >&2
    echo "${logs}" >&2
    return 1
  }

  # URL should be valid HTTPS format
  [[ ${tunnel_url} =~ ^https://.*\.vscode-cdn\.net ]] || {
    echo "Expected valid VSCode tunnel URL format, got: ${tunnel_url}" >&2
    return 1
  }
}

@test "VSCode tunnel should handle port conflicts" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Port conflict test requires local port manipulation"

  # Bind to a port that VSCode might try to use
  local test_port=8000
  nc -l "${test_port}" &
  local nc_pid=$!

  # Start service
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Service should either use different port or handle conflict gracefully
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "port.*conflict\|port.*busy\|using.*port" 30

  # Clean up
  kill "${nc_pid}" 2>/dev/null || true

  # Service should still establish tunnel successfully
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 30
}

@test "VSCode tunnel should maintain connection heartbeat" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for tunnel establishment
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

  # Wait additional time to see heartbeat/keepalive messages
  sleep 30

  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 50)

  # Should see periodic heartbeat or keepalive messages
  echo "${logs}" | grep -qE "heartbeat|keepalive|ping|health.*check" || {
    echo "Expected heartbeat/keepalive messages in service logs" >&2
    echo "Recent service logs:" >&2
    echo "${logs}" >&2
    return 1
  }
}

@test "VSCode tunnel connection should have reasonable startup time" {
  # This test MUST FAIL until implementation is complete
  local start_time
  start_time=$(date +%s)

  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for tunnel establishment
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  # Connection should establish within reasonable time (< 2 minutes)
  [[ $duration -lt 120 ]] || {
    echo "Expected tunnel connection within 120 seconds, took: ${duration}s" >&2
    return 1
  }

  log_info "Tunnel connection established in ${duration} seconds"
}
