{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.dev;
in
{
  options.modules.packages.dev.enable = lib.mkEnableOption "development tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nodejs_22
      bun
      python3
      python3Packages.pipx
      virtualenv
      uv
      direnv
      pre-commit
      vscode
      gnumake
      cmake
    ];
  };
}
