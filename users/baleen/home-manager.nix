# users/baleen/home-manager.nix
#
# baleen's Home Manager configuration
# Imports shared configuration and adds baleen-specific customizations
{
  pkgs,
  lib,
  inputs,
  currentSystemUser,
  isWSL ? false,
  ...
}:

{
  # Import shared configuration
  imports = [
    ../shared/home-manager.nix
  ];

  # baleen-specific customizations can be added here
  # For now, using the same configuration as shared
}
