# Yarn (Berry) user-level configuration
#
# ~/.yarnrc.yml applies to every Yarn 2+ project unless the project's own
# .yarnrc.yml sets the same key, so a repository can still opt out.
# nmMode hardlinks-global makes node_modules hardlinks into Yarn's global
# content-addressed store; each worktree of a repo then costs almost no disk.
{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.programs.yarn;
in
{
  options.modules.programs.yarn.enable = lib.mkEnableOption "Yarn user configuration" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.file.".yarnrc.yml".text = ''
      nmMode: hardlinks-global
    '';
  };
}
