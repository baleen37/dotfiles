{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.ai;
in
{
  options.modules.packages.ai.enable = lib.mkEnableOption "AI/CLI tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      claude-code
      opencode
      gemini-cli
    ];
  };
}
