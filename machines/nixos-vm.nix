# NixOS VM Machine Configuration
#
# Hardware-specific settings for NixOS VM environment.
# Contains only hardware, bootloader, and system-level configurations.
# User configuration is handled in users/baleen/nixos.nix.
#
# Architecture: Mitchell-style
#   - Hardware identification: NixOS VM
#   - Platform: Linux/NixOS
#   - User configuration: users/baleen/nixos.nix
#
# Hardware Settings:
#   - Virtual hardware configuration
#   - Bootloader settings
#   - Filesystem layout (basic for CI)
#   - System user creation

{
  lib,
  pkgs,
  user,
  ...
}:

{
  # System identification
  networking.hostName = "nixos-vm";

  # System state version
  system.stateVersion = lib.mkDefault "24.05";

  # Platform detection for scripts and applications
  environment.variables = {
    PLATFORM = "linux";
    ARCHITECTURE = if pkgs.stdenv.isAarch64 then "arm64" else "x86_64";
  };

  # Boot configuration for VM
  boot = {
    loader.grub = {
      enable = true;
      devices = [ "/dev/vda" ];
      configurationLimit = 10;
    };

    # Basic kernel modules for VM
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [ "uinput" ];
  };

  # Minimal filesystem configuration for VM builds
  # Production uses disko from users/baleen/nixos.nix
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # User configuration handled in users/baleen/nixos.nix (Mitchell-style)
  # Only basic system groups defined here
  users.groups.docker = { };

  # Basic networking for VM
  networking = {
    useDHCP = false;
    interfaces."eth0".useDHCP = true;
  };

  # Hardware support for VM
  hardware = {
    graphics.enable = true;
  };

  # Enable basic system programs
  programs.zsh.enable = true;

  # System packages (hardware level only)
  environment.systemPackages = with pkgs; [
    # Basic system tools
    git
    vim
    curl
    wget
  ];
}
