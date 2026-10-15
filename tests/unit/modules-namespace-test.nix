# modules-namespace-test.nix
# Every module lib/home-modules.nix discovers must declare its enable option
# under modules.<category>.<name>.enable, where <name> is its file or directory
# name. home-manager.nix imports whatever is discovered, so a helper .nix file
# left in programs/ or packages/, or a module whose option name drifted from
# its file name, would otherwise be imported without anything controlling it.
#
# Strategy: lib.evalModules with _module.check = false to allow home-manager
# option assignments without pulling in the full home-manager module tree.

{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  homeModules = import ../../lib/home-modules.nix { inherit lib; };

  declaresEnable =
    category: name: modulePath:
    let
      opts =
        (lib.evalModules {
          modules = [
            modulePath
            {
              _module.args = {
                inherit pkgs inputs;
                currentSystemUser = "testuser";
                isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
              };
              _module.check = false;
            }
          ];
        }).options;
    in
    lib.hasAttrByPath [ "modules" category name "enable" ] opts;

  testsFor =
    category:
    lib.mapAttrs' (
      name: modulePath:
      lib.nameValuePair "${category}-${name}-has-enable" (
        helpers.assertTest "modules.${category}.${name}.enable" (declaresEnable category name modulePath)
          "users/shared/${category}/${name} must declare options.modules.${category}.${name}.enable; helper files belong inside the module's own directory"
      )
    ) homeModules.${category};
in
{
  platforms = [ "any" ];
  value = testsFor "programs" // testsFor "packages";
}
