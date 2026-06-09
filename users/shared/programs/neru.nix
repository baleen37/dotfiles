# users/shared/programs/neru.nix
# Neru configuration (macOS keyboard navigation, Homerow alternative)
#
# Neru reads ~/.config/neru/config.toml and hot-reloads on change. The hints
# mode is bound to Hyper+F: Karabiner forwards right_command+F as the mega-chord
# cmd+ctrl+opt+shift+f (see karabiner.nix hyperLocal.f), which Neru picks up.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.neru;
in
{
  options.modules.programs.neru.enable = lib.mkEnableOption "Neru (macOS)" // {
    default = pkgs.stdenv.hostPlatform.isDarwin;
  };

  config = lib.mkIf cfg.enable {
    home.file.".config/neru/config.toml" = {
      source = ./.config/neru/config.toml;
      force = true;
    };
  };
}
