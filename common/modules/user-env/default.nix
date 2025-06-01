{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin isLinux;

  cliModules = [
    ./cli/tmux
    ./cli/ssh
    ./cli/git
    ./cli/act
    ./cli/nvim
    ./cli/wezterm
    ./cli/1password
    ./cli/zsh
    ./cli/pre-commit
  ];

  guiModules = [
    ./gui/hammerspoon
    ./gui/homerow
    ./gui/karabiner-elements
    ./gui/raycast
    ./gui/vscode
    ./gui/obsidian
    ./gui/syncthing
  ];

in
{
  home-manager.sharedModules =
    (lib.optionals isDarwin guiModules)
    ++ cliModules;
}
