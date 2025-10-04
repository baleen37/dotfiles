# Direnv Environment Management
#
# Direnv configuration with nix-direnv integration.
#
# VERSION: 3.1.0 (Extracted from productivity.nix)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, platformInfo
, userInfo
, ...
}:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config = {
      global = {
        load_dotenv = true;
      };
    };
  };
}
