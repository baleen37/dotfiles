{
  config,
  pkgs,
  inputs,
  hostName, # hostName 추가
  ...
}: let
  commonUserConfig = { username, homeDirectory, extraPackages ? [] }: {
    home.username = username;
    home.homeDirectory = homeDirectory;
    home.packages = with pkgs; [
      git
      fzf
      google-chrome
      brave
      # devtools
      # jetbrains.datagrip
      # jetbrains.idea-ultimate
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

    home-manager.users =
      if hostName == "baleen" then {
        baleen = commonUserConfig {
          username = "baleen";
          homeDirectory = "/Users/baleen";
        };
      } else if hostName == "jito" then {
        jito = commonUserConfig {
          username = "jito";
          homeDirectory = "/Users/jito";
        };
      } else {}; # 다른 호스트 이름의 경우 빈 사용자 설정을 반환하거나 오류 처리
}
