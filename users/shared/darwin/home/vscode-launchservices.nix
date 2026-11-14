{
  isDarwin ? pkgs.stdenv.hostPlatform.isDarwin,
  config,
  lib,
  pkgs,
  ...
}:

{
  options.modules.darwin.vscode.enable = lib.mkEnableOption "vscode";

  config = lib.mkIf (isDarwin && config.modules.darwin.vscode.enable) {
    home.activation.vscodeLaunchServices = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.bash}/bin/bash ${./vscode-launchservices.sh} repair
    '';
  };
}
