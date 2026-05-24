{
  inputs,
  self,
  overlays,
  resolveUser,
  ...
}:

let
  mkSystem = import ../lib/mksystem.nix { inherit inputs self overlays; };
  user = resolveUser "baleen";
in
{
  flake.nixosConfigurations = {
    vm-aarch64-utm = mkSystem "vm-aarch64-utm" {
      system = "aarch64-linux";
      inherit user;
    };

    vm-x86_64-utm = mkSystem "vm-x86_64-utm" {
      system = "x86_64-linux";
      inherit user;
    };
  };
}
