{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  hostConfig = import ../lib/hosts.nix { inherit lib; };

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
    baleen-m2-pro = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "baleen";
    };
    kakaostyle-jito = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "jito.hello";
    };
  };

  machineModules = lib.mapAttrs (_: host: host.machineModules) hostConfig;

  expectedMachineModules = {
    macbook-pro = [ ../../machines/darwin/macbook-pro.nix ];
    baleen-macbook = [ ../../machines/darwin/baleen-macbook.nix ];
    baleen-m2-pro = [ ../../machines/darwin/macbook-pro.nix ];
    kakaostyle-jito = [ ../../machines/darwin/kakaostyle-jito.nix ];
  };
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "host-metadata" [
    (helpers.assertTest "host-summary" (
      hostSummary == expectedSummary
    ) "hosts.nix should declare the expected typed host summary")

    (helpers.assertTest "machine-module-paths" (
      machineModules == expectedMachineModules
    ) "every host should declare exactly its expected machineModules")

    (helpers.assertTest "intel-darwin-absent" (
      !(lib.any (host: host.system == "x86_64-darwin") (lib.attrValues hostConfig))
    ) "host metadata should not reintroduce x86_64-darwin")
  ];
}
