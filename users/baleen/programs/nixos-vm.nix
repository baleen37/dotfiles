# NixOS VM Management - Mitchell Style Integration
#
# Provides NixOS VM management that integrates with the Mitchell-style
# dotfiles architecture and flake-based configurations.
#
# Features:
# - Direct integration with flake.nix NixOS configurations
# - Uses nix build commands instead of make targets
# - Supports nixos-vm-x86_64 configuration from flake
# - Automated VM creation and management with Nix
#
{
  config,
  pkgs,
  ...
}:

{
  # Create VM directory
  home.file.".local/share/nixos-vm/.keep".text = "";

  # NixOS VM management script with Mitchell-style integration
  home.packages = with pkgs; [
    qemu
    qemu-utils

    # Enhanced NixOS VM management script
    (pkgs.writeShellScriptBin "nixos-vm" ''
      set -euo pipefail

      VM_DIR="$HOME/.local/share/nixos-vm"
      FLAKE_PATH="''${FLAKE_PATH:-$(pwd)}"
      NIXOS_CONFIG="nixos-vm-x86_64"

      # Function to get flake path (automatically detects if in worktree)
      get_flake_path() {
        local current_dir="$(pwd)"
        while [ "$current_dir" != "/" ]; do
          if [ -f "$current_dir/flake.nix" ]; then
            echo "$current_dir"
            return 0
          fi
          current_dir="$(dirname "$current_dir")"
        done
        echo "ERROR: No flake.nix found in parent directories" >&2
        return 1
      }

      # Function to build NixOS VM configuration
      build_vm_config() {
        local config="''${1:-$NIXOS_CONFIG}"
        echo "🔨 Building NixOS VM configuration: $config..."

        FLAKE_PATH=$(get_flake_path)
        cd "$FLAKE_PATH"

        # Build the NixOS configuration
        nix build --impure ".#nixosConfigurations.$config.config.system.build.vm" \
          --out-link "$VM_DIR/$config-vm"

        echo "✅ NixOS VM configuration built successfully"
        echo "   VM binary: $VM_DIR/$config-vm/bin/run-nixos-vm"
      }

      # Function to copy VM configuration
      copy_vm_config() {
        local config="''${1:-$NIXOS_CONFIG}"
        echo "📋 Copying NixOS VM configuration: $config..."

        FLAKE_PATH=$(get_flake_path)
        cd "$FLAKE_PATH"

        # Copy the configuration to VM directory
        mkdir -p "$VM_DIR/$config"
        nix copy --impure ".#nixosConfigurations.$config.config.system.build.toplevel" \
          --to "$VM_DIR/$config"

        echo "✅ NixOS VM configuration copied to: $VM_DIR/$config"
      }

      # Function to switch VM configuration (builds and prepares)
      switch_vm_config() {
        local config="''${1:-$NIXOS_CONFIG}"
        echo "🔄 Switching NixOS VM configuration: $config..."

        # First copy the configuration
        copy_vm_config "$config"

        # Build the VM
        build_vm_config "$config"

        echo "✅ NixOS VM configuration switched successfully"
        echo "   Ready to run: nixos-vm run $config"
      }

      # Function to run NixOS VM
      run_vm() {
        local config="''${1:-$NIXOS_CONFIG}"
        local vm_binary="$VM_DIR/$config-vm/bin/run-nixos-vm"

        if [ ! -f "$vm_binary" ]; then
          echo "❌ VM not built. Run: nixos-vm build $config"
          exit 1
        fi

        echo "🚀 Starting NixOS VM: $config"
        exec "$vm_binary"
      }

      # Function to list VM configurations
      list_vms() {
        echo "📋 Available NixOS VM configurations:"
        echo

        FLAKE_PATH=$(get_flake_path)
        cd "$FLAKE_PATH"

        # List available configurations from flake
        echo "From flake.nix:"
        nix eval --impure --json '.#nixosConfigurations' 2>/dev/null | \
          jq -r 'keys[]' 2>/dev/null | sed 's/^/  /' || \
          echo "  No nixosConfigurations found in flake"

        echo
        echo "Built VMs:"
        if [ -d "$VM_DIR" ]; then
          for vm_dir in "$VM_DIR"/*-vm; do
            if [ -d "$vm_dir" ] && [ -f "$vm_dir/bin/run-nixos-vm" ]; then
              local vm_name="$(basename "$vm_dir" | sed 's/-vm$//')"
              echo "  $vm_name (built)"
            fi
          done
        else
          echo "  No built VMs found"
        fi
      }

      # Function to clean VM builds
      clean_vms() {
        local config="''${1:-}"
        echo "🧹 Cleaning NixOS VM builds..."

        if [ -n "$config" ]; then
          if [ -L "$VM_DIR/$config-vm" ]; then
            rm "$VM_DIR/$config-vm"
            echo "✅ Cleaned: $config"
          else
            echo "⚠️  VM not found: $config"
          fi
        else
          # Clean all VMs
          if [ -d "$VM_DIR" ]; then
            rm -rf "$VM_DIR"/*-vm
            echo "✅ Cleaned all VM builds"
          fi
        fi
      }

      # Function to show status
      status_vm() {
        local config="''${1:-$NIXOS_CONFIG}"
        local vm_binary="$VM_DIR/$config-vm/bin/run-nixos-vm"

        echo "📊 NixOS VM Status:"
        echo "  Configuration: $config"
        echo "  VM directory: $VM_DIR"
        echo "  Flake path: $(get_flake_path)"

        if [ -f "$vm_binary" ]; then
          echo "  Status: Built and ready to run"
        else
          echo "  Status: Not built (run: nixos-vm build $config)"
        fi
      }

      # Main command parsing
      case "''${1:-help}" in
        build)
          build_vm_config "''${2:-}"
          ;;
        copy)
          copy_vm_config "''${2:-}"
          ;;
        switch)
          switch_vm_config "''${2:-}"
          ;;
        run)
          run_vm "''${2:-}"
          ;;
        list)
          list_vms
          ;;
        clean)
          clean_vms "''${2:-}"
          ;;
        status)
          status_vm "''${2:-}"
          ;;
        help|--help|-h)
          echo "🖥️  NixOS VM Manager - Mitchell Style"
          echo
          echo "Integrates with Mitchell-style dotfiles architecture and flake configurations."
          echo "Uses direct nix commands instead of make targets."
          echo
          echo "Usage: nixos-vm <command> [config]"
          echo
          echo "Commands:"
          echo "  build [config]     Build NixOS VM configuration (default: nixos-vm-x86_64)"
          echo "  copy [config]      Copy configuration to VM directory"
          echo "  switch [config]    Build and copy configuration (full switch)"
          echo "  run [config]       Run NixOS VM (requires build first)"
          echo "  list               List available and built VMs"
          echo "  clean [config]     Clean VM builds (all or specific config)"
          echo "  status [config]    Show VM configuration status"
          echo "  help               Show this help message"
          echo
          echo "Examples:"
          echo "  nixos-vm build                    # Build default config"
          echo "  nixos-vm switch                   # Build and copy default"
          echo "  nixos-vm run                      # Run default VM"
          echo "  nixos-vm build nixos-vm-x86_64   # Build specific config"
          echo "  nixos-vm list                     # List all VMs"
          echo "  nixos-vm status                   # Show current status"
          echo
          echo "Environment Variables:"
          echo "  FLAKE_PATH         Path to flake directory (auto-detected)"
          echo "  NIXOS_CONFIG       Default VM configuration name"
          ;;
        *)
          echo "❌ Unknown command: $1"
          echo "   Run 'nixos-vm help' for usage information"
          exit 1
          ;;
      esac
    '')
  ];
}
