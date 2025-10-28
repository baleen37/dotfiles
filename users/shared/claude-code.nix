# users/shared/claude-code.nix
# Claude Code configuration using direct symlink via activation script
# Uses home.activation to create symlink outside of Nix store

{
  config,
  lib,
  pkgs,
  self,
  ...
}:

{
  # Create direct symlink to Claude configuration directory
  # This ensures the symlink points to the actual dotfiles directory, not /nix/store
  # Uses git to find the actual repository location dynamically
  home.activation.linkClaudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CLAUDE_TARGET="${config.home.homeDirectory}/.config/claude"

    # Find actual dotfiles repository path by checking common locations
    DOTFILES_ROOT=""
    if [ -d "${config.home.homeDirectory}/dotfiles/.git" ]; then
      DOTFILES_ROOT="${config.home.homeDirectory}/dotfiles"
    elif [ -d "${config.home.homeDirectory}/.dotfiles/.git" ]; then
      DOTFILES_ROOT="${config.home.homeDirectory}/.dotfiles"
    elif [ -d "${config.home.homeDirectory}/dev/dotfiles/.git" ]; then
      DOTFILES_ROOT="${config.home.homeDirectory}/dev/dotfiles"
    else
      # Try to find via existing symlink or git
      if [ -L "$CLAUDE_TARGET" ]; then
        EXISTING_LINK=$(${pkgs.coreutils}/bin/readlink "$CLAUDE_TARGET")
        if [[ "$EXISTING_LINK" == *"/dotfiles/"* ]]; then
          DOTFILES_ROOT=$(echo "$EXISTING_LINK" | ${pkgs.gnused}/bin/sed 's|/users/shared/\.config/claude||')
        fi
      fi
    fi

    if [ -z "$DOTFILES_ROOT" ] || [ ! -d "$DOTFILES_ROOT" ]; then
      echo "⚠️  Warning: Could not find dotfiles repository. Symlink may point to read-only Nix store."
      echo "    Expected locations: ~/dotfiles, ~/.dotfiles, ~/dev/dotfiles"
      CLAUDE_SOURCE="${self.outPath}/users/shared/.config/claude"
    else
      CLAUDE_SOURCE="$DOTFILES_ROOT/users/shared/.config/claude"
    fi

    # Remove existing link/directory if it exists
    if [ -e "$CLAUDE_TARGET" ] || [ -L "$CLAUDE_TARGET" ]; then
      $DRY_RUN_CMD rm -rf "$CLAUDE_TARGET"
    fi

    # Create parent directory if needed
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.config"

    # Create symlink
    $DRY_RUN_CMD ln -sfn "$CLAUDE_SOURCE" "$CLAUDE_TARGET"

    if [ -z "$DRY_RUN_CMD" ]; then
      echo "✅ Created symlink: $CLAUDE_TARGET -> $CLAUDE_SOURCE"
    fi
  '';
}
