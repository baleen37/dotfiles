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
  flake.darwinConfigurations = {
    macbook-pro = mkSystem "macbook-pro" {
      system = "aarch64-darwin";
      inherit user;
      darwin = true;
    };

    baleen-macbook = mkSystem "baleen-macbook" {
      system = "aarch64-darwin";
      inherit user;
      darwin = true;
    };

    kakaostyle-jito = mkSystem "kakaostyle-jito" {
      system = "aarch64-darwin";
      user = "jito.hello";
      darwin = true;
    };
  };
}
