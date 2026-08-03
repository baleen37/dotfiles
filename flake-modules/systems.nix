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

  hostsByClass = cls: lib.filterAttrs (_: h: h.class == cls) config.dotfiles.hosts;

  mkDarwin =
    name: h:
    mkSystem name {
      inherit (h) system user;
      darwin = true;
      inherit (h) homeModules machineModules;
    };

  mkNixos =
    name: h:
    mkSystem name {
      inherit (h) system user;
      inherit (h) homeModules machineModules;
    };
in
{
  flake.darwinConfigurations = lib.mapAttrs mkDarwin (hostsByClass "darwin");
  flake.nixosConfigurations = lib.mapAttrs mkNixos (hostsByClass "nixos");
}
