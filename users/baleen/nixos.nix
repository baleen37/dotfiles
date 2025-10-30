# NixOS User Configuration
#
# NixOS-specific user configurations and packages.
# This file contains Linux/NixOS-specific settings that complement
# the base home-manager configuration.
#
{
  pkgs,
  lib,
  config,
  currentSystemUser,
  ...
}:

let
  # NixOS-specific packages
  nixos-packages = with pkgs; [
    # Linux-specific development tools
    systemd
    util-linux
    file
    tree
    htop
    iotop
  ];

in
{
  # NixOS-specific user packages
  home.packages = nixos-packages;

  # NixOS-specific environment variables
  home.sessionVariables = {
    # Linux-specific environment settings
    XDG_CURRENT_DESKTOP = "none";
    XDG_SESSION_TYPE = "tty";
  };

  # NixOS-specific services (user-level)
  # Add user services that are specific to NixOS here
}
