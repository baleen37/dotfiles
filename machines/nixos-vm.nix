# NixOS VM Machine Configuration
#
# Machine-specific settings for NixOS VM environment.
# Contains only hardware-specific settings and hostname.
# All system configuration moved to users/baleen/nixos.nix

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set hostname
  networking.hostName = "nixos-vm";

  # Minimal filesystem configuration for VM builds
  # Production uses disko configuration from users/baleen/nixos.nix
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Add user to docker group if docker is enabled
  users.users.baleen.extraGroups = [ "docker" ];
}