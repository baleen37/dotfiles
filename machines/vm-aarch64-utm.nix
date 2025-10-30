{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Use a hardcoded user for VM testing
  vmUser = "baleen";
in
{
  imports = [ ./hardware/vm-aarch64-utm.nix ];

  # VM 특정 설정
  networking.hostName = "vm-aarch64-utm";

  # Bootloader configuration for VM
  boot.loader.grub = {
    enable = true;
    devices = [ "/dev/sda" ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # User configuration
  users.users.${vmUser} = {
    isNormalUser = true;
    description = "${vmUser} user";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    group = vmUser;
    initialPassword = "temp123";
  };

  users.groups.${vmUser} = { };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Essential services
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.PermitRootLogin = "no";
  };

  # Set system state version
  system.stateVersion = "24.11";
}
