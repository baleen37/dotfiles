# VM Configuration Examples
#
# This file contains example VM configurations that can be used
# with the QEMU VM management system. These are reference configurations
# that can be customized based on your needs.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.qemu-vm = {
    enable = true;

    # Example VM configurations
    vms = {
      # Lightweight development VM for testing
      nixos-test = {
        name = "nixos-test";
        memory = 2048;
        cores = 2;
        diskSize = "20G";
        diskFormat = "qcow2";
        networkMode = "user";
        graphics = false;
        display = "none";
        enableKvm = false;
      };

      # NixOS development environment with GUI
      nixos-dev = {
        name = "nixos-dev";
        memory = 4096;
        cores = 4;
        diskSize = "40G";
        diskFormat = "qcow2";
        networkMode = "user";
        graphics = true;
        display = "cocoa";
        enableKvm = false;
        sharedFolder = {
          host = "${config.home.homeDirectory}/Projects";
          guest = "/host-projects";
        };
      };

      # Ubuntu testing VM
      ubuntu-test = {
        name = "ubuntu-test";
        memory = 3072;
        cores = 2;
        diskSize = "25G";
        diskFormat = "qcow2";
        networkMode = "user";
        graphics = true;
        display = "cocoa";
        enableKvm = false;
        iso = "${config.home.homeDirectory}/Downloads/ubuntu-22.04.3-live-server-amd64.iso";
      };

      # Alpine Linux minimal VM
      alpine-minimal = {
        name = "alpine-minimal";
        memory = 1024;
        cores = 1;
        diskSize = "8G";
        diskFormat = "qcow2";
        networkMode = "user";
        graphics = false;
        display = "none";
        enableKvm = false;
      };
    };

    # Auto-start lightweight VMs
    autoStart = [ "alpine-minimal" ];
  };

  # Home Manager configuration for VM tools
  home.packages = with pkgs; [
    # Additional VM-related tools
    virt-manager # For GUI VM management (alternative to our scripts)
    libvirt # Virtualization API daemon
    dnsmasq # DNS forwarding for VM networks
    bridge-utils # Network bridge utilities
  ];

  # Environment variables for VM development
  home.sessionVariables = {
    QEMU_SYSTEM_X86_64 = "${pkgs.qemu}/bin/qemu-system-x86_64";
    VM_BASE_DIR = "${config.home.homeDirectory}/.local/share/qemu/vms";
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };

  # Shell aliases for quick VM access
  programs.zsh.shellAliases = {
    vm-start = "qemu-vm-manager start-all";
    vm-stop = "qemu-vm-manager stop-all";
    vm-status = "qemu-vm-manager status-all";
    vm-list = "qemu-vm-manager list";

    # Quick access to specific VMs
    nixos-test = "qemu-vm-nixos-test";
    nixos-dev = "qemu-vm-nixos-dev";
    ubuntu-test = "qemu-vm-ubuntu-test";
    alpine = "qemu-vm-alpine-minimal";
  };
}
