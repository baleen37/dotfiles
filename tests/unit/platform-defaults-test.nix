# platform-defaults-test.nix
# Verifies that hammerspoon and karabiner default to enable=true on Darwin
# and enable=false on non-Darwin platforms.
#
# Strategy: mock pkgs with overridden stdenv.hostPlatform.isDarwin to simulate
# both platforms, then evalModules the modules and check .config.modules.*

{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Override isDarwin in pkgs to simulate Darwin vs Linux
  mockPkgs =
    isDarwin:
    pkgs
    // {
      stdenv = pkgs.stdenv // {
        hostPlatform = pkgs.stdenv.hostPlatform // { inherit isDarwin; };
      };
    };

  evalModuleConfig =
    modulePath: isDarwin:
    (lib.evalModules {
      modules = [
        modulePath
        {
          _module.args = {
            pkgs = mockPkgs isDarwin;
            currentSystemUser = "testuser";
          };
          _module.check = false;
        }
      ];
    }).config;

  hammerspoonOnDarwin = evalModuleConfig ../../users/shared/programs/hammerspoon.nix true;
  hammerspoonOnLinux = evalModuleConfig ../../users/shared/programs/hammerspoon.nix false;
  karabinerOnDarwin = evalModuleConfig ../../users/shared/programs/karabiner.nix true;
  karabinerOnLinux = evalModuleConfig ../../users/shared/programs/karabiner.nix false;

in
{
  platforms = [ "any" ];
  value = {
    hammerspoon-enabled-on-darwin = helpers.assertTest "hammerspoon default=true on Darwin"
      (hammerspoonOnDarwin.modules.programs.hammerspoon.enable == true)
      "Hammerspoon module must default to enable=true on Darwin";

    hammerspoon-disabled-on-linux = helpers.assertTest "hammerspoon default=false on Linux"
      (hammerspoonOnLinux.modules.programs.hammerspoon.enable == false)
      "Hammerspoon module must default to enable=false on non-Darwin";

    karabiner-enabled-on-darwin = helpers.assertTest "karabiner default=true on Darwin"
      (karabinerOnDarwin.modules.programs.karabiner.enable == true)
      "Karabiner module must default to enable=true on Darwin";

    karabiner-disabled-on-linux = helpers.assertTest "karabiner default=false on Linux"
      (karabinerOnLinux.modules.programs.karabiner.enable == false)
      "Karabiner module must default to enable=false on non-Darwin";
  };
}
