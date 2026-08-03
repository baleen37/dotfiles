{ inputs, ... }:
let
  overlays = import ../lib/overlays.nix { inherit inputs; };
in
{
  perSystem = { system, ... }: {
    _module.args = {
      inherit overlays;
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    };
  };

  _module.args = {
    inherit overlays;
    cacheConfig = import ../lib/cache-config.nix;
  };
}
