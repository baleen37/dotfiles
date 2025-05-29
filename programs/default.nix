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
  sharedModules = [
    # local programs (local)
    ./common/hammerspoon
    ./common/homerow
    ./common/syncthing
    ./common/obsidian

    # os systems
    # (lib.mkIf isDarwin ./systems/darwin)
    # (lib.mkIf isLinux ./systems/linux)
  ];

  # homeConfigurations (linux)용 기본 stateVersion 지정
  home.stateVersion = lib.mkDefault "24.05";
}
