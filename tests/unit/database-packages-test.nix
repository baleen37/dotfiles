{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  homeManagerSource = builtins.readFile ../../users/shared/home-manager.nix;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "database-packages" [
    (helpers.assertTest "mysql80-removed-from-home-manager" (
      !(lib.hasInfix "mysql80" homeManagerSource)
    ) "home-manager.nix should not reference removed mysql80 package")

    (helpers.assertTest "mariadb-client-added-to-home-manager" (
      lib.hasInfix "mariadb.client" homeManagerSource
    ) "home-manager.nix should use mariadb.client instead of mysql80")
  ];
}
