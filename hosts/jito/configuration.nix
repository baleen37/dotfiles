{ config, pkgs, ... }:
{
  system.stateVersion = 4;
  users.users.jito = {
    home = "/Users/jito";
    shell = pkgs.zsh;
  };
}
