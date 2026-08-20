# tests/unit/host-overrides-test.nix
#
# Verifies that a host's `homeModules` attribute actually overrides
# `modules.programs.*.enable` in the resulting darwin configuration.
#
# The override is exercised through a throwaway host built here rather than
# through an entry in flake-modules/hosts.nix. An earlier version of this test
# asserted that kakaostyle-jito had hammerspoon disabled; #1273 deliberately
# re-enabled it and dropped the override, leaving the test failing on a stale
# expectation. Building the host locally keeps the feature covered without
# pinning any real host's configuration.

{
  inputs,
  pkgs,
  lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  overlays = import ../../lib/overlays.nix { inherit inputs; };

  # `self` is only used for flake-level references that this configuration does
  # not reach, so the probe host does not need one.
  mkSystem = import ../../lib/mksystem.nix {
    inherit inputs overlays;
    self = null;
  };

  probeUser = "probeuser";

  hammerspoonEnabledWith =
    homeModules:
    (mkSystem "host-overrides-probe" {
      system = "aarch64-darwin";
      user = probeUser;
      darwin = true;
      inherit homeModules;
      machineModules = [ ../../machines/darwin/common.nix ];
    }).config.home-manager.users.${probeUser}.modules.programs.hammerspoon.enable;

  overridden = hammerspoonEnabledWith { modules.programs.hammerspoon.enable = false; };
  default = hammerspoonEnabledWith { };
in
{
  platforms = [ "darwin" ];
  value = {
    home-modules-override-reaches-config = helpers.assertTest "homeModules override reaches config" (
      overridden == false
    ) "host.homeModules must override modules.programs.hammerspoon.enable to false";

    no-override-keeps-module-default =
      helpers.assertTest "no override keeps module default" (default == true)
        "a host without homeModules must keep the module default (hammerspoon defaults to true on Darwin)";
  };
}
