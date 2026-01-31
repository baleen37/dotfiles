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
  # Import nixosTest - works in both flake and non-flake contexts
  nixosTest =
    pkgs.testers.nixosTest or (import "${nixpkgs}/nixos/lib/testing-python.nix" {
      inherit system;
      inherit pkgs;
    });

in
nixosTest {
  # Test name
  name = "my-e2e-test";

  # Define the VM node(s)
  nodes.machine =
    { config, pkgs, ... }:
    {
      # Basic NixOS configuration
      system.stateVersion = "24.11";

      # Networking
      networking.hostName = "test-machine";
      networking.useDHCP = false;
      networking.firewall.enable = false;

      # VM resources
      virtualisation.cores = 2;
      virtualisation.memorySize = 2048;
      virtualisation.diskSize = 4096;

      # Nix configuration
      nix = {
        extraOptions = ''
          experimental-features = nix-command flakes
          accept-flake-config = true
        '';
        settings = {
          substituters = [ "https://cache.nixos.org/" ];
          trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
        };
      };

      # User setup
      users.users.testuser = {
        isNormalUser = true;
        password = "test";
        extraGroups = [ "wheel" ];
        shell = pkgs.bash;
      };

      # System packages
      environment.systemPackages = with pkgs; [
        git
        vim
        curl
        jq
      ];

      # Enable sudo without password for testing
      security.sudo.wheelNeedsPassword = false;

      # ===== CUSTOM CONFIGURATION =====
      # Add your test-specific configuration here

      # Example: Enable a service
      # services.my-service.enable = true;

      # Example: Install test packages
      # environment.systemPackages = with pkgs; [
      #   my-package
      # ];
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

    # ===== CONFIGURATION TESTS =====

    # Test that configuration was applied
    # Example: Check if a service is running
    # machine.succeed("systemctl is-active my-service")

    # Example: Check if a file exists
    # machine.succeed("test -f /etc/my-config.conf")

    # Example: Check configuration content
    # machine.succeed("grep 'expected-value' /etc/my-config.conf")

    # ===== USER SCENARIO TESTS =====

    # Test user can perform actions
    machine.succeed("su - testuser -c 'git --version'")
    machine.succeed("su - testuser -c 'vim --version'")

    # Test user home directory
    machine.succeed("su - testuser -c 'test -d /home/testuser'")

    # ===== INTEGRATION TESTS =====

    # Test workflows that span multiple components
    # Example: Clone a repo and check out a file
    # machine.succeed("su - testuser -c 'cd /tmp && git clone https://github.com/example/repo'")
    # machine.succeed("su - testuser -c 'test -f /tmp/repo/README.md'")

    # ===== PLATFORM-SPECIFIC TESTS =====

    # Add platform-specific tests as needed
    # Example: Test Darwin-specific features
    # if subprocess.call(["uname", "-s"]) == "Darwin":
    #     machine.succeed("brew --version")

    print("✅ All E2E tests passed!")
  '';
}
