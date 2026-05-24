{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.lsp;
in
{
  options.myHome.packages.lsp.enable = lib.mkEnableOption "LSP servers" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      lua-language-server
      gopls
      go
      typescript-language-server
      pyright
    ];
  };
}
