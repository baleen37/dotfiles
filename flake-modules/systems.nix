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

  syncthingPeers = lib.mapAttrs (_: h: h.syncthingId) (
    lib.filterAttrs (_: h: h.syncthingId != null) config.dotfiles.hosts
  );

  hostsByClass = cls: lib.filterAttrs (_: h: h.class == cls) config.dotfiles.hosts;

  mkHost =
    name: h:
    mkSystem name {
      inherit (h)
        system
        user
        machineModules
        ;
      homeModules = lib.mkMerge [
        h.homeModules
        { modules.programs.syncthing.peers = syncthingPeers; }
      ];
      darwin = h.class == "darwin";
    };
in
{
  flake.darwinConfigurations = lib.mapAttrs mkHost (hostsByClass "darwin");
  flake.nixosConfigurations = lib.mapAttrs mkHost (hostsByClass "nixos");
}
