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
    direnv = prev.direnv.overrideAttrs (oldAttrs: {
      env = oldAttrs.env // { CGO_ENABLED = "1"; };
      preBuild = ''
        # Remove -linkmode=external from the build flags
        substituteInPlace GNUmakefile \
          --replace-fail "-ldflags '-linkmode=external" "-ldflags '"
      '';
    });
  })
]
