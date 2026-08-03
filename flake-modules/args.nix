{ inputs, ... }:
let
  overlays = import ../lib/overlays.nix { inherit inputs; };
in
{
  perSystem = _: {
    _module.args.overlays = overlays;
  };

  _module.args = {
    inherit overlays;
    cacheConfig = import ../lib/cache-config.nix;
  };
}
