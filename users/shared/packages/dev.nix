{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.packages.dev;
in
{
  options.modules.packages.dev.enable = lib.mkEnableOption "development tools" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        nodejs_22
        bun
        go
        python3
        python3Packages.pipx
        virtualenv
        uv
        direnv
        pre-commit
        gnumake
        cmake
        # Diff viewers for reviewing agent changes: hunk (also GitHub PRs),
        # diffnav (a file list over delta, fed any diff), and delta, lazygit's
        # diff renderer.
        hunk
        diffnav
        delta
      ]
      # On Darwin, VS Code comes from the `visual-studio-code` Homebrew cask.
      # A nix store copy is opened from its store path, so macOS stamps
      # `com.apple.macl` onto it and `nix-collect-garbage` can no longer
      # delete the path. Homebrew installs into /Applications instead.
      ++ lib.optional (!stdenv.hostPlatform.isDarwin) vscode;
  };
}
