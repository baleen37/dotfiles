{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.programs.tailscale;
  remote = pkgs.writeShellApplication {
    name = "dotfiles-remote";
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./tailscale-remote.py} "$@"
    '';
  };
in
{
  options.modules.programs.tailscale.enable = lib.mkEnableOption "Tailscale (macOS)";

  config = lib.mkIf cfg.enable {
    home.packages = [ remote ];
    launchd.agents.tailscale = {
      enable = true;
      config = {
        ProgramArguments = [
          "/usr/bin/open"
          "-g"
          "/Applications/Tailscale.app"
        ];
        RunAtLoad = true;
        ProcessType = "Interactive";
      };
    };
  };
}
