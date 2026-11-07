{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.ssh;
in
{
  options.modules.packages.ssh.enable = lib.mkEnableOption "SSH tools";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      mosh
      teleport
      sshpass
    ];
  };
}
