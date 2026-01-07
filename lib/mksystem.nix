{ inputs, self, overlays ? [] }:

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
  machineConfig = ../machines/${name}.nix;

  # Unified cache configuration for both Determinate Nix and traditional Nix
  cacheSettings = {
    substituters = [
      "https://baleen-nix.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    trusted-users = [
      "root"
      user
      "@admin"
      "@wheel"
    ];
  };

in
systemFunc {
  inherit system;

  specialArgs = {
    inherit inputs self;
    currentSystem = system;
    currentSystemName = name;
    currentSystemUser = user;
    isWSL = wsl;
    isDarwin = darwin;
  };

  modules = [
    machineConfig
    userOSConfig

    # Conditional Nix configuration for Determinate vs traditional setups
    (
      { lib, ... }:
      {
        # Traditional Nix settings (Linux systems)
        nix.settings = lib.mkIf (!darwin) cacheSettings // {
          # Trust substituters to eliminate "ignoring untrusted substituter" warnings
          trusted-substituters = cacheSettings.substituters;
        };

        # Determinate Nix integration
        determinate-nix.customSettings = cacheSettings;

        # Let Determinate manage Nix on Darwin systems
        nix.enable = lib.mkIf darwin false;
      }
    )
  ]
  ++ lib.optionals darwin [
    # Determinate Nix integration (Darwin systems only)
    inputs.determinate.darwinModules.default
  ] ++ [
    # Home Manager integration
    inputs.home-manager.darwinModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user} = import userHMConfig;
        extraSpecialArgs = {
          inherit inputs self;
          currentSystemUser = user;
        };
      };

      # Set required home-manager options
      users.users.${user} = {
        name = user;
        home = if darwin then "/Users/${user}" else "/home/${user}";
      };

      # Set hostname for Darwin systems
      networking.hostName = lib.mkIf darwin name;

      # Apply overlays
      nixpkgs.overlays = overlays;
    }
  ];
}
