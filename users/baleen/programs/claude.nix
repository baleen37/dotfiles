# Claude Code configuration
#
# Manages Claude Code IDE settings by symlinking configuration files
# from modules/shared/config/claude/ to ~/.claude/
#
# Managed files:
#   - settings.json: Claude Code basic settings (direct link, no rebuild needed)
#   - CLAUDE.md: Project-specific AI instructions (direct link, no rebuild needed)
#   - commands/: Custom Claude commands (direct link, no rebuild needed)
#   - agents/: AI agent configurations (direct link, no rebuild needed)
#   - skills/: Claude skill configurations (direct link, no rebuild needed)
#   - hooks/: Git hook scripts (Nix store, Go binary auto-build)
#
# Supported platforms: macOS (Darwin), Linux
# Packages: claude-hooks (CLI and hooks binary), claude-code-nix
#
# Uses mkOutOfStoreSymlink:
#   - Home Manager's config.lib.file.mkOutOfStoreSymlink function
#   - Creates symlinks pointing directly to source directory
#   - Immediate changes without rebuild
#   - Uses self.outPath for automatic dotfiles path resolution
#   - Bypasses Nix store (out-of-store direct symlink)
#
# Nix Store links:
#   - hooks/: Built Go binaries (requires compilation, uses Nix store)
#
# VERSION: 8.0.0 (Migrated to Mitchell-style programs structure)
# LAST UPDATED: 2025-10-25

{
  pkgs,
  config,
  self,
  ...
}:

let
  # Dotfiles root directory dynamically resolved from flake's actual location
  dotfilesRoot = self.outPath;

  # Path to actual Claude config files
  claudeConfigDirSource = "${dotfilesRoot}/modules/shared/config/claude";

  # Claude Code uses ~/.claude for both platforms
  claudeHomeDir = ".claude";

  # Import claude-hooks binary from separate module
  claudeHooks = pkgs.callPackage ../../../../modules/shared/programs/claude/claude-hook { };

  # Create hooks directory with claude-hooks binary and wrappers
  hooksDir = pkgs.runCommand "claude-hooks-dir" { } ''
        mkdir -p $out
        cp ${claudeHooks}/bin/claude-hooks $out/claude-hooks
        chmod +x $out/claude-hooks

        # Create wrapper scripts that call claude-hooks with appropriate subcommand
        cat > $out/git-commit-validator <<'EOF'
    #!/usr/bin/env bash
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    exec "$SCRIPT_DIR/claude-hooks" git-commit-validator
    EOF
        chmod +x $out/git-commit-validator

        cat > $out/gh-pr-validator <<'EOF'
    #!/usr/bin/env bash
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    exec "$SCRIPT_DIR/claude-hooks" gh-pr-validator
    EOF
        chmod +x $out/gh-pr-validator

        cat > $out/message-cleaner <<'EOF'
    #!/usr/bin/env bash
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    exec "$SCRIPT_DIR/claude-hooks" message-cleaner
    EOF
        chmod +x $out/message-cleaner
  '';

in
{
  # Add Claude Code packages
  home.packages = [
    claudeHooks # Global claude-hooks binary for terminal use
    pkgs.claude-code-nix # Claude Code IDE package
  ];

  # Home Manager file configuration
  home.file = {
    # Hooks directory - Nix store (contains compiled Go binary)
    "${claudeHomeDir}/hooks" = {
      source = hooksDir;
      recursive = true;
    };
  };

  # Activation script for direct symlinks to local dotfiles repository
  # This bypasses Nix store completely and creates true out-of-store symlinks
  home.activation.setupClaudeDirectSymlinks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    # Claude configuration setup - Direct symlinks to local dotfiles
    CLAUDE_HOME="$HOME/.claude"
    # Dynamically find the dotfiles repository by searching for a known file
    # Look for .git directory or flake.nix to identify the dotfiles repo
    CLAUDE_SOURCE_DIR=""

    # Search from current directory and common locations
    SEARCH_PATHS=(
      "$(pwd)"
      "$HOME/dev/dotfiles"
      "/Users/jito/dev/dotfiles"
      "$HOME/projects/dotfiles"
    )

    for search_path in "''${SEARCH_PATHS[@]}"; do
      if [[ -d "$search_path/.git" ]] && [[ -d "$search_path/modules/shared/config/claude" ]]; then
        CLAUDE_SOURCE_DIR="$search_path/modules/shared/config/claude"
        break
      elif [[ -f "$search_path/flake.nix" ]] && [[ -d "$search_path/modules/shared/config/claude" ]]; then
        CLAUDE_SOURCE_DIR="$search_path/modules/shared/config/claude"
        break
      fi
    done

    # Fallback to Nix store if no local repo found
    if [[ -z "$CLAUDE_SOURCE_DIR" ]]; then
      CLAUDE_SOURCE_DIR="${claudeConfigDirSource}"
      echo "⚠️  Using Nix store source (local dotfiles not found)"
    else
      echo "✅ Found local dotfiles repository"
    fi

    # Ensure source directory exists
    if [[ ! -d "$CLAUDE_SOURCE_DIR" ]]; then
      echo "⚠️  Claude source directory not found: $CLAUDE_SOURCE_DIR"
      exit 1
    fi

    # Create Claude home directory if it doesn't exist
    mkdir -p "$CLAUDE_HOME"

    # Define files and directories to symlink
    FILES=(
      "settings.json"
      "CLAUDE.md"
      "agents"
      "commands"
      "skills"
    )

    echo "🔗 Setting up Claude direct symlinks..."

    # Remove any existing Nix store links and create direct symlinks
    for file in "''${FILES[@]}"; do
      target="$CLAUDE_HOME/$file"
      source="$CLAUDE_SOURCE_DIR/$file"

      # Remove existing link/file if it exists
      if [[ -e "$target" || -L "$target" ]]; then
        rm -f "$target"
      fi

      # Create direct symlink if source exists
      if [[ -e "$source" ]]; then
        ln -sf "$source" "$target"
        echo "  ✅ $file → local dotfiles"
      else
        echo "  ⚠️  Source not found: $source"
      fi
    done

    echo "✅ Claude direct symlinks setup complete!"
    echo "   📁 Source: $CLAUDE_SOURCE_DIR"
    echo "   🎯 Target: $CLAUDE_HOME"
  '';
}
