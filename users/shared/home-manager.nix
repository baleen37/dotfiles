{
  pkgs,
  currentSystemUser,
  inputs,
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  ...
}:

{
  imports = [
    inputs.direnv-instant.homeModules.direnv-instant

    # Darwin GUI ownership and LaunchServices repair.
    ./darwin/vscode-launchservices.nix
    ./darwin/keyboard-input.nix
  ]
  # Every module under programs/ and packages/, each enabled by its own option
  # default (see lib/home-modules.nix).
  ++ (
    let
      discovered = import ../../lib/home-modules.nix { inherit lib; };
    in
    builtins.attrValues discovered.programs ++ builtins.attrValues discovered.packages
  );

  home = {
    username = currentSystemUser;
    homeDirectory = if isDarwin then "/Users/${currentSystemUser}" else "/home/${currentSystemUser}";
    stateVersion = "24.11";
  };

  xdg.enable = true;

  manual.manpages.enable = false;
}
