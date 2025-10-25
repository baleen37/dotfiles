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

  # Bootloader configuration for VM
  boot.loader.grub = {
    devices = [ "/dev/vda" ];
    efiSupport = false;
  };

  # Minimal filesystem configuration for VM builds
  # Production uses disko configuration from users/baleen/nixos.nix
  fileSystems."/" = {
    device = "/dev/vda";
    fsType = "ext4";
  };

  # Create user group
  users.groups.baleen = { };

  # Base user configuration (will be extended by users/baleen/nixos.nix)
  users.users.baleen = {
    isNormalUser = true;
    group = "baleen";
    extraGroups = [ "docker" ];
  };
}
