{
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  expectedRule = ''jito.hello ALL = (root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild ^switch --flake \.\#kakaostyle-jito$'';
  expectedNhRule = "jito.hello ALL = (root) NOPASSWD: /run/current-system/sw/bin/nh ^clean all --keep 3$";
  jitoSudo = self.darwinConfigurations.kakaostyle-jito.config.security.sudo.extraConfig;
  macbookSudo = self.darwinConfigurations.macbook-pro.config.security.sudo.extraConfig;
  otherMacSudo = self.darwinConfigurations.baleen-macbook.config.security.sudo.extraConfig;
  jitoPam = self.darwinConfigurations.kakaostyle-jito.config.security.pam.services.sudo_local;
in
{
  platforms = [ "darwin" ];
  value = {
    kakaostyle-switch-is-passwordless =
      helpers.assertTest "kakaostyle switch is passwordless" (lib.hasInfix expectedRule jitoSudo)
        "kakaostyle-jito should allow only its exact darwin-rebuild switch command without a password";

    kakaostyle-nh-clean-is-passwordless =
      helpers.assertTest "kakaostyle nh clean is passwordless" (lib.hasInfix expectedNhRule jitoSudo)
        "make switch runs this exact nh clean after switching; drift from the Makefile turns it into a password prompt";

    macbook-switch-is-passwordless = helpers.assertTest "macbook switch is passwordless" (
      lib.hasInfix "NOPASSWD: /run/current-system/sw/bin/darwin-rebuild" macbookSudo
      && lib.hasInfix "path:(/private)?/tmp/dotfiles-source" macbookSudo
    ) "macbook-pro must allow switch with the filtered snapshot used for local host registration";

    macbook-switch-arguments-are-restricted =
      pkgs.runCommand "macbook-switch-arguments-are-restricted" { }
        ''
          pattern=$(sed -n 's@^baleen ALL = (root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild @@p' ${pkgs.writeText "macbook-sudoers" macbookSudo})
          test -n "$pattern"
          for args in \
            'switch --flake .#macbook-pro' \
            'switch --flake path:/tmp/dotfiles-source.A1b2C3/source#macbook-pro' \
            'switch --flake path:/private/tmp/dotfiles-source.A1b2C3/source#macbook-pro'; do
            printf '%s\n' "$args" | grep -Eq "$pattern"
          done
          for args in \
            'switch --flake .#kakaostyle-jito' \
            'switch --flake .#macbook-pro --impure' \
            'switch --flake path:/tmp/other/source#macbook-pro' \
            'switch --flake path:/tmp/dotfiles-source.A1b2C3/source/../other#macbook-pro' \
            'build --flake .#macbook-pro'; do
            if printf '%s\n' "$args" | grep -Eq "$pattern"; then
              echo "Unexpected sudo permission: $args" >&2
              exit 1
            fi
          done
          touch "$out"
        '';

    other-host-switch-needs-password = helpers.assertTest "other host switch needs password" (
      !lib.hasInfix "NOPASSWD: /run/current-system/sw/bin/darwin-rebuild" otherMacSudo
    ) "baleen-macbook should not inherit macbook-pro's passwordless switch rule";

    other-host-passwordless-scope = helpers.assertTest "other host passwordless scope" (
      lib.filter (lib.hasInfix "NOPASSWD") (lib.splitString "\n" otherMacSudo) == [
        ''baleen ALL = (root) NOPASSWD: /run/current-system/sw/bin/dotfiles-remote-configure ""''
      ]
    ) "baleen-macbook may only invoke its fixed remote-access helper without arguments";

    no-unrestricted-passwordless-sudo = helpers.assertTest "no unrestricted passwordless sudo" (
      !lib.hasInfix "NOPASSWD: ALL" jitoSudo
      && !lib.hasInfix "NOPASSWD: ALL" macbookSudo
      && !lib.hasInfix "NOPASSWD: ALL" otherMacSudo
    ) "Darwin hosts should not allow unrestricted passwordless sudo";

    # A password prompt is unanswerable from a non-interactive shell, so sudo
    # has to have an authentication path that does not need a terminal.
    sudo-accepts-touch-id =
      helpers.assertTest "sudo accepts touch id" jitoPam.touchIdAuth
        "sudo should accept Touch ID so non-interactive shells are not blocked on a password prompt";

    touch-id-works-in-multiplexers =
      helpers.assertTest "touch id works in multiplexers" jitoPam.reattach
        "Touch ID for sudo should reattach so it keeps working inside tmux sessions";
  };
}
