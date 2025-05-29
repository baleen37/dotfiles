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
      # 호스트 정의 (직접 인라인)
      hosts = [
        { host = "baleen"; system = "aarch64-darwin"; extraModules = []; }
        { host = "jito"; system = "aarch64-darwin"; extraModules = []; }
        { host = "my-linux"; system = "x86_64-linux"; extraModules = []; }
      ];

      # 모듈 경로
      homeManagerModules = [
        ./programs/wezterm/default.nix
        ./programs/git/default.nix
        ./programs/tmux/default.nix
        ./programs/nvim/default.nix
        ./programs/vscode/default.nix
        ./programs/ssh/default.nix
        ./programs/act/default.nix
        ./programs/hammerspoon/default.nix
        ./programs/homerow/default.nix
      ];
      darwinOnlyModules = [
        home-manager.darwinModules.home-manager
        ./modules/darwin/configuration.nix
        ./modules/darwin/home.nix
      ];
      linuxOnlyModules = [
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
