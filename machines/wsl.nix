{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # Basic system configuration
  networking.hostName = "wsl-dev";
  time.timeZone = "Asia/Seoul";

  # Internationalization
  i18n.defaultLocale = "en_US.UTF-8";

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
    LIBGL_ALWAYS_SOFTWARE = "1"; # For graphics in virtualized environment
  };

  # Essential services for WSL
  services = {
    sshd.enable = true;
  };

  # Development environment - Virtualization
  virtualisation.docker.enable = true;

  # Development environment - Fonts
  fonts = {
    fontDir.enable = true;
    packages = [
      pkgs.fira-code
      pkgs.cascadia-code
    ];
  };

  # Development environment - System packages
  environment.systemPackages = with pkgs; [
    cachix
    gnumake
    killall
    xclip
  ];

  # Allow packages that may not officially support WSL
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
