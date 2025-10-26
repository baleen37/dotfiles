# NixOS VM Management
{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    qemu
    qemu-utils
  ];

  # Create VM directory
  home.file.".local/share/nixos-vm/.keep".text = "";

  # NixOS VM management script
  home.packages = [
    (pkgs.writeShellScriptBin "nixos-vm" ''
      set -euo pipefail

      VM_DIR="$HOME/.local/share/nixos-vm"
      NIXOS_ISO_URL="https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso"

      # Create VM
      if [ "$1" = "create" ]; then
        NAME="$2"
        SIZE="''${3:-20G}"
        if [ -z "$NAME" ]; then
          echo "Usage: nixos-vm create <name> [size]"
          exit 1
        fi

        mkdir -p "$VM_DIR/$NAME"
        echo "Creating $SIZE disk for $NAME..."
        qemu-img create -f qcow2 "$VM_DIR/$NAME/disk.img" "$SIZE"
        echo "NixOS VM $NAME created"
        exit 0
      fi

      # Download NixOS ISO
      if [ "$1" = "download" ]; then
        echo "Downloading NixOS minimal ISO..."
        curl -L -o "$VM_DIR/nixos-minimal.iso" "$NIXOS_ISO_URL"
        echo "NixOS ISO downloaded to $VM_DIR/nixos-minimal.iso"
        exit 0
      fi

      # Install NixOS
      if [ "$1" = "install" ]; then
        NAME="$2"
        if [ -z "$NAME" ]; then
          echo "Usage: nixos-vm install <name>"
          exit 1
        fi

        DISK="$VM_DIR/$NAME/disk.img"
        ISO="$VM_DIR/nixos-minimal.iso"

        if [ ! -f "$DISK" ]; then
          echo "VM disk not found: $DISK"
          echo "Run: nixos-vm create $NAME"
          exit 1
        fi

        if [ ! -f "$ISO" ]; then
          echo "NixOS ISO not found: $ISO"
          echo "Run: nixos-vm download"
          exit 1
        fi

        echo "Starting NixOS installation for $NAME..."
        qemu-system-x86_64 \
          -m 2048 \
          -smp 2 \
          -cdrom "$ISO" \
          -drive file="$DISK",format=qcow2,if=virtio \
          -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
          -boot d \
          -display cocoa &
        echo "NixOS installer started. Follow installation instructions."
        exit 0
      fi

      # Start installed NixOS
      if [ "$1" = "start" ]; then
        NAME="$2"
        if [ -z "$NAME" ]; then
          echo "Usage: nixos-vm start <name>"
          exit 1
        fi

        DISK="$VM_DIR/$NAME/disk.img"
        if [ ! -f "$DISK" ]; then
          echo "VM disk not found: $DISK"
          echo "Run: nixos-vm create $NAME"
          exit 1
        fi

        echo "Starting NixOS VM: $NAME"
        qemu-system-x86_64 \
          -m 2048 \
          -smp 2 \
          -drive file="$DISK",format=qcow2,if=virtio \
          -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
          -display cocoa &
        echo "NixOS VM $NAME started"
        exit 0
      fi

      # List VMs
      if [ "$1" = "list" ]; then
        echo "NixOS VMs:"
        ls -1 "$VM_DIR" 2>/dev/null | grep -v ".iso$" || echo "  No VMs found"
        exit 0
      fi

      # Delete VM
      if [ "$1" = "delete" ]; then
        NAME="$2"
        if [ -z "$NAME" ]; then
          echo "Usage: nixos-vm delete <name>"
          exit 1
        fi

        if [ -d "$VM_DIR/$NAME" ]; then
          rm -rf "$VM_DIR/$NAME"
          echo "NixOS VM $NAME deleted"
        else
          echo "VM not found: $NAME"
        fi
        exit 0
      fi

      # Help
      echo "NixOS VM Manager"
      echo ""
      echo "Usage:"
      echo "  nixos-vm list                              - List VMs"
      echo "  nixos-vm download                           - Download NixOS ISO"
      echo "  nixos-vm create <name> [size]              - Create VM disk"
      echo "  nixos-vm install <name>                    - Install NixOS"
      echo "  nixos-vm start <name>                      - Start installed VM"
      echo "  nixos-vm delete <name>                     - Delete VM"
      echo ""
      echo "Examples:"
      echo "  nixos-vm download"
      echo "  nixos-vm create my-nixos 20G"
      echo "  nixos-vm install my-nixos"
      echo "  nixos-vm start my-nixos"
    '')
  ];
}
