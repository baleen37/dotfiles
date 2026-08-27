# Baleen toolkit CLI configuration.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.baleen-toolkit;
  bl = pkgs.writeShellApplication {
    name = "bl";
    # Cleanup steps handle optional command failures and continue. Avoid the
    # helper's default errexit so one unavailable cache does not abort GC.
    bashOptions = [
      "nounset"
      "pipefail"
    ];
    runtimeInputs = with pkgs; [
      bash
      coreutils
      gawk
      findutils
      gnused
      git
    ];
    text = builtins.readFile ./baleen-toolkit.sh;
  };
in
{
  options.modules.programs.baleen-toolkit.enable = lib.mkEnableOption "Baleen toolkit CLI";

  config = lib.mkIf cfg.enable {
    home.packages = [ bl ];
  };
}
