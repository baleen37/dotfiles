# SSH client configuration
#
# Manages ~/.ssh/config via home-manager so connection keepalive applies
# uniformly to every host (including invocations through Ghostty's
# ssh-env wrapper). The OrbStack include is preserved at the top.

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
      enableDefaultConfig = false;
      includes = [ "~/.orbstack/ssh/config" ];
      settings = {
        "*" = {
          AddKeysToAgent = "no";
          Compression = false;
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
          ForwardAgent = false;
          HashKnownHosts = false;
          # 15s x 20 = 5min. The previous 60s x 3 gave only 3 minutes, which a
          # quiet long-running remote job (no output until completion) could
          # not outlast once a NAT/firewall dropped the idle connection.
          ServerAliveCountMax = 20;
          ServerAliveInterval = 15;
          TCPKeepAlive = "yes";
          UserKnownHostsFile = "~/.ssh/known_hosts";
        };
        "github.com" = {
          HostName = "github.com";
          IdentitiesOnly = true;
          IdentityFile = "~/.ssh/id_ed25519_github";
          StrictHostKeyChecking = "no";
          User = "git";
        };
      };
    };
  };
}
