{ pkgs, config, user, self, lib, ... }:

let
  # Use unified user resolution system
  getUserInfo = import ../../lib/user-resolution.nix {
    platform = if pkgs.stdenv.isDarwin then "darwin" else "linux";
    returnFormat = "extended";
  };
  userHome = getUserInfo.homePath;

  # mkCommandFiles function removed - Claude files are now managed by platform-specific activation scripts

in
{
  # Claude configuration files are managed by platform-specific activation scripts
  # to ensure proper preservation of user modifications
  "${userHome}/.gitconfig_global".text = "";

  # Claude command files are also managed by platform-specific activation scripts
}
