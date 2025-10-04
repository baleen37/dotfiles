# Claude Code Configuration Module
#
# Creates symlinks to Claude configuration files in config/claude/
# Supports both macOS and Linux platforms
#
# VERSION: 4.0.0 (Multi-platform symlink-based)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, platformInfo
, userInfo
, ...
}:

let
  inherit (userInfo) paths name;
  inherit (platformInfo) isDarwin isLinux;

  # Path to actual Claude config files
  claudeConfigDir = "${paths.home}/dev/dotfiles/modules/shared/config/claude";

  # Claude Code uses ~/.claude for both platforms
  claudeHomeDir = ".claude";

in
{
  # No packages needed - Claude Code installed separately
  home.packages = [ ];

  # Symlink all Claude configuration files
  home.file = {
    # Main settings file
    "${claudeHomeDir}/settings.json" = {
      source = "${claudeConfigDir}/settings.json";
      onChange = ''
        echo "Claude settings.json updated"
      '';
    };

    # CLAUDE.md documentation
    "${claudeHomeDir}/CLAUDE.md" = {
      source = "${claudeConfigDir}/CLAUDE.md";
    };

    # Hooks directory
    "${claudeHomeDir}/hooks" = {
      source = "${claudeConfigDir}/hooks";
      recursive = true;
    };

    # Commands directory
    "${claudeHomeDir}/commands" = {
      source = "${claudeConfigDir}/commands";
      recursive = true;
    };

    # Agents directory
    "${claudeHomeDir}/agents" = {
      source = "${claudeConfigDir}/agents";
      recursive = true;
    };
  };

  # No programs configuration needed
  programs = { };
}
