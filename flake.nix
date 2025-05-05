{
  description = "My Home Manager flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { nixpkgs, home-manager, ... }:
  let
    system = "aarch64-darwin";
  in {
    packages.${system}.default = home-manager.defaultPackage.${system};

    homeConfigurations."baleen" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      modules = [ 
        ./home.nix
        {
          home = {
            username = "baleen";
            homeDirectory = "/Users/baleen";
          };
        }
      ];
    };
  };
}