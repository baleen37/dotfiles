{ config, pkgs, inputs, ... }:

{
  # WSL-specific system configuration
  wsl = {
    enable = true;
    defaultUser = config.currentSystemUser or "nixos";
    startMenuLaunchers = true;
    wslConf = {
      automount.root = "/mnt";
      network.generateHosts = false;
      interop.enabled = true;
    };
  };

  # Performance optimizations for WSL
  systemd.settings = {
    Manager = {
      DefaultLimitNOFILE = 1048576;
      DefaultTimeoutStartSec = "10s";
      DefaultTimeoutStopSec = "10s";
    };
  };

  # Windows interoperability
  environment.variables = {
    WSLENV = "NIXPKGS_ALLOW_UNFREE:NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM";
    LIBGL_ALWAYS_SOFTWARE = "1";  # For graphics in virtualized environment
  };

  # Essential services for WSL
  services = {
    sshd.enable = true;
  };

  # Allow packages that may not officially support WSL
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}