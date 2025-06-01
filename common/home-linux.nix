{ config, pkgs, ... }: {
  imports = [
    ../modules/user-env/cli/wezterm
    ../modules/user-env/cli/git
    ../modules/user-env/cli/tmux
    ../modules/user-env/cli/nvim
    ../modules/user-env/cli/act
    ../modules/user-env/cli/ssh
    ../modules/user-env/cli/1password
  ];
  home.username = "runner";
  home.homeDirectory = "/home/runner";
  home.stateVersion = "25.05";
  # 필요한 경우 home.packages 등 추가 가능
}
