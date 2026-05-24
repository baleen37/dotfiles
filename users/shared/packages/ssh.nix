{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHome.packages.ssh;
in
{
  options.myHome.packages.ssh.enable = lib.mkEnableOption "SSH tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      mosh
      teleport
      sshpass
    ];
  };
}
