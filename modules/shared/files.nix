{ pkgs, config, user, self, lib, ... }:

let
  userHome =
    if pkgs.stdenv.isDarwin
    then config.users.users.${user}.home or "/Users/${user}"
    else builtins.getEnv "HOME";

  # mkCommandFiles function removed - Claude files are now managed by platform-specific activation scripts

in
{
  # Claude configuration files are managed by platform-specific activation scripts
  # to ensure proper preservation of user modifications
  "${userHome}/.gitconfig_global".text = "";

  # WezTerm configuration
  "${userHome}/.wezterm.lua".text = builtins.readFile ./config/wezterm/wezterm.lua;
  # Claude command files are also managed by platform-specific activation scripts
}
