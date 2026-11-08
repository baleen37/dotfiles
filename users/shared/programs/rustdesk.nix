{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.programs.rustdesk;
  configDir = "${config.home.homeDirectory}/Library/Preferences/com.carriez.RustDesk";
  localDefaults = builtins.toFile "RustDesk_local.toml" ''
    [options]
    lang = "ko"
  '';
  sessionDefaults = builtins.toFile "RustDesk_default.toml" ''
    [options]
    image_quality = "balanced"
    view_style = "adaptive"
  '';
in
{
  options.modules.programs.rustdesk.enable = lib.mkEnableOption "RustDesk (macOS)";

  config = lib.mkIf cfg.enable {
    # RustDesk writes these files itself; seed writable defaults only once.
    home.activation.rustdeskConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${lib.escapeShellArg configDir}
      if [ ! -f ${lib.escapeShellArg "${configDir}/RustDesk_local.toml"} ]; then
        run install -m 600 ${localDefaults} ${lib.escapeShellArg "${configDir}/RustDesk_local.toml"}
      fi
      if [ ! -f ${lib.escapeShellArg "${configDir}/RustDesk_default.toml"} ]; then
        run install -m 600 ${sessionDefaults} ${lib.escapeShellArg "${configDir}/RustDesk_default.toml"}
      fi
    '';

    launchd.agents.rustdesk = {
      enable = true;
      config = {
        ProgramArguments = [ "/Applications/RustDesk.app/Contents/MacOS/RustDesk" ];
        RunAtLoad = true;
        ProcessType = "Interactive";
      };
    };
  };
}
