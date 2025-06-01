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

  outputs = { self, ... }@inputs: {
    overlays = import ./common/nix/packages { inherit inputs; };
    homeConfigurations = import ./common/home-configs { inherit inputs; };
    darwinConfigurations = import ./common/darwin-configs { inherit inputs; };
    nixosModules = import ./common/nixos-modules { inherit inputs; };
    checks = import ./common/checks { inherit inputs; };
  };
}
