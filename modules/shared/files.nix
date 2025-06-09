{ pkgs, config, user, self, ... }:

let
  userHome = if pkgs.stdenv.isDarwin 
    then config.users.users.${user}.home or "/Users/${user}"
    else builtins.getEnv "HOME";
in
{

  "${userHome}/.claude" = {
    source = ./config/claude;
    recursive = true;
  };

  "${userHome}/.gitconfig_global" = {
    text = "";
  };
}

