{ inputs, ... }:
let
  mkHomeConfig = system: inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs { inherit system; };
    modules = [ ../../home-linux.nix ];
    extraSpecialArgs = { inherit inputs; };
  };
  systems = [ "x86_64-linux" "aarch64-linux" ];
in inputs.nixpkgs.lib.genAttrs systems mkHomeConfig
