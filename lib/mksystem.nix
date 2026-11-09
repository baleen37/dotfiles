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
  homeModules ? { },
  machineModules ? [ ],
}:

let
  inherit (inputs.nixpkgs) lib;
  systemFunc = if darwin then inputs.darwin.lib.darwinSystem else lib.nixosSystem;

  # Use shared user configuration directory (users/shared)
  # Actual username is dynamically set via currentSystemUser
  userHMConfig = ../users/shared/home-manager.nix;

  hmModule =
    if darwin then
      inputs.home-manager.darwinModules.home-manager
    else
      inputs.home-manager.nixosModules.home-manager;

  # Unified cache configuration for both Determinate Nix and traditional Nix
  cacheConfig = import ./cache-config.nix;
  cacheSettings = cacheConfig // {
    # A trusted user is root-equivalent (nix.conf manual), so trust only the
    # host user instead of every member of @admin / @wheel.
    trusted-users = [
      "root"
      user
    ];
  };

in
systemFunc {
  specialArgs = {
    inherit inputs self;
    currentSystemName = name;
    currentSystemUser = user;
    isDarwin = darwin;
  };

  modules = [
    ./setup-requirements.nix
    { nixpkgs.hostPlatform = system; }
  ]
  ++ machineModules
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
        nix.gc = lib.mkIf (!darwin) {
          automatic = true;
          dates = "daily";
          options = "--delete-older-than 7d";
        };
      }
    )
  ]
  ++ lib.optionals (!darwin) [
    # Home Manager configures zsh; NixOS still logs users into bash by default.
    (
      { pkgs, ... }:
      {
        programs.zsh = {
          enable = true;
          # See machines/darwin/common.nix: Home Manager's .zshrc owns both.
          enableGlobalCompInit = false;
          promptInit = "";
        };
        users.users.${user}.shell = pkgs.zsh;
      }
    )
  ]
  ++ lib.optionals darwin [
    # Determinate Nix integration (Darwin systems only)
    inputs.determinate.darwinModules.default
    {
      determinateNix = {
        customSettings = cacheSettings;
        determinateNixd.garbageCollector.strategy = "automatic";
      };
    }
  ]
  ++ [
    # Home Manager integration
    hmModule
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
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
        home = if darwin then "/Users/${user}" else "/home/${user}";
      }
      // lib.optionalAttrs (!darwin) {
        isNormalUser = true;
        # The Macs' keys as published on GitHub, pinned by flake.lock.
        openssh.authorizedKeys.keyFiles = [ inputs.baleen37-keys ];
      };

      # `make switch` picks the flake output by `hostname -s`; a machine module
      # may still override it.
      networking.hostName = lib.mkDefault name;

      # Apply overlays
      nixpkgs.overlays = overlays;

      # The only unfree switch for system builds (darwin and NixOS); perSystem
      # pkgs get theirs from flake-modules/args.nix.
      nixpkgs.config.allowUnfree = true;
    }
  ];
}
