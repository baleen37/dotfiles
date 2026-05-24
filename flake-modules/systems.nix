{
  inputs,
  self,
  lib,
  config,
  overlays,
  ...
}:

let
  mkSystem = import ../lib/mksystem.nix { inherit inputs self overlays; };

  hostsByClass = cls: lib.filterAttrs (_: h: h.class == cls) config.flake.hosts;

  mkDarwin =
    name: h:
    mkSystem name {
      inherit (h) system user;
      darwin = true;
    };

  mkNixos =
    name: h:
    mkSystem name {
      inherit (h) system user;
    };
in
{
  flake.darwinConfigurations = lib.mapAttrs mkDarwin (hostsByClass "darwin");
  flake.nixosConfigurations = lib.mapAttrs mkNixos (hostsByClass "nixos");
}
