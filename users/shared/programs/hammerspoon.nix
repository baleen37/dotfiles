# users/shared/hammerspoon.nix
# Hammerspoon configuration

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.hammerspoon;
in
{
  options.modules.programs.hammerspoon.enable = lib.mkEnableOption "Hammerspoon (macOS)" // {
    default = pkgs.stdenv.hostPlatform.isDarwin;
  };

  config = lib.mkIf cfg.enable {
    # Pattern: Tool-specific home directory (destination: ~/.hammerspoon/)
    # Hammerspoon requires configuration in ~/.hammerspoon/ (non-XDG)
    # Source organized in .config/ for consistency, symlinked to custom location
    home.file.".hammerspoon" = {
      source = ./.config/hammerspoon;
      recursive = true;
      force = true;
    };
  };
}
