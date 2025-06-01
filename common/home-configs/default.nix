{ inputs, ... }:
let
  overlays = (import ../nix/packages { inherit inputs; }).default;
  mkHomeConfig = system: inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs { inherit system overlays; };
    modules = [ ../../home-linux.nix ];
    extraSpecialArgs = { inherit inputs; };
  };
  systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
in inputs.nixpkgs.lib.genAttrs systems mkHomeConfig
