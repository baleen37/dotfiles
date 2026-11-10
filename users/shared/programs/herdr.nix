{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.herdr;

  # The Herdr app's herdr-sim mods (Changes panel, PR icons) run `herdr-sim`
  # from PATH, so the pinned build goes on PATH here.
  herdrSimPackage = inputs.herdr-sim.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # On macOS this also gates the herdr-app cask (machines/darwin/*.nix).
  options.modules.programs.herdr.enable = lib.mkEnableOption "Herdr desktop app support";

  config = lib.mkIf cfg.enable {
    home.packages = [ herdrSimPackage ];
  };
}
