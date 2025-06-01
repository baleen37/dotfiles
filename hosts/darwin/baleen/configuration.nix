{ config, pkgs, ... }:
{
  system.stateVersion = 6;
  users.users.baleen = {
    home = "/Users/baleen";
    shell = pkgs.zsh;
  };
}
