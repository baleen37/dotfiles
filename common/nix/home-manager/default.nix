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
  home-manager.sharedModules =
    (lib.optionals isDarwin [
      ./programs/hammerspoon
      # macOS 전용 모듈은 여기에 추가
    ]) ++ [
      ./programs/homerow
      # 공통 모듈은 여기에 추가
    ];
}
