# SSH client configuration
#
# SSH connection optimization and security settings
#
# Features:
#   - External SSH config file integration (~/.ssh/config_external)
#   - SSH key agent auto-registration (1Password support)
#   - Connection keep-alive settings (ServerAlive 60s interval, max 3 retries)
#   - TCP KeepAlive for network stability improvement
#   - identitiesOnly=true for key selection optimization
#
# VERSION: 4.0.0 (Mitchell-style migration)
# LAST UPDATED: 2025-10-25

{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "$HOME/.ssh/config_external"
    ];
    matchBlocks = {
      "*" = {
        identitiesOnly = true;
        addKeysToAgent = "yes";
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        extraOptions = {
          TCPKeepAlive = "yes";
        };
      };
    };
  };
}
