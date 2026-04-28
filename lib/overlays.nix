# lib/overlays.nix
# Centralized overlay definitions
# Extracted from flake.nix for reuse across flake-modules
{ inputs }:

[
  (final: prev: {
    # unstable alias - nixpkgs already tracks nixpkgs-unstable
    unstable = prev;

    # Claude Code - latest from flake input
    claude-code = inputs.claude-code.packages.${prev.stdenv.hostPlatform.system}.default;

    # direnv - fix cgo build issue by removing linkmode=external
    # Disable checkPhase: 2.37.1's `make test-zsh` hangs in zsh integration test
    # under Determinate Nix (sandbox=false) on macOS. Tests are upstream-validated
    # in CI; skipping locally is safe.
    direnv = prev.direnv.overrideAttrs (oldAttrs: {
      env = oldAttrs.env // {
        CGO_ENABLED = "1";
      };
      preBuild = ''
        # Remove -linkmode=external from the build flags
        substituteInPlace GNUmakefile \
          --replace-fail "-ldflags '-linkmode=external" "-ldflags '"
      '';
      doCheck = false;
    });
  })
]
