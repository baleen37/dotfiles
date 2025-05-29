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
      # apple-cursor-theme = final.callPackage ./modules/darwin/programs/apple-cursor-theme { };
      # cleanshot = final.callPackage ./modules/darwin/programs/cleanshot { };
      # clop = final.callPackage ./modules/darwin/programs/clop { };
      # deskpad = final.callPackage ./modules/darwin/programs/deskpad { };
      # git-spr = final.callPackage ./modules/darwin/programs/git-spr { };
      hammerspoon = final.callPackage ./programs/hammerspoon { };
      homerow = final.callPackage ./programs/homerow { };
      # nix-activate = final.callPackage ./modules/darwin/programs/nix-activate { };
      # orbstack = final.callPackage ./modules/darwin/programs/orbstack { };
      # pragmatapro = final.callPackage ./modules/darwin/programs/pragmatapro { };
      # redisinsight = final.callPackage ./modules/darwin/programs/redisinsight { };
      # ungoogled-chromium = (lib.mkIf isDarwin (final.callPackage ./modules/darwin/programs/ungoogled-chromium { }));
      # zpl-open = final.callPackage ./modules/darwin/programs/zpl-open { };
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
