{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        just.enable = true;
        nixfmt.enable = true;
        statix.enable = true;
        deadnix.enable = true;
        shfmt.enable = true;
        prettier.enable = true;
      };

      settings.formatter = {
        shfmt.options = [
          "-i"
          "2"
          "-ci"
          "-bn"
          "-sr"
        ];
        prettier.includes = [
          "*.md"
          "*.yaml"
          "*.yml"
          "*.json"
        ];
      };
    };
  };
}
