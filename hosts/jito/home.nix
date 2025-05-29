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
  ];

  home.username = "jito";
  home.homeDirectory = "/Users/jito";
  home.packages = with pkgs; [
    git
    fzf
    google-chrome
    brave
  ];
  home.file.".gitconfig".source = ../../.gitconfig;
  home.stateVersion = "25.05";
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  nixpkgs.config.allowUnfree = true;
}
