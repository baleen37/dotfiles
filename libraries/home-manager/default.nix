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
    ./programs/hammerspoon
    ./programs/homerow
    # 필요시 다른 모듈을 여기에 추가
  ];
}
