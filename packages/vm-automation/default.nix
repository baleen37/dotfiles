# VM Automation Package
#
# Simple utilities for VM testing and validation.
# Provides basic shell scripts for VM management.

{ lib, pkgs, writeShellApplication, qemu, coreutils }:

{
  # Simple VM test script
  vm-test = pkgs.writeShellApplication {
    name = "vm-test";
    runtimeInputs = [ qemu coreutils ];
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "🖥️  VM Test Utility"
      echo "Usage: vm-test <vm-configuration>"
      echo ""
      echo "Available commands:"
      echo "  make test-vm-minimal    # Run minimal VM boot test"
      echo "  make test-vm            # Run full VM test suite"
      echo ""
      echo "This is a utility script for VM testing."
      echo "For actual VM tests, use the Make targets."
    '';
  };

  # Default package
  default = pkgs.writeShellApplication {
    name = "vm-automation";
    runtimeInputs = [ qemu coreutils ];
    text = ''
      #!/usr/bin/env bash
      echo "VM Automation Utilities"
      echo "Use make test-vm or make test-vm-minimal for VM testing"
    '';
  };
}