{ lib, ... }:
let
  hostType = lib.types.submodule {
    options = {
      system = lib.mkOption {
        type = lib.types.enum [
          "aarch64-darwin"
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
      class = lib.mkOption {
        type = lib.types.enum [
          "darwin"
          "nixos"
        ];
      };
      user = lib.mkOption {
        type = lib.types.strMatching "[^[:space:]].*";
      };
      homeModules = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
        default = { };
      };
      machineModules = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
      };
      # Syncthing device ID (public, not a secret); `make syncthing-id` writes
      # it. Every Mac runs Syncthing and peers with each host that has one;
      # see users/shared/programs/syncthing.nix.
      syncthingId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };
  };
in
{
  options.dotfiles.hosts = lib.mkOption {
    type = lib.types.attrsOf hostType;
    default = { };
  };

  config.dotfiles.hosts = {
    macbook-pro = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "baleen";
      machineModules = [ ../machines/darwin/macbook-pro.nix ];
    };
    baleen-macbook = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "baleen";
      machineModules = [ ../machines/darwin/baleen-macbook.nix ];
    };
    baleen-m2-pro = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "baleen";
      syncthingId = "GRWLSDU-LQVUNLV-C6YZATS-6MCXPTI-OAJW77W-CYGVSCE-XAA2MB3-F335OAW";
      machineModules = [ ../machines/darwin/macbook-pro.nix ];
    };
    kakaostyle-jito = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "jito.hello";
      syncthingId = "FAMY2R3-2T2E6RX-UU5H37L-ZGQ5NNV-YG367MA-2VF5G4U-VFHYL4C-USPF3Q6";
      machineModules = [ ../machines/darwin/kakaostyle-jito.nix ];
    };
  };
}
