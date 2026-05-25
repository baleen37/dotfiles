# tests/unit/host-overrides-test.nix
#
# Verifies that a host's `homeModules` attribute actually overrides
# `modules.programs.*.enable` in the resulting darwin configuration.

{
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # The kakaostyle-jito host should have hammerspoon disabled via homeModules.
  jitoCfg = self.darwinConfigurations.kakaostyle-jito.config;

  hammerspoonEnabledOnJito =
    jitoCfg.home-manager.users."jito.hello".modules.programs.hammerspoon.enable;

  # By contrast, macbook-pro (no override) should keep the module-level default
  # (`pkgs.stdenv.hostPlatform.isDarwin` == true on aarch64-darwin).
  # Note: macbook-pro resolves to the current USER (jito.hello in this env).
  proCfg = self.darwinConfigurations.macbook-pro.config;

  macbookProUsers = builtins.attrNames proCfg.home-manager.users;
  macbookProUser = builtins.head macbookProUsers;

  hammerspoonEnabledOnPro =
    proCfg.home-manager.users.${macbookProUser}.modules.programs.hammerspoon.enable;

in
{
  platforms = [ "darwin" ];
  value = {
    override-disables-hammerspoon = helpers.assertTest "kakaostyle-jito disables hammerspoon" (
      hammerspoonEnabledOnJito == false
    ) "host.homeModules must override modules.programs.hammerspoon.enable to false on kakaostyle-jito";

    default-keeps-hammerspoon = helpers.assertTest "macbook-pro keeps hammerspoon default" (
      hammerspoonEnabledOnPro == true
    ) "macbook-pro (no override) must keep hammerspoon default=true (Darwin)";
  };
}
