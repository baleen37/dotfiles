{ inputs }:

{
  additions = final: _prev: import ../pkgs final;

  modifications = _final: prev: {
    # Claude Code - latest from flake input
    claude-code = inputs.claude-code.packages.${prev.stdenv.hostPlatform.system}.default;

    # 8.12.40 cannot read the schema written by 8.12.44 on existing Macs.
    _1password-gui =
      if prev.stdenv.hostPlatform.isDarwin then
        prev._1password-gui.overrideAttrs {
          version = "8.12.44";
          src = prev.fetchurl {
            url = "https://downloads.1password.com/mac/1Password-8.12.44-aarch64.zip";
            hash = "sha256-mySxRkv0N4DwThr6+LB0LyFjypTbiwYgBZ56BaJJj6E=";
          };
        }
      else
        prev._1password-gui;

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
  };

  # wt - pkgs.worktree from the flake input
  worktree = inputs.worktree.overlays.default;
}
