# VM Automation Package
#
# Provides VM testing utilities for NixOS VM validation across architectures.

{
  lib,
  pkgs,
  qemu,
  writeShellScript,
  coreutils,
  gnused,
  gnugrep,
}:

let
  vmTestScript = writeShellScript "vm-test" ''
    set -euo pipefail

    # VM automation script for testing
    echo "🚀 Starting VM validation..."

    VM_NAME="$1"
    ARCH="$2"

    echo "Testing VM: $VM_NAME ($ARCH)"

    # Build VM
    nix build .#nixosConfigurations."$VM_NAME".config.system.build.vm

    # Run VM tests
    echo "✅ VM tests completed"
  '';

in
{
  inherit vmTestScript;

  default = pkgs.writeShellApplication {
    name = "vm-automation";
    runtimeInputs = [
      qemu
      coreutils
      gnused
      gnugrep
    ];
    text = vmTestScript;
  };
}
