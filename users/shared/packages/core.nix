{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.core;
in
{
  options.myHome.packages.core.enable = lib.mkEnableOption "core utilities" // {
    default = true;
  };

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
