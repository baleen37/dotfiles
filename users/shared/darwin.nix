# Shared macOS system policy; desktop preferences are selected by machines.
{ inputs, currentSystemUser, ... }:
{
  imports = [ inputs.determinate.darwinModules.default ];

  determinateNix = {
    customSettings = (import ../../lib/cache-config.nix) // {
      trusted-users = [
        "root"
        currentSystemUser
      ];
    };
    determinateNixd.garbageCollector.strategy = "automatic";
  };
}
