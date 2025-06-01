{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin isLinux;
in
{

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };


  home.shellAliases = {
    code = "/usr/bin/open -a 'Visual Studio Code'";
  };
}
