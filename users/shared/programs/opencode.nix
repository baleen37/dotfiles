# OpenCode CLI and its plugin list.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.opencode;

  # OpenCode installs plugins listed under `plugins` when its server starts.
  # The file stays writable so `opencode plugin add` keeps working.
  opencodeConfig = "${config.xdg.configHome}/opencode/opencode.json";
  plugins = [ "skills@git+https://github.com/baleen37/skills.git" ];
in
{
  options.modules.programs.opencode.enable = lib.mkEnableOption "OpenCode CLI configuration";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.opencode ];

    # Merge into the existing list so plugins added by hand survive.
    home.activation.opencodePlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      opencode_config=${lib.escapeShellArg opencodeConfig}
      current='{}'
      [ -f "$opencode_config" ] && current=$(cat "$opencode_config")
      if merged=$(printf '%s' "$current" | ${lib.getExe pkgs.jq} \
        --argjson add ${lib.escapeShellArg (builtins.toJSON plugins)} \
        '.plugins = ((.plugins // []) + $add | unique)'); then
        if [ "$merged" != "$current" ]; then
          tmp=$(mktemp)
          printf '%s\n' "$merged" > "$tmp"
          run mkdir -p "$(dirname "$opencode_config")"
          run mv "$tmp" "$opencode_config"
        fi
      else
        warnEcho "Skipping OpenCode plugins: $opencode_config is not plain JSON"
      fi
    '';
  };
}
