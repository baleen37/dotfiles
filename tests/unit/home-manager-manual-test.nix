# Home Manager manual settings regression test.
#
# The default Home Manager manpage manual evaluates options documentation,
# which can emit options.json context warnings during darwin-rebuild switch.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  hmConfig = import ../../users/shared/home-manager.nix {
    inherit pkgs lib inputs;
    currentSystemUser = "baleen";
  };
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "home-manager-manual" [
    (helpers.assertTest "home-manager-manual-manpages-disabled" (
      (hmConfig.manual.manpages.enable or true) == false
    ) "Home Manager manual manpages should be disabled for warning-free switch builds")
  ];
}
