# NixOS VM Machine Configuration
#
# Machine-specific settings for NixOS VM environment.
# Contains only hardware-specific settings and hostname.
# All system configuration moved to users/baleen/nixos.nix

{ lib, ... }:
{
  # System state version
  system.stateVersion = lib.mkDefault "24.05";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set hostname
  networking.hostName = "nixos-vm";

  # Boot loader for VM
  boot.loader.grub.devices = [ "/dev/vda" ];

  # Minimal filesystem configuration for VM builds
  # Production uses disko configuration from users/baleen/nixos.nix
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Create user (system-level only, Home Manager handles home config)
  users.users.baleen = {
    isNormalUser = true;
    group = "baleen";
    extraGroups = [
      "docker"
      "wheel"
    ];
  };

  users.groups.baleen = { };

  # Create user group for docker
  users.groups.docker = { };
}
