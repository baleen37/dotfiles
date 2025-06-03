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

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
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

    homeConfigurations = {
      baleen = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          ./hosts/darwin/baleen/home.nix
        ];
        username = "baleen";
        homeDirectory = "/Users/baleen";
      };
      jito = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          ./hosts/darwin/jito/home.nix
        ];
        username = "jito";
        homeDirectory = "/Users/jito";
      };
    };

    apps = {
      x86_64-darwin = import ./apps/darwin { pkgs = nixpkgs.legacyPackages.x86_64-darwin; };
      aarch64-darwin = import ./apps/darwin { pkgs = nixpkgs.legacyPackages.aarch64-darwin; };
      x86_64-linux = import ./apps/linux { pkgs = nixpkgs.legacyPackages.x86_64-linux; };
      aarch64-linux = import ./apps/linux { pkgs = nixpkgs.legacyPackages.aarch64-linux; };
    };

    checks = {
      aarch64-darwin = let
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
      in {
        home-baleen = pkgs.runCommand "home-baleen-smoke" { } ''
          ${pkgs.nix}/bin/nix --extra-experimental-features nix-command build /Users/baleen/dotfiles#homeConfigurations.baleen.activationPackage --dry-run
          touch $out
        '';
        home-jito = pkgs.runCommand "home-jito-smoke" { } ''
          ${pkgs.nix}/bin/nix --extra-experimental-features nix-command build /Users/baleen/dotfiles#homeConfigurations.jito.activationPackage --dry-run
          touch $out
        '';
        darwin-baleen = pkgs.runCommand "darwin-baleen-smoke" { } ''
          ${pkgs.nix}/bin/nix --extra-experimental-features nix-command build /Users/baleen/dotfiles#darwinConfigurations.baleen.system --dry-run
          touch $out
        '';
        darwin-jito = pkgs.runCommand "darwin-jito-smoke" { } ''
          ${pkgs.nix}/bin/nix --extra-experimental-features nix-command build /Users/baleen/dotfiles#darwinConfigurations.jito.system --dry-run
          touch $out
        '';
      };
    };
  };
}
