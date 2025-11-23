{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # Common NixOS configuration for all systems

  # Enable basic system services
  services = {
    # SSH service for remote access
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = lib.mkDefault "no";
        X11Forwarding = true;
      };
      openFirewall = lib.mkDefault false;
    };
  };

  # Enable basic system packages
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    tree
  ];

  # Basic system settings
  system = {
    # Auto upgrade configuration
    autoUpgrade = {
      enable = false; # Disabled by default
    };

    # State version for NixOS
    stateVersion = "24.11";
  };

  # Set default editor to vim
  environment.variables.EDITOR = "vim";

  # Basic security settings
  security.sudo.wheelNeedsPassword = false;

  # Enable regular garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Optimise store automatically
  nix.settings.auto-optimise-store = true;
}
