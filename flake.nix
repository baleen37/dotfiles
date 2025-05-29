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

      # Helper function to provide system-specific default packages
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      # 시스템별 Home Manager 환경을 추상화해서 생성하는 함수
      mkHomeConfig = system: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        modules = [ home-manager-shared nixpkgs-shared ];
        extraSpecialArgs = { inherit inputs; };
      };
      linuxSystems = ["x86_64-linux" "aarch64-linux"];
    in
    {
      darwinConfigurations.baleen = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          home-manager-shared
          nixpkgs-shared
          home-manager.darwinModules.home-manager
          # ./modules/shared/configuration.nix
          ./modules/darwin/configuration.nix
          ./modules/darwin/home.nix
        ];
        specialArgs = { inherit inputs; hostName = "baleen"; };
      };

      darwinConfigurations.jito = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin"; # jito 머신이 Intel Mac인 경우 "x86_64-darwin"으로 변경해야 할 수 있습니다.
        modules = [
          home-manager-shared
          nixpkgs-shared
          home-manager.darwinModules.home-manager
          # ./modules/shared/configuration.nix
          ./modules/darwin/configuration.nix
          ./modules/darwin/home.nix
        ];
        specialArgs = { inherit inputs; hostName = "jito"; };
      };

      # nixosConfigurations.linux = nixpkgs.lib.nixosSystem {
      #   system = "x86_64-linux";
      #   modules = [
      #     home-manager.nixosModules.home-manager
      #     nixpkgs-shared
      #     ({ config, ... }: {
      #       fileSystems."/" = {
      #         device = "/dev/disk/by-label/nixos";
      #         fsType = "ext4";
      #       };
      #       boot.loader.grub.devices = [ "/dev/vda" ];
      #     })
      #   ];
      #   specialArgs = { inherit inputs; };
      # };

      # System-specific default packages
      packages = forAllSystems (system: {
        default =
          if nixpkgs.lib.strings.hasInfix "darwin" system
          then self.darwinConfigurations.baleen.system # 이전 darwin에서 baleen으로 변경
          else nixpkgs.legacyPackages.${system}.hello; # Fallback for non-Darwin systems
      });

      homeConfigurations = nixpkgs.lib.genAttrs linuxSystems mkHomeConfig;
    };
}
