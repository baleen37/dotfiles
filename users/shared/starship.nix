# Starship Prompt Configuration
# Minimal and compact prompt inspired by Pure

{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Basic settings
      add_newline = true;
      command_timeout = 1000;
      scan_timeout = 30;

      # Custom format (module order) - minimal
      format = lib.concatStrings [
        "$directory"
        "$git_branch"
        "$git_status"
        "$python"
        "$nix_shell"
        "$character"
      ];

      # Right prompt - only command duration
      right_format = "$cmd_duration";

      # Character module (prompt symbol)
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      # Directory module
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        format = "[$path]($style)";
        repo_root_format = "[$repo_root]($repo_root_style)([$path]($style)) ";
        repo_root_style = "bold cyan";
        style = "cyan";
      };

      # Git branch
      git_branch = {
        format = "[$symbol$branch]($style) ";
        symbol = "";
        style = "bold purple";
      };

      # Git status
      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        conflicted = "=";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        untracked = "?\${count}";
        stashed = "\$";
        modified = "!\${count}";
        staged = "+\${count}";
        renamed = "»";
        deleted = "✘\${count}";
        style = "bold yellow";
      };

      # Command duration - only show if > 3s
      cmd_duration = {
        min_time = 3000;
        format = "[$duration]($style)";
        style = "bold yellow";
      };

      # Python virtual environment
      python = {
        format = "[\${symbol}\${pyenv_prefix}(\${version} )(\\(\${virtualenv}\\) )]($style)";
        symbol = " ";
        style = "yellow";
        pyenv_version_name = false;
        detect_extensions = [ ];
        detect_files = [ ];
        detect_folders = [ ];
      };

      # Nix shell
      nix_shell = {
        format = "[$symbol$state( \\($name\\))]($style) ";
        symbol = "nix ";
        impure_msg = "!";
        pure_msg = "";
        style = "bold blue";
      };

      # Disable unnecessary modules for performance
      username.disabled = true;
      hostname.disabled = true;
      time.disabled = true;
      package.disabled = true;
      nodejs.disabled = true;
      rust.disabled = true;
      golang.disabled = true;
      php.disabled = true;
      ruby.disabled = true;
      java.disabled = true;
      docker_context.disabled = true;
      aws.disabled = true;
      gcloud.disabled = true;
    };
  };
}
