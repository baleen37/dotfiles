_:

{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          # Core Nix tooling
          nixfmt-rfc-style
          alejandra
          deadnix
          statix

          # Development utilities
          git
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
          echo "  make format     - Format all files"
          echo "  make test       - Evaluate all checks"
          echo "  make test-build - Build every unit + integration assertion"
          echo "  make switch     - Build and apply configuration changes"
        '';
      };
    };
}
