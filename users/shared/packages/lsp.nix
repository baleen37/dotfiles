{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.lsp;
in
{
  options.modules.packages.lsp.enable = lib.mkEnableOption "LSP servers";

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
