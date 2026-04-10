# End-to-End Test Template
#
# This is a template for writing E2E tests.
# Copy this file to tests/e2e/<feature>-test.nix and modify.
#
# E2E tests should:
# - Test complete system scenarios in a VM
# - Have long execution time (5-15 minutes)
# - Validate real-world workflows
# - Only be run manually or in CI (excluded from auto-discovery)
#
# Quick Start:
# 1. Copy this file: cp tests/e2e/test-template.nix tests/e2e/my-scenario-test.nix
# 2. Edit the test configuration below
# 3. Run: nix build '.#checks.x86_64-linux.e2e-my-scenario' --impure
#
# NOTE: E2E tests are NOT auto-discovered. They must be run manually
# or explicitly included in CI workflows.

{
  pkgs ? import <nixpkgs> { },
  nixpkgs ? <nixpkgs>,
  lib ? pkgs.lib,
  system ? builtins.currentSystem,
  self ? null,
  inputs ? { },
}:

let
  e2eHelpers = import ./helpers.nix {
    inherit pkgs lib;
    platformSystem = { isDarwin = false; isLinux = true; };
  };
  nixosTest = e2eHelpers.mkNixosTest { inherit nixpkgs system; };

in
nixosTest {
  # Test name
  name = "my-e2e-test";

  # Define the VM node(s) using factory
  nodes.machine = e2eHelpers.mkBaseNode {
    hostname = "test-machine";
    # Add test-specific configuration:
    # extraConfig = {
    #   services.my-service.enable = true;
    # };
  };

  # Test script - Python-based test logic
  testScript = ''
    start_all()

    # Wait for system to be ready
    machine.wait_for_unit("multi-user.target")

    print("🚀 Starting E2E Test: my-e2e-test")

    # ===== BASIC SYSTEM TESTS =====

    # Verify basic tools are available
    machine.succeed("which git")
    machine.succeed("which vim")
    machine.succeed("which curl")

    # Verify user exists
    machine.succeed("id -u testuser")

    # ===== USER SCENARIO TESTS =====

    # Test user can perform actions
    machine.succeed("su - testuser -c 'git --version'")
    machine.succeed("su - testuser -c 'vim --version'")

    # Test user home directory
    machine.succeed("su - testuser -c 'test -d /home/testuser'")

    print("✅ All E2E tests passed!")
  '';
}
