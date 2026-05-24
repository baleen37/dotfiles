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
    resolveUser =
      fallback:
      let
        env = builtins.getEnv "USER";
      in
      if env != "" && env != "root" then env else fallback;
  };
}
