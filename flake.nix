{
  description = "Home Manager configuration of baleen";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in {
      homeConfigurations."baleen" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # 모듈 경로를 올바르게 참조하기 위해 self 사용
        modules = [
          (import ./modules/darwin/home.nix)
        ];

        # Pass extra parameters to home modules
        extraSpecialArgs = {
          # Add any special arguments you want to pass to your modules here
        };
      };
    };
}
