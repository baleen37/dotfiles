# Git Version Control Configuration
#
# Git configuration with LFS, aliases, and comprehensive ignores.
#
# VERSION: 3.1.0 (Extracted from development.nix)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, platformInfo
, userInfo
, ...
}:

let
  inherit (userInfo) name email;
in
{
  programs.git = {
    enable = true;
    userName = name;
    userEmail = email;
    lfs = {
      enable = true;
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

    extraConfig = {
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
  };
}
