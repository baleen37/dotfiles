{
  config,
  pkgs,
  inputs,
  ...
}: let
  commonUserConfig = { username, homeDirectory }: {
    home.username = username;
    home.homeDirectory = homeDirectory;
    home.packages = with pkgs; [
      git
      fzf
      google-chrome
      brave
      # devtools
      jetbrains.datagrip
      jetbrains.idea-ultimate
    ];
    imports = [
      ../shared/programs/wezterm
      ../shared/programs/git
      ../shared/programs/tmux
      ../shared/programs/nvim
      ../shared/programs/vscode
      ../shared/programs/ssh
      ../shared/programs/act
      ./programs/raycast
      ./programs/homerow
      ./programs/obsidian
      ./programs/hammerspoon
      ./programs/karabiner-elements
      ./programs/syncthing
    ];
    home.file.".gitconfig".source = ../../.gitconfig;
    home.stateVersion = "25.05";
  };
in
{
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    nixpkgs.config.allowUnfree = true;

    home-manager.users.baleen =
        { config, ... }: commonUserConfig {
          username = "baleen";
          homeDirectory = "/Users/baleen";
        };

    home-manager.users.jito =
        { config, ... }: commonUserConfig {
          username = "jito";
          homeDirectory = "/Users/jito";
        };
}
