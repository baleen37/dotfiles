{ inputs, ... }:
let
  overlays = (import ../nix/packages { inherit inputs; }).default;
  mkHomeConfig = system: inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs { inherit system overlays; };
    modules = [
      (if system == "x86_64-linux" then ../../hosts/jito/home.nix
       else if system == "aarch64-darwin" then ../../hosts/baleen/home.nix
       else throw "Unsupported system: ${system}")
    ];
    extraSpecialArgs = { inherit inputs; };
  };
  systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
in inputs.nixpkgs.lib.genAttrs systems mkHomeConfig
