# Productivity Tools Configuration
#
# Direnv and fzf configurations for enhanced development productivity.
# Extracted from programs.nix following single responsibility principle.
#
# FEATURES:
#   - Direnv with nix-direnv integration
#   - Fzf with optimized file finding and history
#   - Zsh integration for both tools
#
# ARCHITECTURE:
#   - Single responsibility: Only productivity tool configurations
#   - Cross-platform: macOS and Linux compatibility
#   - Performance optimized: Efficient search and environment management
#
# VERSION: 3.0.0 (Extracted from programs.nix)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, platformInfo
, userInfo
, ...
}:

let
  inherit (platformInfo) isDarwin isLinux;
  inherit (userInfo) name email;
in
{
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      config = {
        global = {
          load_dotenv = true;
        };
      };
    };

    fzf = {
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
  };
}
