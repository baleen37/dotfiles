# users/shared/opencode.nix
# OpenCode configuration managed via Home Manager
#
# Pattern: Out-of-Store Symlinks (malob pattern)
# - Config files are symlinked to git repo for live editing
# - Changes apply immediately without `home-manager switch`
# - Trade-off: Sacrifices Nix reproducibility for convenience
#
# Reference: https://github.com/malob/nix-config/blob/master/home/claude.nix

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Out-of-store symlink: points to git-tracked file for live editing
  # This allows editing opencode.json without `home-manager switch`
  # Based on malob's nix-config pattern (https://github.com/malob/nix-config)
  home.file.".config/opencode/opencode.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/users/shared/.config/opencode/opencode.json";

  # Superpowers installation via activation script
  home.activation.installSuperpowers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x "${pkgs.opencode}/bin/opencode" ]; then
      SUPERPOWERS_DIR=$HOME/.config/opencode/superpowers
      if [ ! -d "$SUPERPOWERS_DIR" ]; then
        run mkdir -p ~/.config/opencode
        run ${pkgs.git}/bin/git clone https://github.com/obra/superpowers.git "$SUPERPOWERS_DIR"
      fi
      run mkdir -p ~/.config/opencode/plugins
      run rm -f ~/.config/opencode/plugins/superpowers.js
      run ln -sf "$SUPERPOWERS_DIR/.opencode/plugins/superpowers.js" ~/.config/opencode/plugins/superpowers.js
      run mkdir -p ~/.config/opencode/skills
      run rm -rf ~/.config/opencode/skills/superpowers
      run ln -sf "$SUPERPOWERS_DIR/skills" ~/.config/opencode/skills/superpowers
    fi
  '';
}
