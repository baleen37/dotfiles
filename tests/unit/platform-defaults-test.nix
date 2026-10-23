# platform-defaults-test.nix
# home-manager.nix sets no enable flags: every discovered module is on because
# its own option defaults to true. A new module declared with a bare
# lib.mkEnableOption (default false) would be imported and silently do nothing,
# so this checks every module's default on both platforms. Darwin-only GUI
# tools default to pkgs.stdenv.hostPlatform.isDarwin instead.
#
# Strategy: mock pkgs with overridden stdenv.hostPlatform.isDarwin to simulate
# both platforms, then evalModules each module and read .config.modules.*

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

  # Programs that must stay off on Linux. Everything else defaults to true.
  darwinOnly = [
    "hammerspoon"
    "karabiner"
    "raycast"
  ];

  # Override isDarwin in pkgs to simulate Darwin vs Linux
  mockPkgs =
    isDarwin:
    pkgs
    // {
      stdenv = pkgs.stdenv // {
        hostPlatform = pkgs.stdenv.hostPlatform // {
          inherit isDarwin;
        };
      };
    };

  enableDefault =
    category: name: modulePath: isDarwin:
    (lib.evalModules {
      modules = [
        modulePath
        {
          _module.args = {
            pkgs = mockPkgs isDarwin;
            inherit inputs isDarwin;
            currentSystemUser = "testuser";
          };
          _module.check = false;
        }
      ];
    }).config.modules.${category}.${name}.enable;

  testsFor =
    category:
    lib.concatLists (
      lib.mapAttrsToList (
        name: modulePath:
        let
          onLinux = category != "programs" || !(builtins.elem name darwinOnly);
        in
        [
          (helpers.assertTest "${category}-${name}-darwin" (enableDefault category name modulePath true)
            "modules.${category}.${name}.enable must default to true on Darwin; home-manager.nix sets no enable flags"
          )
          (helpers.assertTest "${category}-${name}-linux" (
            enableDefault category name modulePath false == onLinux
          ) "modules.${category}.${name}.enable must default to ${lib.boolToString onLinux} on non-Darwin")
        ]
      ) homeModules.${category}
    );
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "platform-defaults" (
    testsFor "programs"
    ++ testsFor "packages"
    ++ [
      (helpers.assertTest "darwin-only-list-is-current" (lib.all (
        name: homeModules.programs ? ${name}
      ) darwinOnly) "every name in darwinOnly must be a module under users/shared/programs")
    ]
  );
}
