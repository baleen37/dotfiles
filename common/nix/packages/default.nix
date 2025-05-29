{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
in
{
  nixpkgs.overlays = [
    (final: prev: {
      hammerspoon = final.callPackage ./programs/hammerspoon {};
      homerow = final.callPackage ./programs/homerow {};
      # 필요시 다른 패키지를 여기에 추가
    })
  ];

  nixpkgs.config.allowUnfreePredicate = (
    pkg:
    builtins.elem (lib.getName pkg) [
      "1password"
      "1password-cli"
      "datagrip"
      "homerow"
      "raycast"
      "slack"
    ]
  );
}
