{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
  overlays = [
    (final: prev: {
      hammerspoon = final.callPackage ./hammerspoon {};
      homerow = final.callPackage ./homerow {};
      # 필요시 다른 패키지를 여기에 추가
    })
  ];
  packages = system: let
    pkgs = import inputs.nixpkgs { inherit system; config.allowUnfree = true; };
  in if isDarwin then {
    hammerspoon = pkgs.callPackage ./hammerspoon {};
    homerow = pkgs.callPackage ./homerow {};
  } else {};
in {
  inherit overlays packages;
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
