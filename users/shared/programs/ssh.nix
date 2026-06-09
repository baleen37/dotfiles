# SSH client configuration
#
# Manages ~/.ssh/config via home-manager so connection keepalive applies
# uniformly to every host (including invocations through Ghostty's
# ssh-terminfo wrapper). The OrbStack include is preserved at the top.

{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.programs.ssh;
in
{
  options.modules.programs.ssh.enable = lib.mkEnableOption "SSH client config";

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      includes = [ "~/.orbstack/ssh/config" ];
      matchBlocks = {
        "*" = {
          serverAliveInterval = 60;
          serverAliveCountMax = 3;
          extraOptions = {
            TCPKeepAlive = "yes";
          };
        };
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_ed25519_github";
          identitiesOnly = true;
          extraOptions = {
            StrictHostKeyChecking = "no";
          };
        };
      };
    };
  };
}
