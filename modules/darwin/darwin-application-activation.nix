{ lib, pkgs, config, ... }:
{
  # Copy GUI apps to "~/Applications/Home Manager Apps"
  # Based on this comment: https://github.com/nix-community/home-manager/issues/1341#issuecomment-778820334
  home.activation.darwinApps =
    if pkgs.stdenv.isDarwin then
      let
        apps = pkgs.buildEnv {
          name = "home-manager-applications";
          paths = config.home.packages;
          pathsToLink = "/Applications";
        };
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Install MacOS applications to the user environment.
        HM_APPS="$HOME/Applications/Home Manager Apps"
        # Reset current state
        [ -e "$HM_APPS" ] && $DRY_RUN_CMD rm -r "$HM_APPS"
        $DRY_RUN_CMD mkdir -p "$HM_APPS"
        # .app dirs need to be actual directories for Finder to detect them as Apps.
        # In the env of Apps we build, the .apps are symlinks. We pass all of them as
        # arguments to cp and make it dereference those using -H
        $DRY_RUN_CMD cp --archive -H --dereference ${apps}/Applications/* "$HM_APPS"
        $DRY_RUN_CMD chmod +w -R "$HM_APPS"
      ''
    else
      "";
}
