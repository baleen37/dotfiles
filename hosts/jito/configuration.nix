{ config, pkgs, ... }:
{
  system.stateVersion = 6;
  users.users.jito = {
    home = "/Users/jito";
    shell = pkgs.zsh;
  };
}
