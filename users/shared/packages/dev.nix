{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.dev;
in
{
  options.myHome.packages.dev.enable = lib.mkEnableOption "development tools" // {
    default = true;
  };

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
