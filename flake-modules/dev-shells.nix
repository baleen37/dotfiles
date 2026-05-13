{ ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-rfc-style;

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
          echo "  make format    - Format all files"
          echo "  make test      - Run tests"
          echo "  make build     - Build current platform"
          echo "  make switch    - Apply configuration changes"
        '';
      };
    };
}
