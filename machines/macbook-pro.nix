# machines/macbook-pro.nix
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

  # Chip generation detection (M1/M2 vs M3+)
  # Set MAC_CHIP_GEN=m3 for M3+ optimizations
  chipGenEnv = builtins.getEnv "MAC_CHIP_GEN";
  isM3Plus = chipGenEnv == "m3" || chipGenEnv == "m4";

  # Resource allocation based on chip generation
  builderConfig = {
    cores = if isM3Plus then 8 else 4;
    memory = if isM3Plus then (1024 * 20) else (1024 * 8);
    disk = if isM3Plus then (1024 * 80) else (1024 * 40);
    maxJobs = if isM3Plus then 8 else 4;
  };

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
    maxJobs = builderConfig.maxJobs;

    # NixOS VM configuration
    config =
      { lib, pkgs, ... }:
      {
        # Enable x86_64 emulation on ARM Macs
        boot.binfmt.emulatedSystems = lib.mkIf isAarch64 [ "x86_64-linux" ];

        # VM resources (hardware-aware)
        virtualisation = {
          cores = builderConfig.cores;
          memorySize = lib.mkForce builderConfig.memory;
          diskSize = lib.mkForce builderConfig.disk;

          darwin-builder = {
            diskSize = builderConfig.disk;
            memorySize = builderConfig.memory;
          };
        };

        # Build optimization
        nix.settings = {
          max-jobs = builderConfig.maxJobs;
          cores = builderConfig.cores;
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
