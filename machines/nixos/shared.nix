# Shared NixOS configuration for all NixOS systems (bare metal, VM, WSL)
# Common settings that apply regardless of deployment type
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Disable systemd-boot for WSL (nixos-wsl provides its own bootloader)
  boot.loader.systemd-boot.enable = lib.mkForce false;

  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  # Set your time zone
  time.timeZone = lib.mkDefault "Asia/Seoul";

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Virtualization settings
  virtualisation.docker.enable = true;

  # Select internationalisation properties
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  # Define a user account
  users.mutableUsers = true;

  # Set zsh as default shell
  programs.zsh.enable = true;

  # Manage fonts
  fonts = {
    fontDir.enable = true;

    packages = with pkgs; [
      fira-code
      cascadia-code
    ];
  };

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    cachix
    gnumake
    killall
    xclip
  ];

  # Enable the OpenSSH daemon
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Disable the firewall for development environments
  networking.firewall.enable = false;

  # System state version
  system.stateVersion = lib.mkDefault "23.11";
}
