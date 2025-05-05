{ ... }: {
    programs.home-manager.enable = true;

    # Packages to install
    home.packages = with pkgs; [
        cowsay
    ]
}