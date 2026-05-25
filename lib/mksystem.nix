{
  inputs,
  self,
  overlays ? [ ],
}:

name:
{
  system,
  user,
  darwin ? false,
  wsl ? false,
  homeModules ? { },
}:

let
  inherit (inputs.nixpkgs) lib;
  systemFunc = if darwin then inputs.darwin.lib.darwinSystem else lib.nixosSystem;

  # Use shared user configuration directory (users/shared)
  # Actual username is dynamically set via currentSystemUser
  userHMConfig = ../users/shared/home-manager.nix;
  userOSConfig = if darwin then ../users/shared/darwin else ../users/shared/nixos.nix;

  # darwin: 모든 호스트가 공유 common 모듈을 사용 (호스트별 차이는 hosts.nix에서 표현)
  # nixos: 호스트별 .nix 파일 유지
  machineConfig = if darwin then ../machines/darwin/common.nix else ../machines/nixos/${name}.nix;

  hmModule =
    if darwin then
      inputs.home-manager.darwinModules.home-manager
    else
      inputs.home-manager.nixosModules.home-manager;

  # Unified cache configuration for both Determinate Nix and traditional Nix
  cacheConfig = import ./cache-config.nix;
  cacheSettings = cacheConfig // {
    trusted-users = [
      "root"
      user
      "@admin"
      "@wheel"
    ];
  };

in
systemFunc {
  specialArgs = {
    inherit inputs self;
    currentSystem = system;
    currentSystemName = name;
    currentSystemUser = user;
    isWSL = wsl;
    isDarwin = darwin;
  };

  modules = [
    { nixpkgs.hostPlatform = system; }
    machineConfig
  ]
  ++ lib.optionals (builtins.pathExists userOSConfig) [
    userOSConfig
  ]
  ++ [

    # Nix configuration
    (
      { lib, ... }:
      {
        # Traditional Nix settings (Linux systems)
        nix.settings = lib.mkIf (!darwin) (
          cacheSettings
          // {
            trusted-substituters = cacheSettings.substituters;
          }
        );

        # Let Determinate manage Nix on Darwin systems
        nix.enable = lib.mkIf darwin false;
      }
    )
  ]
  ++ lib.optionals darwin [
    # Determinate Nix integration (Darwin systems only)
    inputs.determinate.darwinModules.default
    { determinateNix.customSettings = cacheSettings; }
  ]
  ++ [
    # Home Manager integration
    hmModule
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user} = lib.mkMerge [
          (import userHMConfig)
          homeModules
        ];
        extraSpecialArgs = {
          inherit inputs self;
          currentSystemUser = user;
          isDarwin = darwin;
        };
      };

      # Set required home-manager options
      users.users.${user} = {
        name = user;
        home = if darwin then "/Users/${user}" else "/home/${user}";
      }
      // lib.optionalAttrs (!darwin) {
        isNormalUser = true;
      };

      # Set hostname for Darwin systems
      networking.hostName = lib.mkIf darwin name;

      # Apply overlays
      nixpkgs.overlays = overlays;
    }
  ];
}
