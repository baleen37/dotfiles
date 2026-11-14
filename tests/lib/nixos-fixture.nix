# Exercise the NixOS system factory without registering a deployable host.
{ inputs, self }:
let
  mkSystem = import ../../lib/mksystem.nix { inherit inputs self; };
in
mkSystem "nixos-probe" {
  system = "x86_64-linux";
  user = "testuser";
  machineModules = [ { system.stateVersion = "24.11"; } ];
}
