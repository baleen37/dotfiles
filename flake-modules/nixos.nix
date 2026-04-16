{ inputs, self, ... }:

let
  overlays = import ../lib/overlays.nix { inherit inputs; };
  mkSystem = import ../lib/mksystem.nix { inherit inputs self overlays; };

  user =
    let
      envUser = builtins.getEnv "USER";
    in
    if envUser != "" && envUser != "root" then envUser else "baleen";
in
{
  flake.nixosConfigurations = {
    vm-aarch64-utm = mkSystem "vm-aarch64-utm" {
      system = "aarch64-linux";
      user = user;
    };

    vm-x86_64-utm = mkSystem "vm-x86_64-utm" {
      system = "x86_64-linux";
      user = user;
    };
  };
}
