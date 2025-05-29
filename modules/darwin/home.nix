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
      ../../programs/common/wezterm/default.nix
      ../../programs/common/git/default.nix
      ../../programs/common/tmux/default.nix
      ../../programs/common/nvim/default.nix
      ../../programs/common/vscode/default.nix
      ../../programs/common/ssh/default.nix
      ../../programs/common/act/default.nix
      ../../programs/common/syncthing/default.nix
      ../../programs/common/obsidian/default.nix
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
