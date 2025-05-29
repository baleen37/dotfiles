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
      home-manager-shared = ./libraries/home-manager;
      nixpkgs-shared = ./libraries/nixpkgs;
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
            modules = [ ./modules/shared/home-linux.nix nixpkgs-shared ];
            extraSpecialArgs = { inherit inputs; };
          }
        else
          home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs { inherit system; };
            modules = [ home-manager-shared nixpkgs-shared { home.stateVersion = "25.05"; } ];
            extraSpecialArgs = { inherit inputs; };
          };
      linuxSystems = ["x86_64-linux" "aarch64-linux"];
      macosSystems = ["aarch64-darwin" "x86_64-darwin"];
      # darwinConfigurations 중복 제거 함수
      mkDarwinConfig = hostName: system: nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          home-manager-shared
          nixpkgs-shared
          home-manager.darwinModules.home-manager
          ./modules/darwin/configuration.nix
          ./modules/darwin/home.nix
        ];
        specialArgs = { inherit inputs hostName; };
      };
      # homerow 테스트 중복 제거 함수
      mkHomerowTest = system: (import "${nixpkgs}/nixos/tests/make-test-python.nix") {
        name = "homerow-basic";
        nodes.machine = { pkgs, ... }: {
          imports = [ self.nixosModules.homerow ];
          services.homerow.enable = true;
        };
        testScript = ''
          machine.start()
          machine.wait_for_unit("multi-user.target")
          machine.succeed("pgrep Homerow")
        '';
      }.driver;
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
          hammerspoon = pkgs.callPackage ./libraries/nixpkgs/programs/hammerspoon {};
          homerow = pkgs.callPackage ./libraries/nixpkgs/programs/homerow {};
        });
      homeConfigurations = nixpkgs.lib.genAttrs (linuxSystems ++ macosSystems) mkHomeConfig;
      nixosModules = {
        homerow = ./modules/nixos/programs/homerow/default.nix;
      };
      checks = {
        x86_64-linux = { homerow = mkHomerowTest "x86_64-linux"; };
        aarch64-linux = { homerow = mkHomerowTest "aarch64-linux"; };
      };
    };
}
