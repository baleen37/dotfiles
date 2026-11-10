{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.programs.tailscale;
  secretFile = ../../../secrets/remote-access.json;
  hasAuthKey = builtins.hasAttr "tailscale-auth-key" (
    builtins.fromJSON (builtins.readFile secretFile)
  );
  remote = pkgs.writeShellApplication {
    name = "dotfiles-remote";
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./tailscale-remote.py} "$@"
    '';
  };
in
{
  options.modules.programs.tailscale = {
    enable = lib.mkEnableOption "Tailscale (macOS)";
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = if hasAuthKey then config.sops.secrets.tailscale-auth-key.path else null;
      description = "Decrypted sops auth key or scoped OAuth secret for unattended enrollment; existing sessions are preserved.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib.mkIf hasAuthKey {
      tailscale-auth-key = {
        sopsFile = secretFile;
        format = "json";
      };
    };
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
