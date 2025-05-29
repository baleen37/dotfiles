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
      ./hammerspoon
      # macOS 전용 모듈은 여기에 추가
    ]) ++ [
      ./homerow
      # 공통 모듈은 여기에 추가
    ];
}
