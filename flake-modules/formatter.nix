{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        nixfmt.enable = true;
        statix.enable = true;
        deadnix.enable = true;
        shfmt.enable = true;
        prettier.enable = true;
      };

      settings.global.excludes = [
        # Bash heredoc inside indented Nix strings confuses nixfmt's parser.
        "tests/e2e/tool-integration-test.nix"
      ];

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
