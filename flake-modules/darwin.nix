{ inputs, self, ... }:

let
  overlays = import ../lib/overlays.nix { inherit inputs; };
  mkSystem = import ../lib/mksystem.nix { inherit inputs self overlays; };

  # Dynamic user resolution: get from environment variable, fallback to "baleen"
  # Requires --impure flag for nix build/switch commands
  user =
    let
      envUser = builtins.getEnv "USER";
    in
    if envUser != "" && envUser != "root" then envUser else "baleen";
in
{
  flake.darwinConfigurations = {
    macbook-pro = mkSystem "macbook-pro" {
      system = "aarch64-darwin";
      user = user;
      darwin = true;
    };

    baleen-macbook = mkSystem "baleen-macbook" {
      system = "aarch64-darwin";
      user = user;
      darwin = true;
    };

    kakaostyle-jito = mkSystem "kakaostyle-jito" {
      system = "aarch64-darwin";
      user = "jito.hello";
      darwin = true;
    };
  };
}
