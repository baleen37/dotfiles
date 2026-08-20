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
  options.modules.packages.dev.enable = lib.mkEnableOption "development tools";

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        nodejs_22
        bun
        python3
        python3Packages.pipx
        virtualenv
        uv
        direnv
        pre-commit
        gnumake
        cmake
      ]
      # On Darwin, VS Code comes from the `visual-studio-code` Homebrew cask.
      # A nix store copy is opened from its store path, so macOS stamps
      # `com.apple.macl` onto it and `nix-collect-garbage` can no longer
      # delete the path. Homebrew installs into /Applications instead.
      ++ lib.optional (!stdenv.hostPlatform.isDarwin) vscode;
  };
}
