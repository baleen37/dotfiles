{ inputs }:

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

  userHMConfig = ../users/${user}/home-manager.nix;
  userOSConfig = ../users/${user}/${osConfig};
  machineConfig = ../machines/${name}.nix;

in
systemFunc {
  inherit system;

  specialArgs = {
    inherit inputs;
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
        extraSpecialArgs = { inherit inputs; };
      };

      # Set required home-manager options
      users.users.${user} = {
        name = user;
        home = if darwin then "/Users/${user}" else "/home/${user}";
      };
    }
  ];
}
