# T019: HomeManagerModule - main Claude Code integration module
# Orchestrates Claude Code configuration deployment through Home Manager

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.claude-code;

  # Import sub-modules
  configModule = import ./claude-code/config.nix { inherit config lib pkgs; };
  symlinkModule = import ./claude-code/symlink.nix { inherit config lib pkgs; };

  # Claude Code package with management scripts
  claudeCodePackage = pkgs.writeShellScriptBin "claude-code" ''
    #!/usr/bin/env bash
    # Claude Code management script
    set -euo pipefail

    CLAUDE_CONFIG_DIR="${config.home.homeDirectory}/${cfg.configDirectory}"
    DOTFILES_DIR="${config.home.homeDirectory}/dev/dotfiles"

    show_help() {
      cat <<EOF
    Claude Code Management Script

    Usage: claude-code <command> [options]

    Commands:
      status      Show configuration status
      deploy      Deploy configuration
      validate    Validate symlinks and configuration
      clean       Clean up configuration
      backup      Create backup of current configuration
      restore     Restore from backup
      help        Show this help message

    Options:
      --force     Force operation (overwrite existing files)
      --dry-run   Show what would be done without executing
      --verbose   Enable verbose output

    Environment Variables:
      CLAUDE_CONFIG_DIR   Configuration directory (default: ~/.claude)
      DOTFILES_DIR        Dotfiles repository path
    EOF
    }

    show_status() {
      echo "=== Claude Code Configuration Status ==="
      echo "Config Directory: $CLAUDE_CONFIG_DIR"
      echo "Dotfiles Directory: $DOTFILES_DIR"
      echo "Nix Managed: ${if cfg.enable then "Yes" else "No"}"
      echo "Force Overwrite: ${if cfg.forceOverwrite then "Yes" else "No"}"
      echo "Backups Enabled: ${if cfg.enableBackups then "Yes" else "No"}"
      echo ""

      if [[ -d "$CLAUDE_CONFIG_DIR" ]]; then
        echo "Configuration exists:"
        ${symlinkModule.meta.symlinkUtils.listSymlinks "$CLAUDE_CONFIG_DIR"}
      else
        echo "Configuration not found"
      fi
    }

    deploy_config() {
      local force_flag=""
      local dry_run_flag=""

      [[ "''${FORCE:-false}" == "true" ]] && force_flag="--force"
      [[ "''${DRY_RUN:-false}" == "true" ]] && dry_run_flag="--dry-run"

      echo "=== Deploying Claude Code Configuration ==="

      # Run Home Manager activation
      if command -v home-manager >/dev/null 2>&1; then
        echo "Running Home Manager switch..."
        home-manager switch $force_flag $dry_run_flag
      else
        echo "Home Manager not found, running manual deployment..."
        ${symlinkModule.meta.symlinkConfig.createAllSymlinks}
      fi

      echo "Deployment complete"
    }

    validate_config() {
      echo "=== Validating Claude Code Configuration ==="
      ${symlinkModule.meta.symlinkConfig.validateAllSymlinks}
      echo "Validation complete"
    }

    clean_config() {
      echo "=== Cleaning Claude Code Configuration ==="
      ${symlinkModule.meta.symlinkConfig.cleanupSymlinks}
      echo "Cleanup complete"
    }

    create_backup() {
      echo "=== Creating Configuration Backup ==="
      if [[ -d "$CLAUDE_CONFIG_DIR" ]]; then
        local backup_dir="$CLAUDE_CONFIG_DIR.backup.$(date +%s)"
        cp -r "$CLAUDE_CONFIG_DIR" "$backup_dir"
        echo "Backup created: $backup_dir"
      else
        echo "No configuration found to backup"
      fi
    }

    restore_backup() {
      echo "=== Restoring Configuration from Backup ==="
      local latest_backup
      latest_backup=$(find "$(dirname "$CLAUDE_CONFIG_DIR")" -name "$(basename "$CLAUDE_CONFIG_DIR").backup.*" -type d | sort -r | head -n1)

      if [[ -n "$latest_backup" ]]; then
        [[ -d "$CLAUDE_CONFIG_DIR" ]] && rm -rf "$CLAUDE_CONFIG_DIR"
        cp -r "$latest_backup" "$CLAUDE_CONFIG_DIR"
        echo "Restored from: $latest_backup"
      else
        echo "No backup found to restore"
        return 1
      fi
    }

    # Parse command line arguments
    COMMAND="''${1:-help}"
    shift || true

    # Parse options
    while [[ $# -gt 0 ]]; do
      case $1 in
        --force)
          export FORCE=true
          shift
          ;;
        --dry-run)
          export DRY_RUN=true
          shift
          ;;
        --verbose)
          export VERBOSE=true
          set -x
          shift
          ;;
        *)
          echo "Unknown option: $1" >&2
          exit 1
          ;;
      esac
    done

    # Execute command
    case $COMMAND in
      status)
        show_status
        ;;
      deploy)
        deploy_config
        ;;
      validate)
        validate_config
        ;;
      clean)
        clean_config
        ;;
      backup)
        create_backup
        ;;
      restore)
        restore_backup
        ;;
      help|--help|-h)
        show_help
        ;;
      *)
        echo "Unknown command: $COMMAND" >&2
        echo "Run 'claude-code help' for usage information"
        exit 1
        ;;
    esac
  '';

  # Pre-commit hook for validation
  preCommitHook = pkgs.writeShellScript "claude-code-pre-commit" ''
    #!/usr/bin/env bash
    # Pre-commit hook for Claude Code configuration validation
    set -euo pipefail

    echo "Validating Claude Code configuration..."

    # Check for backup files
    if find . -name "*.backup" -o -name "*.bak" -o -name "*.orig" | grep -q .; then
      echo "Error: Found backup files in repository. Please remove them before committing." >&2
      find . -name "*.backup" -o -name "*.bak" -o -name "*.orig"
      exit 1
    fi

    # Validate symlink targets exist
    if [[ -d ".claude" ]]; then
      while IFS= read -r -d "" link; do
        if [[ ! -e "$link" ]]; then
          echo "Error: Broken symlink detected: $link" >&2
          exit 1
        fi
      done < <(find .claude -type l -print0 2>/dev/null)
    fi

    echo "Claude Code configuration validation passed"
  '';

in
{
  # Import configuration from sub-modules
  imports = [
    ./claude-code/config.nix
    ./claude-code/symlink.nix
  ];

  # Main module options
  options.programs.claude-code = {
    # Core enable option (inherited from config.nix)

    # Management options
    management = {
      enablePreCommitHook = mkOption {
        type = types.bool;
        default = true;
        description = "Enable pre-commit hook for validation";
      };

      enableShellIntegration = mkOption {
        type = types.bool;
        default = true;
        description = "Enable shell aliases and functions";
      };

      enableSystemdService = mkOption {
        type = types.bool;
        default = false;
        description = "Enable systemd user service for monitoring";
      };
    };

    # Monitoring options
    monitoring = {
      enableHealthChecks = mkOption {
        type = types.bool;
        default = true;
        description = "Enable periodic health checks";
      };

      checkInterval = mkOption {
        type = types.str;
        default = "1h";
        description = "Health check interval (systemd timer format)";
      };

      notifyOnFailure = mkOption {
        type = types.bool;
        default = false;
        description = "Send notifications on health check failures";
      };
    };
  };

  # Pre-switch cleanup hooks
  preActivationCleanup = pkgs.writeShellScript "claude-code-pre-activation" ''
    #!/usr/bin/env bash
    # Pre-switch cleanup hooks for Claude Code configuration
    set -euo pipefail

    CLAUDE_CONFIG_DIR="${config.home.homeDirectory}/${cfg.configDirectory}"

    echo "=== Claude Code Pre-Switch Cleanup ==="

    # Remove backup files (critical: no backup files should exist)
    if [[ -d "$CLAUDE_CONFIG_DIR" ]]; then
      echo "Cleaning up backup files..."
      find "$CLAUDE_CONFIG_DIR" -name "*.backup" -type f -delete 2>/dev/null || true
      find "$CLAUDE_CONFIG_DIR" -name "*.bak" -type f -delete 2>/dev/null || true
      find "$CLAUDE_CONFIG_DIR" -name "*.orig" -type f -delete 2>/dev/null || true
      echo "Backup files removed"
    fi

    # Remove broken symlinks
    if [[ -d "$CLAUDE_CONFIG_DIR" ]]; then
      echo "Removing broken symlinks..."
      find "$CLAUDE_CONFIG_DIR" -type l ! -exec test -e {} \; -delete 2>/dev/null || true
      echo "Broken symlinks removed"
    fi

    # Create config directory if it doesn't exist
    if [[ ! -d "$CLAUDE_CONFIG_DIR" ]]; then
      echo "Creating Claude Code configuration directory..."
      mkdir -p "$CLAUDE_CONFIG_DIR"
      mkdir -p "$CLAUDE_CONFIG_DIR/commands"
      echo "Configuration directory created"
    fi

    echo "Pre-switch cleanup complete"
  '';

  # Main module configuration
  config = mkIf cfg.enable {
    # Override default package with our management script
    programs.claude-code.package = claudeCodePackage;

    # Pre-switch cleanup activation
    home.activation.claudeCodePreCleanup = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      ${preActivationCleanup}
    '';

    # Shell integration
    home = mkIf cfg.management.enableShellIntegration {
      shellAliases = {
        claude-status = "claude-code status";
        claude-deploy = "claude-code deploy";
        claude-validate = "claude-code validate";
        claude-clean = "claude-code clean";
      };

      sessionVariables = {
        CLAUDE_CODE_ENABLED = "true";
        CLAUDE_CODE_VERSION = "1.0.0";
      };
    };

    # Pre-commit hook integration
    home.file = mkIf cfg.management.enablePreCommitHook {
      ".git/hooks/pre-commit" = {
        source = preCommitHook;
        executable = true;
      };
    };

    # Systemd user service for monitoring
    systemd.user = mkIf cfg.management.enableSystemdService {
      services.claude-code-monitor = {
        Unit = {
          Description = "Claude Code Configuration Monitor";
          After = [ "graphical-session.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${claudeCodePackage}/bin/claude-code validate";
          StandardOutput = "journal";
          StandardError = "journal";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      timers.claude-code-monitor = mkIf cfg.monitoring.enableHealthChecks {
        Unit = {
          Description = "Claude Code Configuration Health Check";
          Requires = [ "claude-code-monitor.service" ];
        };

        Timer = {
          OnCalendar = cfg.monitoring.checkInterval;
          Persistent = true;
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };

    # Configuration warnings and assertions
    warnings =
      optional cfg.enableBackups
        "Claude Code backup files are enabled. Consider disabling to avoid cluttering the repository." ++
      optional (!cfg.forceOverwrite)
        "Force overwrite is disabled. Existing configurations may not be updated.";

    assertions = [
      {
        assertion = !(cfg.enableBackups && cfg.forceOverwrite);
        message = "Cannot enable both backups and force overwrite simultaneously";
      }
      {
        assertion = cfg.configDirectory != "";
        message = "Configuration directory cannot be empty";
      }
      {
        assertion = cfg.management.enableSystemdService -> cfg.monitoring.enableHealthChecks;
        message = "Health checks must be enabled when using systemd service";
      }
    ];

    # XDG integration
    xdg.configFile."claude-code/metadata.json" = {
      text = builtins.toJSON {
        version = "1.0.0";
        managedBy = "home-manager";
        lastUpdated = builtins.currentTime;
        configuration = {
          enableBackups = cfg.enableBackups;
          forceOverwrite = cfg.forceOverwrite;
          configDirectory = cfg.configDirectory;
        };
      };
    };
  };

  # Module metadata and exports
  meta = {
    maintainers = [ "dotfiles-team" ];
    description = "Claude Code configuration management for Home Manager";

    # Export sub-module functionality
    inherit (configModule.meta) getConfig getGenerator getDefaults validateConfig mergeConfigs;
    inherit (symlinkModule.meta) symlinkUtils symlinkConfig;

    # Management utilities
    managementUtils = {
      inherit claudeCodePackage preCommitHook;
    };
  };
}
