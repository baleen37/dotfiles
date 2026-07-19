{
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  expectedRule = ''jito.hello ALL = (root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild ^switch --flake \.\#kakaostyle-jito$'';
  jitoSudo = self.darwinConfigurations.kakaostyle-jito.config.security.sudo.extraConfig;
  macbookSudo = self.darwinConfigurations.macbook-pro.config.security.sudo.extraConfig;
in
{
  platforms = [ "darwin" ];
  value = {
    kakaostyle-switch-is-passwordless =
      helpers.assertTest "kakaostyle switch is passwordless" (lib.hasInfix expectedRule jitoSudo)
        "kakaostyle-jito should allow only its exact darwin-rebuild switch command without a password";

    other-host-switch-needs-password = helpers.assertTest "other host switch needs password" (
      !lib.hasInfix "NOPASSWD" macbookSudo
    ) "other Darwin hosts should not inherit the passwordless switch rule";

    no-unrestricted-passwordless-sudo = helpers.assertTest "no unrestricted passwordless sudo" (
      !lib.hasInfix "NOPASSWD: ALL" jitoSudo
    ) "kakaostyle-jito should not allow unrestricted passwordless sudo";
  };
}
