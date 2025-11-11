# machines/kakaostyle-jito.nix
{
  pkgs,
  lib,
  config,
  ...
}:

let
  # Platform detection
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;

in
{
  # Linux builder for cross-platform development (macOS only)
  # Note: Requires nix.enable = true (incompatible with Determinate Nix)
  # Will auto-activate if nix-darwin manages Nix (not using Determinate)
  nix.linux-builder = lib.mkIf (isDarwin && config.nix.enable) {
    enable = true;

    # Support both Linux architectures
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    # Concurrent build jobs
    maxJobs = 4;

    # NixOS VM configuration
    config =
      { lib, pkgs, ... }:
      {
        # Enable x86_64 emulation on ARM Macs
        boot.binfmt.emulatedSystems = lib.mkIf isAarch64 [ "x86_64-linux" ];

        # VM resources (conservative allocation for broad compatibility)
        virtualisation = {
          cores = 4;
          memorySize = lib.mkForce (1024 * 8);
          diskSize = lib.mkForce (1024 * 40);

          darwin-builder = {
            diskSize = 1024 * 40;
            memorySize = 1024 * 8;
          };
        };

        # Build optimization
        nix.settings = {
          max-jobs = 4;
          cores = 4;
        };
      };
  };

  # Minimal system-level settings
  environment.systemPackages = with pkgs; [
    home-manager
  ];

  # Enable essential programs
  programs = {
    zsh.enable = true;
  };

  # System state version
  system.stateVersion = 5;

  # Nix settings (only linux-builder config, base settings in darwin.nix)
  nix.settings = lib.mkIf (isDarwin && config.nix.enable) {
    # System features for NixOS testing (requires nix.enable = true)
    system-features = [
      "nixos-test"
      "apple-virt"
    ];
    trusted-users = [ "@admin" ];
  };
}
