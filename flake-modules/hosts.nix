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
      machineModules = [ ../machines/darwin/common.nix ];
    };
    baleen-macbook = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "baleen";
      machineModules = [ ../machines/darwin/common.nix ];
    };
    kakaostyle-jito = {
      system = "aarch64-darwin";
      class = "darwin";
      user = "jito.hello";
      machineModules = [ ../machines/darwin/common.nix ];
    };
    vm-aarch64-utm = {
      system = "aarch64-linux";
      class = "nixos";
      user = "baleen";
      machineModules = [ ../machines/nixos/vm-aarch64-utm.nix ];
    };
    vm-x86_64-utm = {
      system = "x86_64-linux";
      class = "nixos";
      user = "baleen";
      machineModules = [ ../machines/nixos/vm-x86_64-utm.nix ];
    };
  };
}
