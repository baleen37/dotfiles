# tests/unit/mksystem-darwin-test.nix
#
# Darwin-only counterpart to mksystem-test.nix: nix.enable must stay off so
# Determinate owns the daemon, and GC has to be delegated to determinate-nixd
# because nix.gc is inert once nix.enable is false.
{
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  darwin = self.darwinConfigurations.macbook-pro.config;
in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "mksystem-darwin" [
    (helpers.assertTest "determinate-collects-garbage" (
      darwin.determinateNix.determinateNixd.garbageCollector.strategy == "automatic"
    ) "Determinate Nixd must own GC on Darwin; nix.gc does nothing while nix.enable = false")

    (helpers.assertTest "nix-daemon-left-to-determinate" (
      darwin.nix.enable == false
    ) "nix.enable must stay false on Darwin so nix-darwin does not fight the Determinate daemon")

    (helpers.assertTest "determinate-gets-cache-settings" (
      darwin.determinateNix.customSettings.substituters
      == (import ../../lib/cache-config.nix).substituters
    ) "determinateNix.customSettings must carry the substituters from lib/cache-config.nix")

    (helpers.assertTest "home-manager-backs-up-collisions" (
      darwin.home-manager.backupFileExtension == "backup"
    ) "home-manager needs a backup extension or the first switch aborts on existing files")
  ];
}
