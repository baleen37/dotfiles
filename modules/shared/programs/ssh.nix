# SSH Configuration
#
# SSH configuration with 1Password integration and connection optimization.
#
# VERSION: 3.1.0 (Extracted from development.nix)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, platformInfo
, userInfo
, ...
}:

let
  inherit (userInfo) paths;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "${paths.ssh}/config_external"
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
