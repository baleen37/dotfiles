# T018: Symlink model - manages symlink creation for Claude Code configuration
# Provides functionality for creating and managing symlinks with proper error handling

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.claude-code;

  # Symlink management utilities
  symlinkUtils = {
    # Create symlink with proper error handling
    createSymlink = source: target: force: ''
      create_symlink() {
        local source="$1"
        local target="$2"
        local force="$3"

        # Validate source exists
        if [[ ! -e "$source" ]]; then
          echo "Error: Source '$source' does not exist" >&2
          return 1
        fi

        # Create target directory if needed
        mkdir -p "$(dirname "$target")"

        # Handle existing target
        if [[ -e "$target" || -L "$target" ]]; then
          if [[ "$force" == "true" ]]; then
            echo "Removing existing target: $target"
            rm -f "$target"
          else
            echo "Error: Target '$target' already exists and force is not enabled" >&2
            return 1
          fi
        fi

        # Create symlink
        ln -sf "$source" "$target"

        # Verify symlink was created successfully
        if [[ -L "$target" ]]; then
          echo "Successfully created symlink: $target -> $source"
          return 0
        else
          echo "Error: Failed to create symlink: $target -> $source" >&2
          return 1
        fi
      }

      create_symlink "${source}" "${target}" "${if force then "true" else "false"}"
    '';

    # Validate symlink integrity
    validateSymlink = target: ''
      validate_symlink() {
        local target="$1"

        # Check if target exists
        if [[ ! -L "$target" ]]; then
          echo "Error: '$target' is not a symlink" >&2
          return 1
        fi

        # Check if symlink target exists
        if [[ ! -e "$target" ]]; then
          echo "Error: Symlink '$target' is broken (target does not exist)" >&2
          return 1
        fi

        # Get symlink target
        local link_target
        link_target=$(readlink "$target")
        echo "Symlink '$target' points to '$link_target'"
        return 0
      }

      validate_symlink "${target}"
    '';

    # Remove symlink safely
    removeSymlink = target: force: ''
      remove_symlink() {
        local target="$1"
        local force="$2"

        # Check if target is a symlink
        if [[ ! -L "$target" ]]; then
          if [[ "$force" == "true" ]]; then
            echo "Warning: '$target' is not a symlink, skipping removal"
            return 0
          else
            echo "Error: '$target' is not a symlink" >&2
            return 1
          fi
        fi

        # Remove symlink
        rm -f "$target"

        # Verify removal
        if [[ ! -e "$target" ]]; then
          echo "Successfully removed symlink: $target"
          return 0
        else
          echo "Error: Failed to remove symlink: $target" >&2
          return 1
        fi
      }

      remove_symlink "${target}" "${if force then "true" else "false"}"
    '';

    # List all symlinks in directory
    listSymlinks = directory: ''
      list_symlinks() {
        local directory="$1"

        if [[ ! -d "$directory" ]]; then
          echo "Error: Directory '$directory' does not exist" >&2
          return 1
        fi

        echo "Symlinks in $directory:"
        find "$directory" -type l -exec sh -c '
          for link; do
            target=$(readlink "$link")
            if [[ -e "$link" ]]; then
              status="✓"
            else
              status="✗"
            fi
            echo "  $status $link -> $target"
          done
        ' sh {} +
      }

      list_symlinks "${directory}"
    '';

    # Fix broken symlinks
    fixBrokenSymlinks = directory: ''
      fix_broken_symlinks() {
        local directory="$1"
        local fixed_count=0

        if [[ ! -d "$directory" ]]; then
          echo "Error: Directory '$directory' does not exist" >&2
          return 1
        fi

        echo "Checking for broken symlinks in $directory..."

        while IFS= read -r -d "" link; do
          if [[ ! -e "$link" ]]; then
            echo "Found broken symlink: $link"
            rm -f "$link"
            ((fixed_count++))
            echo "Removed broken symlink: $link"
          fi
        done < <(find "$directory" -type l -print0)

        echo "Fixed $fixed_count broken symlinks"
        return 0
      }

      fix_broken_symlinks "${directory}"
    '';
  };

  # Configuration for symlink deployment
  symlinkConfig = {
    # Source paths in dotfiles repository
    sourcePaths = {
      commands = "${config.home.homeDirectory}/dev/dotfiles/.claude/commands";
      agents = "${config.home.homeDirectory}/dev/dotfiles/.claude/agents";
      constitution = "${config.home.homeDirectory}/dev/dotfiles/.claude/commands/constitution.md";
      claudeMd = "${config.home.homeDirectory}/dev/dotfiles/CLAUDE.md";
    };

    # Target paths in user's home directory
    targetPaths = {
      commands = "${config.home.homeDirectory}/${cfg.configDirectory}/commands";
      agents = "${config.home.homeDirectory}/${cfg.configDirectory}/agents";
      constitution = "${config.home.homeDirectory}/${cfg.configDirectory}/commands/constitution.md";
      claudeMd = "${config.home.homeDirectory}/${cfg.configDirectory}/CLAUDE.md";
    };

    # Symlink creation scripts
    createAllSymlinks = ''
      # Create all Claude Code symlinks
      echo "Creating Claude Code symlinks..."

      ${symlinkUtils.createSymlink symlinkConfig.sourcePaths.commands symlinkConfig.targetPaths.commands cfg.forceOverwrite}
      ${symlinkUtils.createSymlink symlinkConfig.sourcePaths.agents symlinkConfig.targetPaths.agents cfg.forceOverwrite}
      ${symlinkUtils.createSymlink symlinkConfig.sourcePaths.constitution symlinkConfig.targetPaths.constitution cfg.forceOverwrite}
      ${symlinkUtils.createSymlink symlinkConfig.sourcePaths.claudeMd symlinkConfig.targetPaths.claudeMd cfg.forceOverwrite}

      echo "Claude Code symlinks created successfully"
    '';

    # Symlink validation scripts
    validateAllSymlinks = ''
      # Validate all Claude Code symlinks
      echo "Validating Claude Code symlinks..."

      ${symlinkUtils.validateSymlink symlinkConfig.targetPaths.commands}
      ${symlinkUtils.validateSymlink symlinkConfig.targetPaths.agents}
      ${symlinkUtils.validateSymlink symlinkConfig.targetPaths.constitution}
      ${symlinkUtils.validateSymlink symlinkConfig.targetPaths.claudeMd}

      echo "All Claude Code symlinks are valid"
    '';

    # Symlink cleanup scripts
    cleanupSymlinks = ''
      # Clean up Claude Code symlinks
      echo "Cleaning up Claude Code symlinks..."

      ${symlinkUtils.removeSymlink symlinkConfig.targetPaths.commands true}
      ${symlinkUtils.removeSymlink symlinkConfig.targetPaths.agents true}
      ${symlinkUtils.removeSymlink symlinkConfig.targetPaths.constitution true}
      ${symlinkUtils.removeSymlink symlinkConfig.targetPaths.claudeMd true}

      # Remove empty directories
      rmdir "${config.home.homeDirectory}/${cfg.configDirectory}/commands" 2>/dev/null || true
      rmdir "${config.home.homeDirectory}/${cfg.configDirectory}" 2>/dev/null || true

      echo "Claude Code symlinks cleaned up"
    '';
  };

  # Backup management (when enabled)
  backupUtils = mkIf cfg.enableBackups {
    # Create backup of existing file
    createBackup = target: ''
      create_backup() {
        local target="$1"

        if [[ -e "$target" && ! -L "$target" ]]; then
          local backup_path="''${target}${cfg.backupSuffix}"
          local backup_count=1

          # Find unique backup name
          while [[ -e "$backup_path" ]]; do
            backup_path="''${target}${cfg.backupSuffix}.$backup_count"
            ((backup_count++))
          done

          cp -p "$target" "$backup_path"
          echo "Created backup: $backup_path"
        fi
      }

      create_backup "${target}"
    '';

    # Restore from backup
    restoreBackup = target: ''
      restore_backup() {
        local target="$1"
        local backup_path="''${target}${cfg.backupSuffix}"

        if [[ -f "$backup_path" ]]; then
          cp -p "$backup_path" "$target"
          echo "Restored from backup: $target"
          return 0
        else
          echo "Error: Backup file not found: $backup_path" >&2
          return 1
        fi
      }

      restore_backup "${target}"
    '';

    # Clean up backup files
    cleanupBackups = ''
      cleanup_backups() {
        local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"

        echo "Cleaning up backup files..."
        find "$config_dir" -name "*${cfg.backupSuffix}*" -type f -delete
        echo "Backup files cleaned up"
      }

      cleanup_backups
    '';
  };

in
{
  # Configuration options specific to symlink management
  options.programs.claude-code.symlinks = {
    enableValidation = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to validate symlinks after creation";
    };

    enableAutoFix = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to automatically fix broken symlinks";
    };

    customMappings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Custom source -> target symlink mappings";
      example = literalExpression ''
        {
          "/path/to/source" = "~/target/location";
        }
      '';
    };
  };

  # Configuration implementation
  config = mkIf cfg.enable {
    # Home Manager activation script for symlink management
    home.activation = {
      claudeCodeSymlinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${optionalString (cfg.deploymentHooks ? pre) cfg.deploymentHooks.pre}

        # Create Claude Code symlinks
        $DRY_RUN_CMD ${symlinkConfig.createAllSymlinks}

        # Validate symlinks if enabled
        ${optionalString cfg.symlinks.enableValidation ''
          $DRY_RUN_CMD ${symlinkConfig.validateAllSymlinks}
        ''}

        # Fix broken symlinks if enabled
        ${optionalString cfg.symlinks.enableAutoFix ''
          $DRY_RUN_CMD ${symlinkUtils.fixBrokenSymlinks "${config.home.homeDirectory}/${cfg.configDirectory}"}
        ''}

        # Create custom symlinks
        ${concatStringsSep "\n" (mapAttrsToList (source: target: ''
          $DRY_RUN_CMD ${symlinkUtils.createSymlink source target cfg.forceOverwrite}
        '') cfg.symlinks.customMappings)}

        ${optionalString (cfg.deploymentHooks ? post) cfg.deploymentHooks.post}
      '';

      # Cleanup activation script
      claudeCodeCleanup = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        ${optionalString (cfg.deploymentHooks ? cleanup) cfg.deploymentHooks.cleanup}
        ${optionalString cfg.enableBackups backupUtils.cleanupBackups}
      '';
    };

    # Shell aliases for symlink management
    home.shellAliases = {
      claude-symlinks-list = symlinkUtils.listSymlinks "${config.home.homeDirectory}/${cfg.configDirectory}";
      claude-symlinks-fix = symlinkUtils.fixBrokenSymlinks "${config.home.homeDirectory}/${cfg.configDirectory}";
      claude-symlinks-validate = symlinkConfig.validateAllSymlinks;
    };
  };

  # Internal module utilities (not exported to Home Manager)
  # Note: Removed meta export to prevent Home Manager configuration conflicts
}
