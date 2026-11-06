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

  mkHost =
    name: h:
    mkSystem name {
      inherit (h)
        system
        user
        homeModules
        machineModules
        ;
      darwin = h.class == "darwin";
    };
in
{
  flake.darwinConfigurations = lib.mapAttrs mkHost (hostsByClass "darwin");
  flake.nixosConfigurations = lib.mapAttrs mkHost (hostsByClass "nixos");
}
