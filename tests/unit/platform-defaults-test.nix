# Optional modules stay off on both platforms; Git and SSH are baseline.

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
          enabled =
            category == "programs"
            && builtins.elem name [
              "git"
              "ssh"
            ];
        in
        [
          (helpers.assertTest "${category}-${name}-darwin" (
            enableDefault category name modulePath true == enabled
          ) "modules.${category}.${name}.enable must use the minimal baseline on Darwin")
          (helpers.assertTest "${category}-${name}-linux" (
            enableDefault category name modulePath false == enabled
          ) "modules.${category}.${name}.enable must default to ${lib.boolToString enabled} on non-Darwin")
        ]
      ) homeModules.${category}
    );
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "platform-defaults" (
    testsFor "programs" ++ testsFor "packages"

  );
}
