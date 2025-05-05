{ pkgs, ... }: {
    programs.home-manager.enable = true;

    # Packages to install
    home.packages = with pkgs; [
      git
    ];

    # Install the gitconfig file, as .gitconfig in the home directory
    home.file.".gitconfig".source = ./.gitconfig;

    # Required field - add stateVersion
    home.stateVersion = "23.11"; # 사용 중인 Nix/Home-Manager 버전에 맞게 조정할 수 있습니다
}

