# QEMU VM Management Configuration
#
# Provides declarative QEMU virtual machine management with Nix.
# Supports creating, configuring, and managing VM lifecycle through Nix.
#
# Features:
# - Declarative VM configuration (memory, CPU, disk, networking)
# - Automated VM creation and management
# - ISO-based VM installation support
# - Network configuration (user mode and bridge modes)
# - Resource usage optimization for development

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.qemu-vm;

  # VM configuration type
  vmConfig = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "VM name identifier";
      };

      memory = mkOption {
        type = types.ints.positive;
        default = 2048;
        description = "VM memory in MB";
      };

      cores = mkOption {
        type = types.ints.positive;
        default = 2;
        description = "Number of CPU cores";
      };

      diskSize = mkOption {
        type = types.str;
        default = "20G";
        description = "Virtual disk size (e.g., '20G', '10240M')";
      };

      diskFormat = mkOption {
        type = types.enum [
          "qcow2"
          "raw"
          "vmdk"
        ];
        default = "qcow2";
        description = "Virtual disk format";
      };

      iso = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to ISO file for installation";
      };

      networkMode = mkOption {
        type = types.enum [
          "user"
          "bridge"
        ];
        default = "user";
        description = "Network mode";
      };

      bridgeInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Bridge interface name (when networkMode = bridge)";
      };

      graphics = mkOption {
        type = types.bool;
        default = true;
        description = "Enable graphics display";
      };

      display = mkOption {
        type = types.enum [
          "gtk"
          "cocoa"
          "vnc"
          "none"
        ];
        default = "cocoa";
        description = "Display backend";
      };

      sharedFolder = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              host = mkOption {
                type = types.str;
                description = "Host directory path";
              };
              guest = mkOption {
                type = types.str;
                description = "Guest mount point";
              };
            };
          }
        );
        default = null;
        description = "Shared folder configuration";
      };

      enableKvm = mkOption {
        type = types.bool;
        default = false;
        description = "Enable KVM acceleration (Linux only)";
      };
    };
  };

  # Generate QEMU command from configuration
  generateQemuCommand =
    vm:
    let
      cpu = if vm.enableKvm then "host" else "qemu64";
      machine = if vm.enableKvm then "q35,accel=kvm" else "q35";
      memory = "${toString vm.memory}M";
      smp = toString vm.cores;
      disk = "file=${config.home.homeDirectory}/.local/share/qemu/vms/${vm.name}/disk.img,format=${vm.diskFormat},if=virtio";
      network =
        if vm.networkMode == "user" then
          "-netdev user,id=net0 -device virtio-net-pci,netdev=net0"
        else
          "-netdev bridge,id=net0,br=${vm.bridgeInterface} -device virtio-net-pci,netdev=net0";

      displayOption =
        if vm.graphics then
          switch vm.display {
            gtk = "-display gtk";
            cocoa = "-display cocoa";
            vnc = "-display vnc=:0";
            none = "-display none";
          }
        else
          "-display none";

      serialOption = if !vm.graphics then "-serial stdio" else "";

      isoOption = optionalString (vm.iso != null) "-cdrom ${vm.iso}";
      bootOption = if vm.iso != null then "-boot d" else "-boot c";

      sharedOption = optionalString (
        vm.sharedFolder != null
      ) "-virtfs local,path=${vm.sharedFolder.host},mount_tag=share,security_model=passthrough";

    in
    ''
      ${pkgs.qemu}/bin/qemu-system-x86_64 \
        -machine ${machine} \
        -cpu ${cpu} \
        -m ${memory} \
        -smp ${smp} \
        -drive ${disk} \
        ${network} \
        ${displayOption} \
        ${serialOption} \
        ${isoOption} \
        ${bootOption} \
        ${sharedOption}
    '';

  # VM management scripts
  vmScript =
    vm:
    pkgs.writeShellScriptBin "qemu-vm-${vm.name}" ''
      set -euo pipefail

      VM_DIR="${config.home.homeDirectory}/.local/share/qemu/vms/${vm.name}"
      DISK_PATH="$VM_DIR/disk.img"
      PID_FILE="$VM_DIR/vm.pid"

      # Create VM directory if it doesn't exist
      mkdir -p "$VM_DIR"

      # Function to check if VM is running
      is_running() {
        [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE)" 2>/dev/null
      }

      # Function to start VM
      start_vm() {
        if is_running; then
          echo "VM ${vm.name} is already running (PID: $(cat $PID_FILE))"
          exit 1
        fi

        # Create disk if it doesn't exist
        if [[ ! -f "$DISK_PATH" ]]; then
          echo "Creating ${vm.diskSize} disk image: $DISK_PATH"
          ${pkgs.qemu}/bin/qemu-img create -f ${vm.diskFormat} "$DISK_PATH" ${vm.diskSize}
        fi

        echo "Starting VM ${vm.name}..."
        ${generateQemuCommand vm} &
        VM_PID=$!
        echo $VM_PID > "$PID_FILE"
        echo "VM ${vm.name} started (PID: $VM_PID)"
      }

      # Function to stop VM
      stop_vm() {
        if ! is_running; then
          echo "VM ${vm.name} is not running"
          exit 1
        fi

        echo "Stopping VM ${vm.name}..."
        kill "$(cat "$PID_FILE")"
        rm -f "$PID_FILE"
        echo "VM ${vm.name} stopped"
      }

      # Function to show VM status
      status_vm() {
        if is_running; then
          echo "VM ${vm.name} is running (PID: $(cat $PID_FILE))"
        else
          echo "VM ${vm.name} is not running"
        fi
      }

      # Function to connect to VM console (for headless mode)
      console_vm() {
        if ! is_running; then
          echo "VM ${vm.name} is not running"
          exit 1
        fi

        echo "Connecting to VM ${vm.name} console..."
        # This would require additional setup for serial console access
        echo "Console access not yet implemented"
      }

      # Parse command line arguments
      case "''${1:-start}" in
        start)
          start_vm
          ;;
        stop)
          stop_vm
          ;;
        restart)
          stop_vm
          sleep 2
          start_vm
          ;;
        status)
          status_vm
          ;;
        console)
          console_vm
          ;;
        *)
          echo "Usage: $0 {start|stop|restart|status|console}"
          echo "  start   - Start the VM"
          echo "  stop    - Stop the VM"
          echo "  restart - Restart the VM"
          echo "  status  - Show VM status"
          echo "  console - Connect to VM console"
          exit 1
          ;;
      esac
    '';

in
{
  options.programs.qemu-vm = {
    enable = mkEnableOption "QEMU VM management";

    vms = mkOption {
      type = types.attrsOf vmConfig;
      default = { };
      description = "VM configurations";
    };

    autoStart = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of VM names to auto-start";
    };

    dataDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/qemu/vms";
      description = "Base directory for VM data";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      qemu
      qemu-utils
      coreutils

      # Simple VM management script
      (pkgs.writeShellScriptBin "vm" ''
        set -euo pipefail

        VM_DIR="$HOME/.local/share/qemu/vms"

        # List VMs
        if [ "$1" = "list" ]; then
          echo "Available VMs:"
          ls -1 "$VM_DIR" 2>/dev/null || echo "  No VMs found"
          exit 0
        fi

        # Create VM
        if [ "$1" = "create" ]; then
          NAME="$2"
          SIZE="''${3:-20G}"
          if [ -z "$NAME" ]; then
            echo "Usage: vm create <name> [size]"
            exit 1
          fi

          mkdir -p "$VM_DIR/$NAME"
          echo "Creating $SIZE disk for $NAME..."
          qemu-img create -f qcow2 "$VM_DIR/$NAME/disk.img" "$SIZE"
          echo "VM $NAME created"
          exit 0
        fi

        # Start VM
        if [ "$1" = "start" ]; then
          NAME="$2"
          if [ -z "$NAME" ]; then
            echo "Usage: vm start <name>"
            exit 1
          fi

          DISK="$VM_DIR/$NAME/disk.img"
          if [ ! -f "$DISK" ]; then
            echo "VM disk not found: $DISK"
            echo "Run: vm create $NAME"
            exit 1
          fi

          echo "Starting VM: $NAME"
          qemu-system-x86_64 \
            -m 2048 \
            -smp 2 \
            -drive file="$DISK",format=qcow2,if=virtio \
            -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
            -display cocoa &
          echo "VM $NAME started"
          exit 0
        fi

        # Start with ISO
        if [ "$1" = "start-iso" ]; then
          NAME="$2"
          ISO="$3"
          if [ -z "$NAME" ] || [ -z "$ISO" ]; then
            echo "Usage: vm start-iso <name> <iso-path>"
            exit 1
          fi

          DISK="$VM_DIR/$NAME/disk.img"
          if [ ! -f "$DISK" ]; then
            mkdir -p "$VM_DIR/$NAME"
            qemu-img create -f qcow2 "$DISK" 20G
          fi

          echo "Starting VM: $NAME with ISO: $ISO"
          qemu-system-x86_64 \
            -m 2048 \
            -smp 2 \
            -cdrom "$ISO" \
            -drive file="$DISK",format=qcow2,if=virtio \
            -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
            -boot d \
            -display cocoa &
          echo "VM $NAME started with ISO"
          exit 0
        fi

        # Help
        echo "Simple VM Manager"
        echo ""
        echo "Usage:"
        echo "  vm list                           - List VMs"
        echo "  vm create <name> [size]           - Create VM disk"
        echo "  vm start <name>                   - Start VM"
        echo "  vm start-iso <name> <iso-path>    - Start VM with ISO"
        echo ""
        echo "Examples:"
        echo "  vm create nixos 20G"
        echo "  vm start-iso nixos ~/Downloads/nixos.iso"
        echo "  vm start nixos"
      '')
    ];
  };
}
