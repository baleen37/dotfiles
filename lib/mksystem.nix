{ inputs, self }:

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
    }
  ];
}
