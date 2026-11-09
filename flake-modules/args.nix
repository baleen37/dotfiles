{ inputs, config, ... }:
let
  overlays = with config.flake.overlays; [
    additions
    modifications
    worktree
  ];
in
{
  flake.overlays = import ../overlays { inherit inputs; };

  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
    };
  };

  _module.args = {
    inherit overlays;
  };
}
