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

  # Compose machine, user OS policy and user Home Manager configuration.
  userOSConfig = if darwin then ../users/shared/darwin.nix else ../users/shared/nixos.nix;
  userHMConfig = ../users/shared/home-manager.nix;

  hmModule =
    if darwin then
      inputs.home-manager.darwinModules.home-manager
    else
      inputs.home-manager.nixosModules.home-manager;

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
    userOSConfig
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
