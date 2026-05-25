{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.core;
in
{
  options.modules.packages.core.enable = lib.mkEnableOption "core utilities";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wget
      curl
      zip
      unzip
      tree
      htop
      jq
      ripgrep
      fd
      bat
      eza
      fzf
    ];
  };
}
