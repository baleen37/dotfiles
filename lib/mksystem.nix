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
}:

let
  inherit (inputs.nixpkgs) lib;
  systemFunc = if darwin then inputs.darwin.lib.darwinSystem else lib.nixosSystem;

  osConfig = if darwin then "darwin.nix" else "nixos.nix";

  # Use shared user configuration directory (users/shared)
  # Actual username is dynamically set via currentSystemUser
  userHMConfig = ../users/shared/home-manager.nix;
  userOSConfig = ../users/shared/${osConfig};
  machineConfig = if darwin then ../machines/${name}.nix else ../machines/nixos/${name}.nix;

  hmModule = if darwin then inputs.home-manager.darwinModules.home-manager else inputs.home-manager.nixosModules.home-manager;

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
        nix.settings = lib.mkIf (!darwin) (cacheSettings // {
          trusted-substituters = cacheSettings.substituters;
        });

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
        users.${user} = import userHMConfig;
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
      } // lib.optionalAttrs (!darwin) {
        isNormalUser = true;
      };

      # Set hostname for Darwin systems
      networking.hostName = lib.mkIf darwin name;

      # Apply overlays
      nixpkgs.overlays = overlays;
    }
  ];
}
