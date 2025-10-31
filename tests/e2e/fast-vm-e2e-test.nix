# Fast E2E test using NixOS Testing Framework
# Validates actual runtime behavior: boot + files + commands
# Target time: 2-3 minutes
{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  system ? builtins.currentSystem,
  ...
}:

let
  # Use nixosTest from pkgs (works in flake context)
  nixosTest =
    pkgs.testers.nixosTest or (import "${pkgs.path}/nixos/lib/testing-python.nix" {
      inherit system;
      inherit pkgs;
    });
in
nixosTest {
  name = "dotfiles-e2e-fast";

  nodes.machine =
    { config, pkgs, ... }:
    {
      # Import shared VM configuration
      imports = [ ../../machines/nixos/vm-shared.nix ];

      # Minimal test user
      users.users.testuser = {
        isNormalUser = true;
        password = "test";
        extraGroups = [ "wheel" ];
      };

      # Ensure home-manager is active
      home-manager.users.testuser = {
        home.stateVersion = "23.11";
      };
    };

  testScript = ''
    # Start VM and wait for boot
    machine.start()
    machine.wait_for_unit("multi-user.target")
    print("✅ VM booted successfully")

    # Validate home directory exists
    machine.succeed("test -d /home/testuser")
    print("✅ User home directory exists")

    # Check core configuration files exist
    machine.succeed("test -f /home/testuser/.gitconfig")
    print("✅ Git config present")

    machine.succeed("test -f /home/testuser/.zshrc")
    print("✅ Zsh config present")

    # Validate commands work
    machine.succeed("git --version")
    print("✅ Git command works")

    machine.succeed("zsh -c 'echo test'")
    print("✅ Zsh shell works")

    # Check system is healthy
    machine.succeed("systemctl is-system-running --wait")
    print("✅ System is healthy")
  '';
}
