{
  config,
  pkgs,
  inputs,
  hostName,
  ...
}:
{
  imports = [
    ../../common/modules/user-env/cli/wezterm
    ../../common/modules/user-env/cli/git
    ../../common/modules/user-env/cli/tmux
    ../../common/modules/user-env/cli/nvim
    ../../common/modules/user-env/cli/act
    ../../common/modules/user-env/cli/ssh
    ../../common/modules/user-env/cli/1password
    ../../common/modules/user-env/gui/raycast
    ../../common/modules/user-env/gui/homerow
    ../../common/modules/user-env/gui/obsidian
    ../../common/modules/user-env/gui/hammerspoon
    ../../common/modules/user-env/gui/karabiner-elements
    ../../common/modules/user-env/gui/syncthing
    ../../common/modules/user-env/gui/vscode
  ];

  home.username = "baleen";
  home.homeDirectory = "/Users/baleen";
  home.packages = with pkgs; [
    git
    fzf
    google-chrome
    brave
  ];
  home.file.".gitconfig".source = ../../.gitconfig;
  home.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;
}
