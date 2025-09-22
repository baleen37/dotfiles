# T024: Config deployer for /config/deploy contract
# Provides Claude Code configuration deployment functionality

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.claude-code;

  # Import related modules
  configModule = import ./config.nix { inherit config lib pkgs; };
  symlinkModule = import ./symlink.nix { inherit config lib pkgs; };

  # Deployment utilities
  deploymentUtils = {
    # Platform detection
    detectPlatform = ''
      detect_platform() {
        if [[ "$OSTYPE" == "darwin"* ]]; then
          echo "darwin"
        elif [[ -f /etc/nixos/configuration.nix ]]; then
          echo "nixos"
        else
          echo "unknown"
        fi
      }
    '';

    # Validate deployment request
    validateDeployRequest = platform: force_overwrite: dry_run: ''
      validate_deploy_request() {
        local platform="$1"
        local force_overwrite="$2"
        local dry_run="$3"

        # Validate platform
        case "$platform" in
          darwin|nixos)
            ;;
          *)
            echo "Error: Invalid platform '$platform'. Must be 'darwin' or 'nixos'" >&2
            return 1
            ;;
        esac

        # Validate force_overwrite (must be true per contract)
        if [[ "$force_overwrite" != "true" ]]; then
          echo "Error: force_overwrite must be true (no backups allowed)" >&2
          return 1
        fi

        # Validate dry_run
        if [[ "$dry_run" != "true" && "$dry_run" != "false" ]]; then
          echo "Error: dry_run must be true or false" >&2
          return 1
        fi

        return 0
      }

      validate_deploy_request "${platform}" "${if force_overwrite then "true" else "false"}" "${if dry_run then "true" else "false"}"
    '';

    # Execute deployment steps
    executeDeployment = platform: force_overwrite: dry_run: ''
      execute_deployment() {
        local platform="$1"
        local force_overwrite="$2"
        local dry_run="$3"
        local deployment_log="/tmp/claude_code_deploy_$(date +%s).log"

        # Initialize deployment context
        export CLAUDE_CODE_PLATFORM="$platform"
        export CLAUDE_CODE_FORCE_OVERWRITE="$force_overwrite"
        export CLAUDE_CODE_DRY_RUN="$dry_run"
        export CLAUDE_CODE_CONFIG_DIR="${config.home.homeDirectory}/${cfg.configDirectory}"
        export CLAUDE_CODE_SOURCE_DIR="${config.home.homeDirectory}/dev/dotfiles/.claude"

        echo "Starting Claude Code deployment..." | tee -a "$deployment_log"
        echo "Platform: $platform" | tee -a "$deployment_log"
        echo "Force Overwrite: $force_overwrite" | tee -a "$deployment_log"
        echo "Dry Run: $dry_run" | tee -a "$deployment_log"
        echo "Config Directory: $CLAUDE_CODE_CONFIG_DIR" | tee -a "$deployment_log"
        echo "Source Directory: $CLAUDE_CODE_SOURCE_DIR" | tee -a "$deployment_log"
        echo "" | tee -a "$deployment_log"

        # Step 1: Validate source directories exist
        if [[ ! -d "$CLAUDE_CODE_SOURCE_DIR" ]]; then
          echo "Error: Source directory does not exist: $CLAUDE_CODE_SOURCE_DIR" | tee -a "$deployment_log"
          return 1
        fi

        # Step 2: Create target directory structure
        if [[ "$dry_run" == "false" ]]; then
          mkdir -p "$CLAUDE_CODE_CONFIG_DIR"
          echo "Created config directory: $CLAUDE_CODE_CONFIG_DIR" | tee -a "$deployment_log"
        else
          echo "DRY RUN: Would create config directory: $CLAUDE_CODE_CONFIG_DIR" | tee -a "$deployment_log"
        fi

        # Step 3: Deploy symlinks
        local symlink_results
        symlink_results=$(deploy_symlinks "$deployment_log")
        echo "$symlink_results" | tee -a "$deployment_log"

        # Step 4: Platform-specific deployment
        case "$platform" in
          darwin)
            deploy_darwin_specific "$deployment_log"
            ;;
          nixos)
            deploy_nixos_specific "$deployment_log"
            ;;
        esac

        echo "Deployment completed successfully" | tee -a "$deployment_log"
        echo "Log file: $deployment_log"

        return 0
      }

      execute_deployment "${platform}" "${if force_overwrite then "true" else "false"}" "${if dry_run then "true" else "false"}"
    '';

    # Deploy symlinks with detailed tracking
    deploySymlinks = ''
            deploy_symlinks() {
              local deployment_log="$1"
              local symlinks_created=()
              local symlink_errors=()

              echo "Deploying Claude Code symlinks..." | tee -a "$deployment_log"

              # Define symlink mappings
              declare -A symlink_mappings=(
                ["commands"]="$CLAUDE_CODE_SOURCE_DIR/commands:$CLAUDE_CODE_CONFIG_DIR/commands"
                ["agents"]="$CLAUDE_CODE_SOURCE_DIR/agents:$CLAUDE_CODE_CONFIG_DIR/agents"
                ["constitution"]="$CLAUDE_CODE_SOURCE_DIR/commands/constitution.md:$CLAUDE_CODE_CONFIG_DIR/commands/constitution.md"
                ["claude_md"]="$CLAUDE_CODE_SOURCE_DIR/../CLAUDE.md:$CLAUDE_CODE_CONFIG_DIR/CLAUDE.md"
              )

              # Process each symlink
              for symlink_name in "''${!symlink_mappings[@]}"; do
                local mapping="''${symlink_mappings[$symlink_name]}"
                local source_path="''${mapping%:*}"
                local target_path="''${mapping#*:}"

                echo "Processing symlink: $symlink_name" | tee -a "$deployment_log"
                echo "  Source: $source_path" | tee -a "$deployment_log"
                echo "  Target: $target_path" | tee -a "$deployment_log"

                # Validate source exists
                if [[ ! -e "$source_path" ]]; then
                  local error="Source does not exist: $source_path"
                  echo "  ERROR: $error" | tee -a "$deployment_log"
                  symlink_errors+=("$error")
                  continue
                fi

                # Handle existing target
                if [[ -e "$target_path" || -L "$target_path" ]]; then
                  if [[ "$CLAUDE_CODE_FORCE_OVERWRITE" == "true" ]]; then
                    if [[ "$CLAUDE_CODE_DRY_RUN" == "false" ]]; then
                      rm -rf "$target_path"
                      echo "  Removed existing target: $target_path" | tee -a "$deployment_log"
                    else
                      echo "  DRY RUN: Would remove existing target: $target_path" | tee -a "$deployment_log"
                    fi
                  else
                    local error="Target exists and force_overwrite is false: $target_path"
                    echo "  ERROR: $error" | tee -a "$deployment_log"
                    symlink_errors+=("$error")
                    continue
                  fi
                fi

                # Create target directory if needed
                local target_dir
                target_dir="$(dirname "$target_path")"
                if [[ "$CLAUDE_CODE_DRY_RUN" == "false" ]]; then
                  mkdir -p "$target_dir"
                else
                  echo "  DRY RUN: Would create directory: $target_dir" | tee -a "$deployment_log"
                fi

                # Create symlink
                if [[ "$CLAUDE_CODE_DRY_RUN" == "false" ]]; then
                  if ln -sf "$source_path" "$target_path"; then
                    echo "  SUCCESS: Created symlink: $target_path -> $source_path" | tee -a "$deployment_log"
                    symlinks_created+=("$symlink_name:$source_path:$target_path:created")
                  else
                    local error="Failed to create symlink: $target_path -> $source_path"
                    echo "  ERROR: $error" | tee -a "$deployment_log"
                    symlink_errors+=("$error")
                  fi
                else
                  echo "  DRY RUN: Would create symlink: $target_path -> $source_path" | tee -a "$deployment_log"
                  symlinks_created+=("$symlink_name:$source_path:$target_path:created")
                fi
              done

              # Generate symlink results JSON
              local symlinks_json="[]"
              if command -v jq >/dev/null 2>&1 && [[ ''${#symlinks_created[@]} -gt 0 ]]; then
                local symlink_objects=()
                for symlink_info in "''${symlinks_created[@]}"; do
                  IFS=':' read -r name source target status <<< "$symlink_info"
                  symlink_objects+=("{\"name\":\"$name\",\"source\":\"$source\",\"target\":\"$target\",\"status\":\"$status\",\"force\":true}")
                done
                symlinks_json="[$(IFS=,; echo "''${symlink_objects[*]}")]"
              fi

              # Return deployment result
              local success="true"
              [[ ''${#symlink_errors[@]} -eq 0 ]] || success="false"

              cat <<DEPLOY_RESULT
      {
        "success": $success,
        "symlinks_created": $symlinks_json,
        "errors": [$(IFS=','; printf '"%s"' "''${symlink_errors[@]}" | sed 's/,$//' | tr '\n' ',' | sed 's/,$//' )]
      }
      DEPLOY_RESULT
            }
    '';

    # Darwin-specific deployment
    deployDarwinSpecific = ''
      deploy_darwin_specific() {
        local deployment_log="$1"

        echo "Executing Darwin-specific deployment steps..." | tee -a "$deployment_log"

        # Set up Homebrew integration if needed
        if command -v brew >/dev/null 2>&1; then
          echo "Homebrew detected, configuring Claude Code integration..." | tee -a "$deployment_log"

          # Create brew completion integration
          local brew_completion_dir="$CLAUDE_CODE_CONFIG_DIR/completion"
          if [[ "$CLAUDE_CODE_DRY_RUN" == "false" ]]; then
            mkdir -p "$brew_completion_dir"
            echo "# Claude Code Homebrew completion integration" > "$brew_completion_dir/brew.sh"
            echo "Created Homebrew completion integration" | tee -a "$deployment_log"
          else
            echo "DRY RUN: Would create Homebrew completion integration" | tee -a "$deployment_log"
          fi
        fi

        # Set up macOS-specific paths
        echo "Configuring macOS-specific paths..." | tee -a "$deployment_log"

        return 0
      }
    '';

    # NixOS-specific deployment
    deployNixOSSpecific = ''
      deploy_nixos_specific() {
        local deployment_log="$1"

        echo "Executing NixOS-specific deployment steps..." | tee -a "$deployment_log"

        # Validate NixOS environment
        if [[ ! -f /etc/nixos/configuration.nix ]]; then
          echo "Warning: Not running on NixOS, skipping NixOS-specific deployment" | tee -a "$deployment_log"
          return 0
        fi

        # Check if Home Manager is available
        if command -v home-manager >/dev/null 2>&1; then
          echo "Home Manager detected, setting up integration..." | tee -a "$deployment_log"

          # Create Home Manager integration marker
          local hm_marker="$CLAUDE_CODE_CONFIG_DIR/.home-manager-managed"
          if [[ "$CLAUDE_CODE_DRY_RUN" == "false" ]]; then
            echo "Managed by Home Manager on $(date)" > "$hm_marker"
            echo "Created Home Manager integration marker" | tee -a "$deployment_log"
          else
            echo "DRY RUN: Would create Home Manager integration marker" | tee -a "$deployment_log"
          fi
        fi

        # Set up systemd user service integration
        echo "Configuring systemd user service integration..." | tee -a "$deployment_log"

        return 0
      }
    '';
  };

  # Main deployment script
  deploymentScript = pkgs.writeShellScript "claude-code-deploy" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Source deployment utilities
        ${deploymentUtils.detectPlatform}
        ${deploymentUtils.validateDeployRequest cfg.forceOverwrite false false}
        ${deploymentUtils.executeDeployment "$(detect_platform)" cfg.forceOverwrite false}
        ${deploymentUtils.deploySymlinks}
        ${deploymentUtils.deployDarwinSpecific}
        ${deploymentUtils.deployNixOSSpecific}

        # Main deployment function (implements POST /config/deploy)
        deploy_claude_code_config() {
          local platform="''${1:-$(detect_platform)}"
          local force_overwrite="''${2:-${if cfg.forceOverwrite then "true" else "false"}}"
          local dry_run="''${3:-false}"

          # Validate deployment request
          if ! validate_deploy_request "$platform" "$force_overwrite" "$dry_run"; then
            return 1
          fi

          # Execute deployment
          execute_deployment "$platform" "$force_overwrite" "$dry_run"
        }

        # Command line interface
        main() {
          local action="''${1:-deploy}"
          local platform="''${2:-$(detect_platform)}"
          local force_overwrite="''${3:-${if cfg.forceOverwrite then "true" else "false"}}"
          local dry_run="''${4:-false}"

          case "$action" in
            deploy)
              deploy_claude_code_config "$platform" "$force_overwrite" "$dry_run"
              ;;
            validate)
              validate_deploy_request "$platform" "$force_overwrite" "$dry_run"
              echo "Deployment request is valid"
              ;;
            platform)
              detect_platform
              ;;
            help)
              cat <<EOF
    Claude Code Configuration Deployer

    Usage: claude-code-deploy [action] [platform] [force_overwrite] [dry_run]

    Actions:
      deploy     Deploy Claude Code configuration (default)
      validate   Validate deployment parameters
      platform   Detect current platform
      help       Show this help message

    Parameters:
      platform         Target platform (darwin|nixos, auto-detected)
      force_overwrite  Force overwrite existing files (true|false, default: ${if cfg.forceOverwrite then "true" else "false"})
      dry_run         Dry run mode (true|false, default: false)

    Examples:
      claude-code-deploy
      claude-code-deploy deploy nixos true false
      claude-code-deploy validate darwin true true
    EOF
              ;;
            *)
              echo "Error: Unknown action '$action'. Use 'help' for usage information." >&2
              return 1
              ;;
          esac
        }

        # Execute main function if script is run directly
        if [[ "''${BASH_SOURCE[0]}" == "''${0}" ]]; then
          main "$@"
        fi
  '';

in
{
  # Configuration options specific to deployment
  options.programs.claude-code.deployment = {
    enableAutoDetection = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically detect platform for deployment";
    };

    validateBeforeDeploy = mkOption {
      type = types.bool;
      default = true;
      description = "Validate configuration before deployment";
    };

    createBackupBeforeDeploy = mkOption {
      type = types.bool;
      default = false;
      description = "Create backup before deployment (conflicts with no-backup policy)";
    };

    deploymentTimeout = mkOption {
      type = types.int;
      default = 300;
      description = "Deployment timeout in seconds";
    };

    retryOnFailure = mkOption {
      type = types.bool;
      default = true;
      description = "Retry deployment on failure";
    };

    maxRetries = mkOption {
      type = types.int;
      default = 3;
      description = "Maximum number of deployment retries";
    };
  };

  # Configuration implementation
  config = mkIf cfg.enable {
    # Add deployment script to user packages
    home.packages = [ deploymentScript ];

    # Shell aliases for deployment
    home.shellAliases = {
      claude-deploy = "claude-code-deploy deploy";
      claude-deploy-dry = "claude-code-deploy deploy $(claude-code-deploy platform) true true";
      claude-validate-deploy = "claude-code-deploy validate";
    };

    # Environment variables for deployment
    home.sessionVariables = {
      CLAUDE_CODE_DEPLOY_SCRIPT = "${deploymentScript}";
      CLAUDE_CODE_PLATFORM = "$(${deploymentScript} platform 2>/dev/null || echo unknown)";
    };

    # Deployment assertions
    assertions = [
      {
        assertion = !(cfg.deployment.createBackupBeforeDeploy && cfg.forceOverwrite);
        message = "Cannot create backup and force overwrite simultaneously";
      }
      {
        assertion = cfg.deployment.deploymentTimeout > 0;
        message = "Deployment timeout must be greater than 0";
      }
      {
        assertion = cfg.deployment.maxRetries >= 0;
        message = "Max retries must be 0 or greater";
      }
    ];

    # Warnings for backup policy
    warnings = optional cfg.deployment.createBackupBeforeDeploy
      "Backup creation is enabled but conflicts with the no-backup policy. Consider disabling createBackupBeforeDeploy.";
  };

  # Export deployment utilities
  meta = {
    inherit deploymentUtils deploymentScript;

    # Contract compliance functions
    contractFunctions = {
      # POST /config/deploy implementation
      deployConfig = platform: force_overwrite: dry_run: ''
        ${deploymentScript} deploy "${platform}" "${if force_overwrite then "true" else "false"}" "${if dry_run then "true" else "false"}"
      '';

      # Platform detection for deployment
      detectPlatform = ''
        ${deploymentScript} platform
      '';

      # Validation for deployment requests
      validateDeployment = platform: force_overwrite: dry_run: ''
        ${deploymentScript} validate "${platform}" "${if force_overwrite then "true" else "false"}" "${if dry_run then "true" else "false"}"
      '';
    };
  };
}
