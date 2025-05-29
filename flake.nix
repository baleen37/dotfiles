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
      homeManagerShared = ./libraries/home-manager;
      nixpkgsShared = ./libraries/nixpkgs;
      linuxSystems = ["x86_64-linux" "aarch64-linux"];
      darwinSystems = [
        { name = "baleen"; system = "aarch64-darwin"; }
        { name = "jito";   system = "aarch64-darwin"; } # 필요시 "x86_64-darwin"으로 변경
      ];
      darwinModules = [
        homeManagerShared
        nixpkgsShared
        home-manager.darwinModules.home-manager
        ./modules/darwin/configuration.nix
        ./modules/darwin/home.nix
      ];
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      mkHomeConfig = system: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        modules = [ homeManagerShared nixpkgsShared ];
        extraSpecialArgs = { inherit inputs; };
      };
      mkDarwinConfig = { name, system }: nix-darwin.lib.darwinSystem {
        inherit system;
        modules = darwinModules;
        specialArgs = { inherit inputs; hostName = name; };
      };
    in
    {
      darwinConfigurations = nixpkgs.lib.genAttrs (map (x: x.name) darwinSystems)
        (name: let cfg = builtins.head (builtins.filter (x: x.name == name) darwinSystems); in mkDarwinConfig cfg);

      # System-specific default packages
      packages = forAllSystems (system: {
        default =
          if nixpkgs.lib.strings.hasInfix "darwin" system
          then self.darwinConfigurations.baleen.system
          else nixpkgs.legacyPackages.${system}.hello;
      });

      homeConfigurations = nixpkgs.lib.genAttrs linuxSystems mkHomeConfig;
    };
}
