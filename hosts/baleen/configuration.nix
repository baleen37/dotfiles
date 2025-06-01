{ config, pkgs, ... }:
{
  system.stateVersion = 4;
  users.users.baleen = {
    home = "/Users/baleen";
    shell = pkgs.zsh;
  };
}
