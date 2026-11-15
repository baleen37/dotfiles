_:

{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          # Core Nix tooling
          deadnix
          statix

          # Development utilities
          git
          just
          pre-commit
          jq
          yq

          # Testing tools
          bats

          # Optional: common utilities
          curl
          wget
        ];

        shellHook = ''
          echo "Dotfiles development environment loaded"
          echo "Available commands:"
          echo "  just format     - Format all files"
          echo "  just test       - Execute unit and integration assertions"
          echo "  just test-build - Build every unit + integration assertion"
          echo "  just switch     - Build and apply configuration changes"
        '';
      };
    };
}
