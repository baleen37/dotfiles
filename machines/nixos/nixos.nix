# General NixOS configuration for x86_64 systems
# Works on bare metal, VMs, and WSL
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    ./shared.nix
    # Note: For WSL, nixos-wsl module is added in flake.nix
    # For bare metal/VM, ensure hardware-configuration.nix exists
  ];

  # Override hostname
  networking.hostName = "nixos";

  # Allow unfree packages for development tools
  nixpkgs.config.allowUnfree = true;
}
