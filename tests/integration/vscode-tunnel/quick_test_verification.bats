#!/usr/bin/env bats
# Quick verification that tests fail without implementation

@test "VSCode tunnel service should exist (expects to FAIL)" {
  # This test MUST FAIL - service not implemented yet
  systemctl --user list-unit-files | grep -q "vscode-tunnel.service" || {
    echo "Expected failure: VSCode tunnel service not implemented yet"
    return 1
  }
}
