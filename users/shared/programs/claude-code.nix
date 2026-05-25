# users/shared/claude-code.nix
# Claude Code configuration managed via Home Manager
# Configuration files only - package managed in home-manager.nix
#
# NOTE: commands, agents, skills, and hooks are now managed via external plugin:
# https://github.com/baleen37/claude-plugins

{ config, lib, ... }:

let
  cfg = config.modules.programs.claude-code;
in
{
  options.modules.programs.claude-code.enable = lib.mkEnableOption "Claude Code configuration";

  config = lib.mkIf cfg.enable { };
}
