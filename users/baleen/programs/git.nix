# Git version control configuration
#
# Manages Git global settings, aliases, and ignore file patterns
#
# Features:
#   - User info: name, email (hardcoded for Mitchell-style simplicity)
#   - Git LFS: Large file support enabled
#   - Global gitignore: Auto-exclude editors, OS, build files
#   - Pull strategy: rebase by default (autoStash enabled)
#   - Aliases:
#       - st: status
#       - co: checkout
#       - br: branch
#       - ci: commit
#       - df: diff
#       - lg: log --graph --oneline --decorate --all
#
# Ignore patterns:
#   - Editors: .vscode/, .idea/, *.swp
#   - OS: .DS_Store, Thumbs.db
#   - Development: .direnv/, node_modules/, .env.local
#   - Project: issues/, specs/, plans/
#
# VERSION: 4.0.0 (Mitchell-style migration)
# LAST UPDATED: 2025-10-25

{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    lfs = {
      enable = true;
    };

    settings = {
      user = {
        name = "Jiho";
        email = "baleen37@gmail.com";
      };
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        autocrlf = "input";
        excludesFile = "~/.gitignore_global";
      };
      pull.rebase = true;
      rebase.autoStash = true;
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        df = "diff";
        lg = "log --graph --oneline --decorate --all";
      };
    };

    ignores = [
      # Local files
      ".local/"

      # Editor files
      "*.swp"
      "*.swo"
      "*~"
      ".vscode/"
      ".idea/"

      # OS files
      ".DS_Store"
      "Thumbs.db"
      "desktop.ini"

      # Development files
      ".direnv/"
      "result"
      "result-*"
      "node_modules/"
      ".env.local"
      ".env.*.local"
      ".serena/"

      # Temporary files
      "*.tmp"
      "*.log"
      ".cache/"

      # Build artifacts
      "dist/"
      "build/"
      "target/"

      # Issues (local project management)
      "issues/"

      # Plan files (project planning)
      "specs/"
      "plans/"
    ];
  };
}
