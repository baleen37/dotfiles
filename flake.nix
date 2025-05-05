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

  outputs = {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }@inputs:
    let
      # dev-shell = import ./libraries/dev-shell { inherit inputs; };
      home-manager-shared = ./libraries/home-manager;
      nixpkgs-shared = ./libraries/nixpkgs;

    in
    {
      darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          # home-manager-shared
          # nixpkgs-shared
          home-manager.darwinModules.home-manager
          # ./modules/shared/configuration.nix
          # ./modules/darwin/configuration.nix
          # ./modules/darwin/home.nix
        ];
        specialArgs = { inherit inputs; };
      };

      # nixosConfigurations.linux = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     home-manager.nixosModules.home-manager
      #   ];
      #   specialArgs = { inherit inputs; };
      # };
    };
}
