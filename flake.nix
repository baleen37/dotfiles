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
      hammerspoon = pkgs.callPackage ./modules/nix/packages/hammerspoon {};
      homerow = pkgs.callPackage ./modules/nix/packages/homerow {};
    };

    homeConfigurations = import ./common/home-configs { inherit inputs; };
    darwinConfigurations = import ./common/darwin-configs { inherit inputs; };
    nixosModules = import ./common/nixos-modules { inherit inputs; };
    checks = import ./common/checks { inherit inputs; };

    hosts = {
      darwin = {
        baleen = import ./hosts/darwin/baleen;
        jito = import ./hosts/darwin/jito;
      };
      # linux = { ... } # 필요시 추가
    };

    apps = {
      x86_64-darwin = import ./apps/darwin;
      aarch64-darwin = import ./apps/darwin;
      x86_64-linux = import ./apps/linux;
      aarch64-linux = import ./apps/linux;
    };
  };
}
