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
    packages.aarch64-darwin = let
      overlays = (import ./common/nix/packages { inherit inputs; }).default;
      pkgs = import nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; inherit overlays; };
    in {
      hammerspoon = pkgs.callPackage ./common/nix/packages/hammerspoon {};
      homerow = pkgs.callPackage ./common/nix/packages/homerow {};
    };

    homeConfigurations = import ./common/home-configs { inherit inputs; };
    darwinConfigurations = import ./common/darwin-configs { inherit inputs; };
    nixosModules = import ./common/nixos-modules { inherit inputs; };
    checks = import ./common/checks { inherit inputs; };
  };
}
