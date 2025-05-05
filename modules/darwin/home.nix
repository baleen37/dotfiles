{
  config,
  pkgs,
  inputs,
  ...
}: {
    home.username = "baleen"; # 사용자 이름
    home.homeDirectory = "/Users/baleen"; # 홈 디렉토리 경로
    programs.home-manager.enable = true;

    # Packages to install
    home.packages = with pkgs; [
        git
        fzf

        # devtools
        jetbrains.datagrip
        jetbrains.idea-ultimate
    ];
    imports = [
      # ../shared/programs/1password
      ./programs/raycast
    ];

    # Install the gitconfig file, as .gitconfig in the home directory
    home.file.".gitconfig".source = ../../.gitconfig;

    # Required field - add stateVersion
    home.stateVersion = "25.05";
}
