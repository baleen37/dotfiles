{
  config,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    ./hardware/vm-aarch64-utm.nix
    ./vm-shared.nix
  ];

  # Interface is this on my M1
  networking.interfaces.enp0s10.useDHCP = true;

  # Qemu
  services.spice-vdagentd.enable = true;

  # Force software rendering for OpenGL applications.
  # Hardware acceleration for graphics is not fully supported in UTM VMs on Apple Silicon,
  # so this environment variable forces Mesa to use software rendering instead of
  # attempting to use virtualized GPU hardware that may not be available or stable.
  environment.variables.LIBGL_ALWAYS_SOFTWARE = "1";

  # Allow packages that may not officially support aarch64-linux.
  # Many packages in nixpkgs don't officially mark aarch64-linux as supported,
  # even though they work perfectly fine. This setting allows us to use these
  # packages in the VM despite their unsupported status in the package metadata.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
