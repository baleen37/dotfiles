# Fast E2E test using NixOS Testing Framework
# Validates actual runtime behavior: boot + files + commands
# Target time: 2-3 minutes
#
# This test is completely self-contained to avoid Nix store path issues
# that occur when importing vm-shared.nix with linuxPackages_latest
{
  inputs,
  pkgs ? import inputs.nixpkgs { inherit system; },
  nixpkgs ? inputs.nixpkgs,
  lib ? pkgs.lib,
  system ? builtins.currentSystem,
  nixtest ? { },
  ...
}:

let
  # Use nixosTest from pkgs (works in flake context)
  nixosTest =
    pkgs.testers.nixosTest or (import "${nixpkgs}/nixos/lib/testing-python.nix" {
      inherit system;
      inherit pkgs;
    });
in
nixosTest {
  name = "dotfiles-e2e-fast";

  nodes.machine =
    { config, pkgs, ... }:
    {
      # Minimal VM configuration - self-contained to avoid store path issues
      # DO NOT import vm-shared.nix here (causes linuxPackages_latest store path errors)

      # Use default kernel (not linuxPackages_latest) to avoid store path issues
      # boot.kernelPackages defaults to pkgs.linuxPackages

      # Basic boot configuration
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Networking
      networking.hostName = "test-vm";
      networking.useDHCP = false;
      networking.firewall.enable = false;

      # Nix configuration
      nix = {
        extraOptions = ''
          experimental-features = nix-command flakes
        '';
      };

      # System packages needed for tests
      environment.systemPackages = with pkgs; [
        git
        zsh
      ];

      # Minimal test user
      users.users.testuser = {
        isNormalUser = true;
        password = "test";
        extraGroups = [ "wheel" ];
      };

      # Don't require password for sudo
      security.sudo.wheelNeedsPassword = false;

      # State version
      system.stateVersion = "24.11";
    };

  testScript = ''
    # Start VM and wait for boot
    machine.start()
    machine.wait_for_unit("multi-user.target")
    print("✅ VM booted successfully")

    # Validate home directory exists
    machine.succeed("test -d /home/testuser")
    print("✅ User home directory exists")

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
