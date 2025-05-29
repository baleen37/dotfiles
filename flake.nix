{
  description = "Home Manager configuration of baleen";

  # --- Inputs ---
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

  # --- Outputs ---
  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs:
    let
      # 호스트 정의
      hosts = [
        (import ./hosts/baleen.nix)
        (import ./hosts/jito.nix)
        (import ./hosts/my-linux.nix)
      ];

      # 모듈 경로
      nixpkgsShared = ./libraries/nixpkgs;
      homeManagerModules = [
        ./modules/shared/programs/wezterm
        ./modules/shared/programs/git
        ./modules/shared/programs/tmux
        ./modules/shared/programs/nvim
        ./modules/shared/programs/vscode
        ./modules/shared/programs/ssh
        ./modules/shared/programs/act
        ./libraries/home-manager/programs/hammerspoon
        ./libraries/home-manager/programs/homerow
      ];
      darwinOnlyModules = [
        nixpkgsShared
        home-manager.darwinModules.home-manager
        ./modules/darwin/configuration.nix
        ./modules/darwin/home.nix
      ];
      linuxOnlyModules = [
        nixpkgsShared
        ./modules/shared/home-linux.nix
      ];

      # 시스템별 모듈 조합
      getModules = system: extraModules:
        if nixpkgs.lib.strings.hasInfix "darwin" system
        then darwinOnlyModules ++ extraModules
        else linuxOnlyModules ++ extraModules;

      # Home Manager config 생성
      mkHomeConfig = { system, modules }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; };
          modules = modules;
          extraSpecialArgs = { inherit inputs; };
        };

      # Darwin config 생성
      mkDarwinConfig = { name, system, modules }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          modules = modules;
          specialArgs = { inherit inputs; hostName = name; };
        };

      # 시스템별 attr 생성
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux"
      ];

      # 호스트 필터링
      filterHosts = pred: map (h: h.host) (builtins.filter pred hosts);
      getHostCfg = hostName: hostList:
        builtins.head (builtins.filter (h: h.host == hostName) hostList);

    in {
      # macOS용 nix-darwin 설정
      darwinConfigurations = nixpkgs.lib.genAttrs
        (filterHosts (h: nixpkgs.lib.strings.hasInfix "darwin" h.system))
        (hostName:
          let
            cfg = getHostCfg hostName hosts;
            modules = getModules cfg.system cfg.extraModules;
          in
            mkDarwinConfig { name = cfg.host; system = cfg.system; modules = modules; }
        );

      # 시스템별 default 패키지
      packages = forAllSystems (system: {
        default =
          if nixpkgs.lib.strings.hasInfix "darwin" system
          then self.darwinConfigurations.baleen.system
          else nixpkgs.legacyPackages.${system}.hello;
      });

      # Linux용 Home Manager 설정
      homeConfigurations = nixpkgs.lib.genAttrs
        (filterHosts (h: nixpkgs.lib.strings.hasInfix "linux" h.system))
        (hostName:
          let
            cfg = getHostCfg hostName hosts;
            modules = homeManagerModules ++ linuxOnlyModules ++ cfg.extraModules;
          in
            mkHomeConfig { system = cfg.system; modules = modules; }
        );
    };
}
