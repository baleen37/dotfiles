{ config, pkgs, ... }: {
  home.username = "linuxuser";
  home.homeDirectory = "/home/linuxuser";
  home.stateVersion = "25.05";
  # 필요한 경우 home.packages 등 추가 가능
}
