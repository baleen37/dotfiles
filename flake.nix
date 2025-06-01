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
      home-manager-shared = ./common/modules/user-env/default.nix;
      nixpkgs-shared = ./common/nix/packages/default.nix;
      # Helper function to provide system-specific default packages
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      # 시스템별 Home Manager 환경을 추상화해서 생성하는 함수
      mkHomeConfig = system:
        if nixpkgs.lib.strings.hasInfix "linux" system then
          home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs { inherit system; };
            modules = [ ./common/home-linux.nix nixpkgs-shared ];
            extraSpecialArgs = { inherit inputs; };
          }
        else
          home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs { inherit system; };
            modules = [ nixpkgs-shared { home.stateVersion = "25.05"; } ];
            extraSpecialArgs = { inherit inputs; };
          };
      linuxSystems = ["x86_64-linux" "aarch64-linux"];
      macosSystems = ["aarch64-darwin" "x86_64-darwin"];
      # darwinConfigurations 중복 제거 함수
      mkDarwinConfig = hostName: system: nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          home-manager.darwinModules.home-manager
          nixpkgs-shared
          ./hosts/baleen/configuration.nix
          {
            home-manager.users.baleen = import ./hosts/baleen/home.nix;
          }
        ];
        specialArgs = { inherit inputs hostName; };
      };
      # nixos 프로그램 테스트 모듈 자동 로딩 함수
      nixosProgramTests = system: let
        programsDir = ./hosts/jito/programs;
        nixosProgramNames = builtins.filter
          (name: builtins.pathExists (programsDir + "/${name}/test.nix"))
          (builtins.attrNames (builtins.readDir programsDir));
      in
        builtins.listToAttrs (
          map
            (name: {
              inherit name;
              value = import (programsDir + "/${name}/test.nix") nixpkgs;
            })
            nixosProgramNames
        );
    in
    {
      darwinConfigurations = {
        baleen = mkDarwinConfig "baleen" "aarch64-darwin";
        jito = mkDarwinConfig "jito" "aarch64-darwin"; # Intel Mac이면 "x86_64-darwin"으로 변경
      };
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in {
          default =
            if nixpkgs.lib.strings.hasInfix "darwin" system then
              self.darwinConfigurations.baleen.system
            else if nixpkgs.lib.strings.hasInfix "linux" system && self ? homeConfigurations && self.homeConfigurations ? ${system}
            then self.homeConfigurations.${system}.activationPackage or nixpkgs.legacyPackages.${system}.hello
            else nixpkgs.legacyPackages.${system}.hello;
          hammerspoon = pkgs.callPackage ./common/nix/packages/hammerspoon {};
          homerow = pkgs.callPackage ./common/nix/packages/homerow {};
        });
      homeConfigurations = nixpkgs.lib.genAttrs (linuxSystems ++ macosSystems) mkHomeConfig;
      nixosModules = {
        homerow = ./hosts/jito/programs/homerow/default.nix;
      };
      checks = {
        x86_64-linux = nixosProgramTests "x86_64-linux" // {
          build-homerow = self.packages.x86_64-linux.homerow;
        };
        aarch64-linux = nixosProgramTests "aarch64-linux" // {
          build-homerow = self.packages.aarch64-linux.homerow;
        };
        aarch64-darwin = {
          build-homerow = self.packages.aarch64-darwin.homerow;
          build-hammerspoon = self.packages.aarch64-darwin.hammerspoon;
        };
        x86_64-darwin = {
          build-homerow = self.packages.x86_64-darwin.homerow;
          build-hammerspoon = self.packages.x86_64-darwin.hammerspoon;
        };
      };
    };
}
