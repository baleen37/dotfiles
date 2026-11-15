{ currentSystemUser, ... }:
{
  imports = [ ./development.nix ];

  security.sudo.extraConfig = ''
    ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild ^switch --flake \.\#kakaostyle-jito$
    ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/nh ^clean all --keep 3$
  '';
}
