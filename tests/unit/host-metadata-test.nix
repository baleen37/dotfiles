{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  hostConfig =
    (lib.evalModules {
      modules = [ ../../flake-modules/hosts.nix ];
    }).config.dotfiles.hosts;

  hostSummary = lib.mapAttrs (_: host: {
    inherit (host) system class user;
  }) hostConfig;

  expectedSummary = {
    macbook-pro = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "baleen";
    };
    baleen-macbook = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "baleen";
    };
    kakaostyle-jito = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "jito.hello";
    };
    vm-aarch64-utm = {
      system = "aarch64-linux";
      class = "nixos";
      user = "baleen";
    };
    vm-x86_64-utm = {
      system = "x86_64-linux";
      class = "nixos";
      user = "baleen";
    };
  };
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "host-metadata" [
    (helpers.assertTest "host-summary" (
      hostSummary == expectedSummary
    ) "hosts.nix should declare the expected typed host summary")

    (helpers.assertTest "machine-modules-present" (lib.all (host: host.machineModules != [ ]) (
      lib.attrValues hostConfig
    )) "every host should explicitly declare machineModules")

    (helpers.assertTest "intel-darwin-absent" (
      !(lib.any (host: host.system == "x86_64-darwin") (lib.attrValues hostConfig))
    ) "host metadata should not reintroduce x86_64-darwin")
  ];
}
