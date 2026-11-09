{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.programs.syncthing;

  # Always-on hub outside Nix. Devices that are not Nix hosts (iPhone, Windows)
  # pair with it from its own web UI and reach the Macs through it, so they are
  # not listed here. Debian hosts read the same file in machines/debian/apply.py.
  inherit (lib.importJSON ../../../machines/syncthing.json) hub;

  # Includes this host's own ID: Syncthing treats it as the local device.
  devices = hub // cfg.peers;
in
{
  options.modules.programs.syncthing = {
    enable = lib.mkEnableOption "Syncthing sync of ~/wiki";

    # Set by flake-modules/systems.nix from the hosts' `syncthingId`s.
    peers = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Host name to Syncthing device ID, for every host with a syncthingId.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      # Devices and folders come only from here: anything added in the web UI
      # is removed on the next login or switch. Pair new non-Nix devices on the hub.
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = lib.mapAttrs (_: id: { inherit id; }) devices;
        folders.wiki = {
          path = "~/wiki";
          devices = builtins.attrNames devices;
          ignorePatterns = [
            # Obsidian workspace state is device-specific and changes often.
            "/.obsidian/workspace*.json"
            "/.obsidian_desktop/workspace*.json"
            "/.trash"
            ".DS_Store"
            # One machine keeps the git history through Obsidian Git; .git is
            # never synced so the other machines cannot commit over it.
            "/.git"
          ];
        };
      };
    };
  };
}
