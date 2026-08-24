{
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf isDarwin {
    home.activation.vscodeLaunchServices = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.bash}/bin/bash ${./vscode-launchservices.sh} repair
    '';
  };
}
