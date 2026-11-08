# tests/lib/hosts.nix
#
# The `dotfiles.hosts` table from flake-modules/hosts.nix, evaluated on its own
# so tests can read host metadata without going through the flake outputs.
{ lib }:
(lib.evalModules {
  modules = [ ../../flake-modules/hosts.nix ];
}).config.dotfiles.hosts
