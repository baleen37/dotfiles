{
  description = "Home Manager configuration of baleen";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    overlays = {
      default = import ./overlays;
    };

    packages.aarch64-darwin = let
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
      };
    in {
      hammerspoon = pkgs.callPackage ./modules/nix/packages/hammerspoon {};
      homerow = pkgs.callPackage ./modules/nix/packages/homerow {};
    };

    darwinConfigurations = {
      baleen = inputs.nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/darwin/baleen/configuration.nix
        ];
      };
      jito = inputs.nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/darwin/jito/configuration.nix
        ];
      };
    };

    apps = {
      x86_64-darwin = import ./apps/darwin { pkgs = nixpkgs.legacyPackages.x86_64-darwin; };
      aarch64-darwin = import ./apps/darwin { pkgs = nixpkgs.legacyPackages.aarch64-darwin; };
      x86_64-linux = import ./apps/linux { pkgs = nixpkgs.legacyPackages.x86_64-linux; };
      aarch64-linux = import ./apps/linux { pkgs = nixpkgs.legacyPackages.aarch64-linux; };
    };
  };
}
