# OpenCode CLI and its plugin list.
#
# mutableSettings writes these settings to opencode/home-manager.json and
# points OPENCODE_CONFIG at it, so opencode.json stays writable for
# `opencode plugin add`. OpenCode installs listed plugins when its server starts.

{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.programs.opencode;
in
{
  options.modules.programs.opencode.enable = lib.mkEnableOption "OpenCode CLI configuration";

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      mutableSettings = true;
      # OpenCode 2.x reads `plugins`; 1.x used `plugin`.
      settings.plugins = [
        "skills@git+https://github.com/baleen37/skills.git"
        "superpowers@git+https://github.com/obra/superpowers.git"
      ];
    };
  };
}
