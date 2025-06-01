{ config, pkgs, ... }:
{
  system.stateVerion = 6;
  users.users.baleen = {
    home = "/Users/baleen";
    shell = pkgs.zsh;
  };
}
