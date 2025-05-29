{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin isLinux;

in
{
  home-manager.sharedModules = [
    # local programs (local)
    ./programs/hammerspoon
    ./programs/homerow

    # os systems
    # (lib.mkIf isDarwin ./systems/darwin)
    # (lib.mkIf isLinux ./systems/linux)
  ];
}
