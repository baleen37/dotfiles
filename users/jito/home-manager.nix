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

  # jito-specific customizations can be added here
  # For now, using the same configuration as baleen
}
