# VM Testing Framework

This directory contains simple but functional VM boot tests using NixOS's built-in `nixosTest` framework.

## Tests

### `boot-test-minimal.nix`
A minimal VM boot test that verifies basic functionality without complex dependencies:

- VM boots to multi-user target
- User login works
- Basic file operations
- Network connectivity
- Essential programs (git, vim, curl, wget) are available
- Shell functionality works
- Hostname is set correctly

### `boot-test.nix`
A more comprehensive VM boot test that attempts to use the actual VM configuration from `machines/nixos-vm.nix`. This test may fail if NetworkManager or other dependencies are not available in the VM environment.

## Usage

### On Linux Systems

Run VM tests using the Make targets:

```bash
# Run minimal VM test (recommended)
make test-vm-minimal

# Run all VM tests (minimal + full)
make test-vm
```

### On macOS Systems

VM tests require Linux with QEMU support. To run VM tests on macOS, you can use Docker:

```bash
# Using Docker with NixOS
docker run -it --privileged -v $(pwd):/workspace nixos/nix:latest bash -c "cd /workspace && export USER=$(whoami) && make test-vm-minimal"
```

## Requirements

- Linux system with QEMU support
- Nix with flakes enabled
- Sufficient memory and disk space for VM (2GB RAM, 2GB disk by default)

## Test Output

Successful test output looks like:

```
✓ VM reached multi-user target
✓ User login works
✓ Basic file operations work
✓ Basic programs available
✓ User home directory exists
✓ Network connectivity works
✓ File creation and modification works
✓ Shell functionality works
✓ Hostname is set correctly
🎉 All VM boot tests passed!
```

## Troubleshooting

### "VM tests require Linux with QEMU support"
VM tests can only run on Linux systems with QEMU virtualization support. Use Docker with NixOS on macOS.

### Network connectivity failures
The minimal test uses systemd-networkd instead of NetworkManager for better VM compatibility.

### Memory/disk issues
Increase the memory and disk sizes in the test configuration if needed:

```nix
virtualisation.memorySize = 2048;  # 2GB RAM
virtualisation.diskSize = 4096;   # 4GB disk
```