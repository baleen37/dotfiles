# Shared NixOS system policy.
{ pkgs, currentSystemUser, ... }:
let
  cacheSettings = (import ../../lib/cache-config.nix) // {
    trusted-users = [
      "root"
      currentSystemUser
    ];
  };
in
{
  nix.settings = cacheSettings // {
    trusted-substituters = cacheSettings.substituters;
  };
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  # Home Manager owns completion and the prompt; NixOS owns the login shell.
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
    promptInit = "";
  };
  users.users.${currentSystemUser}.shell = pkgs.zsh;
}
