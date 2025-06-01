{ inputs, ... }:
let
  mkDarwinConfig = host: system: inputs.nix-darwin.lib.darwinSystem {
    inherit system;
    modules = [
      inputs.home-manager.darwinModules.home-manager
      ../../hosts/${host}/configuration.nix
      { home-manager.users.${host} = import ../../hosts/${host}/home.nix; }
    ];
    specialArgs = { inherit inputs; };
  };
in {
  baleen = mkDarwinConfig "baleen" "aarch64-darwin";
  jito = mkDarwinConfig "jito" "aarch64-darwin";
}
