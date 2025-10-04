#!/usr/bin/env bats
# T010: Service logging validation test
# Tests systemd service logging, structure, and observability

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

@test "VSCode tunnel service should produce structured logs" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for service to generate logs
  sleep 5

  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 50)

  [[ -n ${logs} ]] || {
    echo "Expected service to produce logs" >&2
    return 1
  }

  # Logs should have timestamps
  echo "${logs}" | grep -qE '^[A-Za-z]+ +[0-9]+ +[0-9]+:[0-9]+:[0-9]+' || {
    echo "Expected logs to have timestamps" >&2
    echo "Service logs:" >&2
    echo "${logs}" >&2
    return 1
  }
}

@test "VSCode tunnel service should use appropriate log levels" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for various log events
  sleep 10

  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 100)

  # Should contain INFO level logs
  echo "${logs}" | grep -qE '\[INFO\]|INFO:' || {
    echo "Expected INFO level logs" >&2
    echo "Service logs:" >&2
    echo "${logs}" >&2
    return 1
  }
}

@test "VSCode tunnel service should log startup events" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Check for startup log messages
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "starting\|started" 30

  assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "VSCode.*tunnel\|tunnel.*service"
}

@test "VSCode tunnel service should log version information" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Service should log VSCode CLI version
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "version" 30

  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 100)

  # Should contain version in format X.Y.Z
  echo "${logs}" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+' || {
    echo "Expected version number in logs" >&2
    echo "Service logs:" >&2
    echo "${logs}" >&2
    return 1
  }
}

@test "VSCode tunnel service should log authentication events" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for authentication flow
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "authentication\|auth" 30

  # Should log OAuth flow initiation
  assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "device_code\|user_code"

  # Should log authentication URL
  assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "github.com/login/device"
}

@test "VSCode tunnel service should log tunnel connection events" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for tunnel establishment
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established\|connection.*successful" 60

  # Should log tunnel details
  assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "tunnel.*name\|machine.*name"

  # Should log connection URL
  assert_service_logs_contain "${VSCODE_SERVICE_NAME}" "https://.*vscode-cdn\.net\|tunnel.*URL"
}

@test "VSCode tunnel service should log errors with context" {
  # This test MUST FAIL until implementation is complete
  # Simulate error condition (missing CLI binary)
  local cli_path="${HOME}/.vscode-server/cli/code"
  mkdir -p "$(dirname "${cli_path}")"

  # Create invalid CLI binary
  echo "#!/bin/bash\nexit 1" >"${cli_path}"
  chmod +x "${cli_path}"

  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Should log error with context
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "error\|failed\|ERROR" 30

  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 50)

  # Error logs should include context/details
  echo "${logs}" | grep -iE "error.*:" || echo "${logs}" | grep -iE "failed.*:" || {
    echo "Expected error logs to include context" >&2
    echo "Service logs:" >&2
    echo "${logs}" >&2
    return 1
  }
}

@test "VSCode tunnel service should not log sensitive information" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for authentication flow
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "device_code" 30

  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 100)

  # Should NOT log actual tokens or sensitive data
  ! echo "${logs}" | grep -qE "access_token|refresh_token|bearer|authorization:" || {
    echo "Service logs should not contain sensitive tokens" >&2
    echo "Service logs:" >&2
    echo "${logs}" >&2
    return 1
  }

  # Should NOT log full authentication headers
  ! echo "${logs}" | grep -qE "Authorization:|Bearer [A-Za-z0-9]+" || {
    echo "Service logs should not contain authorization headers" >&2
    return 1
  }
}

@test "VSCode tunnel service should log performance metrics" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for tunnel establishment
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 100)

  # Should log timing information
  echo "${logs}" | grep -qE "took|duration|time|ms|seconds" || {
    echo "Expected performance timing logs" >&2
    echo "Service logs:" >&2
    echo "${logs}" >&2
    return 1
  }
}

@test "VSCode tunnel service should support log rotation" {
  # This test MUST FAIL until implementation is complete
  skip_if_ci "Log rotation test requires long running service"

  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Check systemd journal configuration for the service
  local max_level_store
  max_level_store=$(systemctl --user show "${VSCODE_SERVICE_NAME}" --property=MaxLevelStore --value)

  # Should have appropriate log retention settings
  [[ -n ${max_level_store} ]] || {
    echo "Expected log retention configuration" >&2
    return 1
  }
}

@test "VSCode tunnel service logs should be searchable" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for various events
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "started" 30

  # Test log filtering by field
  local filtered_logs
  filtered_logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 10 --grep="started")

  [[ -n ${filtered_logs} ]] || {
    echo "Expected logs to be filterable/searchable" >&2
    return 1
  }
}

@test "VSCode tunnel service should log with consistent format" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Let service run for a bit to generate various logs
  sleep 10

  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 50)

  # Check for consistent log format across different messages
  local consistent_format=true
  local line_count=0

  while IFS= read -r line; do
    [[ -z $line ]] && continue
    ((line_count++))

    # Each log line should have timestamp and service identifier
    if ! echo "$line" | grep -qE '^[A-Za-z]+ +[0-9]+ +[0-9]+:[0-9]+:[0-9]+.*vscode-tunnel'; then
      consistent_format=false
      echo "Inconsistent log format in line: $line" >&2
    fi
  done <<<"$logs"

  [[ $line_count -gt 0 ]] || {
    echo "Expected service to produce log entries" >&2
    return 1
  }

  [[ $consistent_format == true ]] || {
    echo "Expected consistent log format across all entries" >&2
    return 1
  }
}

@test "VSCode tunnel service should log health check information" {
  # This test MUST FAIL until implementation is complete
  systemctl --user start "${VSCODE_SERVICE_NAME}"
  wait_for_service_active "${VSCODE_SERVICE_NAME}" 10

  # Wait for tunnel establishment
  wait_for_service_logs "${VSCODE_SERVICE_NAME}" "tunnel.*established" 60

  # Wait for health check/heartbeat logs
  sleep 30

  local logs
  logs=$(journalctl --user -u "${VSCODE_SERVICE_NAME}" --no-pager -n 100)

  # Should periodically log health status
  echo "${logs}" | grep -qE "health|heartbeat|ping|keepalive|status" || {
    echo "Expected health check information in logs" >&2
    echo "Recent service logs:" >&2
    echo "${logs}" | tail -20 >&2
    return 1
  }
}
