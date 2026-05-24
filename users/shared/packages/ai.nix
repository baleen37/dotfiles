{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.ai;
in
{
  options.myHome.packages.ai.enable = lib.mkEnableOption "AI/CLI tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      claude-code
      opencode
      gemini-cli
    ];
  };
}
