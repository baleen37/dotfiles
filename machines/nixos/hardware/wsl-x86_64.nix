# NixOS-WSL hardware configuration for x86_64 systems
# This configuration is for WSL2 environments on Windows
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  # WSL-specific hardware settings
  # Most hardware detection is handled by NixOS-WSL modules

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # WSL uses the Windows host for filesystems
  # No traditional disk partitions needed
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };

  swapDevices = [ ];
}
