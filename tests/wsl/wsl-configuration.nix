# tests/wsl/wsl-configuration.nix
{ inputs, system, pkgs, lib, ... }:

let
  helpers = import ../../lib/enhanced-assertions.nix { inherit pkgs lib; };
in
helpers.testSuite "wsl-configuration" [
  (helpers.assertTestWithDetails "wsl-system-builds"
    (builtins.isAttrs inputs.self.nixosConfigurations.wsl)
    "WSL system configuration should be defined and buildable"
    "WSL configuration object"
    (builtins.typeOf inputs.self.nixosConfigurations.wsl)
  )

  (helpers.assertTestWithDetails "wsl-home-manager-available"
    (builtins.isAttrs inputs.self.homeConfigurations.nixos)
    "Home Manager configuration for WSL user should be available"
    "WSL home configuration object"
    (builtins.typeOf inputs.self.homeConfigurations.nixos)
  )

  (helpers.assertTestWithDetails "wsl-has-flag"
    inputs.self.nixosConfigurations.wsl.specialArgs.isWSL
    "WSL configuration should have isWSL flag set to true"
    true
    inputs.self.nixosConfigurations.wsl.specialArgs.isWSL
  )
]