#!/usr/bin/env bats
# Implementation verification test

load "../../bats/test_helper"

@test "NixOS config contains VSCode tunnel service definition" {
    local config_file="/Users/baleen/dev/dotfiles/hosts/nixos/default.nix"
    assert_file_exists "${config_file}"

    local config_content
    config_content=$(cat "${config_file}")

    # Check for systemd service definition
    assert_contains "${config_content}" "systemd.user.services.vscode-tunnel"
    assert_contains "${config_content}" "VSCode Remote Tunnel Service"

    # Check for service configuration elements
    assert_contains "${config_content}" "ExecStartPre"
    assert_contains "${config_content}" "ExecStart"
    assert_contains "${config_content}" "network-online.target"
    assert_contains "${config_content}" "Restart = \"on-failure\""
}

@test "NixOS config contains code command wrapper" {
    local config_file="/Users/baleen/dev/dotfiles/hosts/nixos/default.nix"
    local config_content
    config_content=$(cat "${config_file}")

    # Check for code command definition
    assert_contains "${config_content}" "writeShellScriptBin \"code\""
    assert_contains "${config_content}" "VSCode Remote Tunnel client command"
    assert_contains "${config_content}" "\$HOME/.vscode-server/cli/code"
}

@test "VSCode tunnel service has proper security settings" {
    local config_file="/Users/baleen/dev/dotfiles/hosts/nixos/default.nix"
    local config_content
    config_content=$(cat "${config_file}")

    # Check security configurations
    assert_contains "${config_content}" "NoNewPrivileges = true"
    assert_contains "${config_content}" "PrivateTmp = true"
    assert_contains "${config_content}" "ProtectSystem = \"strict\""
}

@test "VSCode tunnel service has proper restart policy" {
    local config_file="/Users/baleen/dev/dotfiles/hosts/nixos/default.nix"
    local config_content
    config_content=$(cat "${config_file}")

    # Check restart configuration
    assert_contains "${config_content}" "Restart = \"on-failure\""
    assert_contains "${config_content}" "RestartSec = \"5\""
    assert_contains "${config_content}" "StartLimitBurst = 3"
    assert_contains "${config_content}" "StartLimitIntervalSec = 300"
}

@test "VSCode tunnel CLI download script has error handling" {
    local config_file="/Users/baleen/dev/dotfiles/hosts/nixos/default.nix"
    local config_content
    config_content=$(cat "${config_file}")

    # Check download script error handling
    assert_contains "${config_content}" "set -euo pipefail"
    assert_contains "${config_content}" "for attempt in {1..3}"
    assert_contains "${config_content}" "curl -fsSL"
    assert_contains "${config_content}" "chmod +x"

    # Check CLI verification
    assert_contains "${config_content}" "--version"
    assert_contains "${config_content}" "rm -f \"\$CLI_PATH\""
}
