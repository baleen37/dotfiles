# Fzf fuzzy finder configuration
#
# File search and command history exploration with fzf
#
# Features:
#   - Zsh integration: Ctrl+R (history search), Ctrl+T (file search)
#   - Optimized file search: ripgrep-based, excludes .git directories
#   - UI settings: 40% height, reverse layout, border display
#   - History search: Sorting enabled, exact matching mode
#
# VERSION: 4.0.0 (Mitchell-style migration)
# LAST UPDATED: 2025-10-25

{ ... }:

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
