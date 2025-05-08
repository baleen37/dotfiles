{
  config,
  pkgs,
  inputs,
  ...
}: {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    nixpkgs.config.allowUnfree = true;

    home-manager.users.baleen =
        { config, ... }:
      {
        home.username = "baleen"; # 사용자 이름
        home.homeDirectory = "/Users/baleen"; # 홈 디렉토리 경로

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
        ];

        # Install the gitconfig file, as .gitconfig in the home directory
        home.file.".gitconfig".source = ../../.gitconfig;

        # Required field - add stateVersion
        home.stateVersion = "25.05";
  };
}
