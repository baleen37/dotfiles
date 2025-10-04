# Fzf Fuzzy Finder Configuration
#
# Fzf configuration with optimized file finding and history.
#
# VERSION: 3.1.0 (Extracted from productivity.nix)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, platformInfo
, userInfo
, ...
}:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "rg --files --hidden --follow --glob '!.git/*'";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
  };
}
