# users/shared/opencode.nix
# OpenCode configuration managed via Home Manager

{
  pkgs,
  lib,
  ...
}:

{
  home.file.".config/opencode/opencode.json" = {
    source = ./.config/opencode/opencode.json;
    force = true;
  };

  home.file.".config/opencode/agent" = {
    source = ./.config/opencode/agent;
    recursive = true;
    force = true;
  };

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
