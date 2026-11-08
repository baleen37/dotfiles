# tests/integration/syncthing-test.nix
#
# Every Mac runs Syncthing and knows every host that declares a `syncthingId`
# in flake-modules/hosts.nix as a peer. The wiring goes hosts.nix ->
# systems.nix -> the Home Manager module, so a break anywhere only shows up as
# a Mac that silently stops syncing ~/wiki.
{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  hosts = import ../lib/hosts.nix { inherit lib; };

  outputs = inputs.self.darwinConfigurations // inputs.self.nixosConfigurations;

  syncthingOf =
    name: outputs.${name}.config.home-manager.users.${hosts.${name}.user}.services.syncthing;

  hostsOf = class: builtins.attrNames (lib.filterAttrs (_: h: h.class == class) hosts);
  macs = hostsOf "darwin";

  ids = lib.filter (id: id != null) (lib.mapAttrsToList (_: h: h.syncthingId) hosts);
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "syncthing" [
    (helpers.assertTest "macs-run-syncthing" (lib.all (
      name: (syncthingOf name).enable
    ) macs) "every Darwin host must enable services.syncthing")

    (helpers.assertTest "nixos-hosts-do-not" (lib.all (name: !(syncthingOf name).enable) (
      hostsOf "nixos"
    )) "NixOS hosts must not run Syncthing")

    (helpers.assertTest "macs-know-every-host-id" (
      ids != [ ]
      && lib.all (
        name:
        let
          known = map (d: d.id) (lib.attrValues (syncthingOf name).settings.devices);
        in
        lib.all (id: lib.elem id known) ids
      ) macs
    ) "every Mac must list every syncthingId from hosts.nix as a device")

    # The folder ID must match the one the hub and phones already use, and
    # .git must stay local: only one machine commits the vault through Obsidian Git.
    (helpers.assertTest "wiki-folder-matches-existing-share" (lib.all (
      name:
      let
        wiki = (syncthingOf name).settings.folders.wiki;
      in
      wiki.id == "wiki" && wiki.path == "~/wiki" && lib.elem "/.git" wiki.ignorePatterns
    ) macs) "~/wiki must be shared as folder id 'wiki' with .git ignored")
  ];
}
