# users/shared/opencode.nix
# OpenCode configuration managed via Home Manager
# Configuration files shared with Claude Code
#
# NOTE: commands are now managed via external plugin:
# https://github.com/baleen37/claude-plugins

{
  pkgs,
  lib,
  ...
}:

{
  home.file.".config/opencode/opencode.json" = {
    source = ./.config/opencode/opencode.json;
    force = true;
  };
}
