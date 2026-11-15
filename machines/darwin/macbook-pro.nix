{
  lib,
  currentSystemName,
  currentSystemUser,
  ...
}:
{
  imports = [ ./development.nix ];

  security.sudo.extraConfig = ''
    ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild ^switch --flake (\.|path:(/private)?/tmp/dotfiles-source\.[A-Za-z0-9]+/source)\#${lib.escapeRegex currentSystemName}$
    ${currentSystemUser} ALL = (root) NOPASSWD: /run/current-system/sw/bin/nh ^clean all --keep 3$
  '';
}
