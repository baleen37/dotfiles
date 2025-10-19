# NixOS System Configuration
#
# Complete NixOS system definition for desktop environment with bspwm window manager.
# Provides declarative configuration for boot, networking, services, and user management.
#
# FEATURES:
#   - Systemd-boot EFI with 42 generation limit
#   - BSPWM tiling window manager with LightDM greeter
#   - Picom compositor with animations and rounded corners
#   - Docker virtualization support
#   - VSCode Remote Tunnel service (systemd user service)
#   - Syncthing for file synchronization
#   - Hardware support: Ledger, OpenGL graphics
#
# SERVICES:
#   - X11 display server with BSPWM window manager
#   - OpenSSH for remote access
#   - GVFS for file system operations
#   - VSCode Remote Tunnel daemon with auto-download
#
# SECURITY:
#   - SSH key-based authentication
#   - Trusted users configuration
#   - Nix flakes and experimental features enabled
#
# CUSTOMIZATION:
#   - Time zone: America/New_York
#   - Default shell: zsh
#   - Font packages: JetBrains Mono, DejaVu, Noto, Font Awesome

{
  pkgs,
  user ? (
    import ../../lib/user-resolution.nix {
      default = "baleen";
      returnFormat = "string";
    }
  ),
  ...
}:

let
  keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ];
in
{
  imports = [
    ../../modules/shared/files.nix
    ../../modules/shared/cachix
    # NOTE: disk-config.nix (disko) omitted for CI compatibility
    #
    # Production deployment options:
    #   1. Manual: Import ../../modules/nixos/disk-config.nix before installation
    #   2. disko-install: Use `disko-install --flake .#nixos` with automatic disk setup
    #   3. Separate config: Create hosts/nixos/production.nix with disko enabled
    #
    # CI builds fail with disko due to kernel module optimization requiring
    # hardware-specific paths not available in GitHub Actions runners
  ];

  # Minimal filesystem configuration for CI builds
  # Production uses disko (modules/nixos/disk-config.nix) for declarative partitioning
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 42;
      };
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    # Uncomment for AMD GPU
    # initrd.kernelModules = [ "amdgpu" ];
    # Use LTS kernel for CI stability and cache availability
    # NOTE: Explicit kernel package disabled for CI - causes module-shrunk evaluation
    # kernelPackages = pkgs.linuxPackages_6_6;
    kernelModules = [ "uinput" ];
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking = {
    hostName = "nixos"; # Define your hostname.
    useDHCP = false;
    interfaces."eth0".useDHCP = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Turn on flag for proprietary software
  nix = {
    nixPath = [ "nixos-config=/home/${user}/.local/share/src/nixos-config:/etc/nixos" ];
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [
        "@admin"
        "${user}"
      ];
    };

    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Manages keys and such
  programs = {
    gnupg.agent.enable = true;

    # Needed for anything GTK related
    dconf.enable = true;

    # My shell
    zsh.enable = true;
  };

  services = {
    displayManager.defaultSession = "none+bspwm";
    xserver = {
      enable = true;

      # Uncomment these for AMD or Nvidia GPU
      # boot.initrd.kernelModules = [ "amdgpu" ];
      # videoDrivers = [ "amdgpu" ];
      # videoDrivers = [ "nvidia" ];

      # Uncomment for Nvidia GPU
      # This helps fix tearing of windows for Nvidia cards
      # screenSection = ''
      #   Option       "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
      #   Option       "AllowIndirectGLXProtocol" "off"
      #   Option       "TripleBuffer" "on"
      # '';

      displayManager = {
        lightdm = {
          enable = true;
          greeters.slick.enable = true;
          background = ../../modules/nixos/config/login-wallpaper.png;
        };
      };

      # Tiling window manager
      windowManager.bspwm = {
        enable = true;
      };

      xkb = {
        # Turn Caps Lock into Ctrl
        layout = "us";
        options = "ctrl:nocaps";
      };
    };

    # Better support for general peripherals
    libinput.enable = true;

    # Let's be able to SSH into this machine
    openssh.enable = true;

    # Sync state between machines
    syncthing = {
      enable = true;
      openDefaultPorts = true;
      dataDir = "/home/${user}/.local/share/syncthing";
      configDir = "/home/${user}/.config/syncthing";
      user = "${user}";
      group = "users";
      guiAddress = "127.0.0.1:8384";
      overrideFolders = true;
      overrideDevices = true;

      settings = {
        devices = { };
        options.globalAnnounceEnabled = false; # Only sync on LAN
      };
    };

    # Enable CUPS to print documents
    # printing.enable = true;
    # printing.drivers = [ pkgs.brlaser ]; # Brother printer driver

    # Picom, my window compositor with fancy effects
    #
    # Notes on writing exclude rules:
    #
    #   class_g looks up index 1 in WM_CLASS value for an application
    #   class_i looks up index 0
    #
    #   To find the value for a specific application, use `xprop` at the
    #   terminal and then click on a window of the application in question
    #
    picom = {
      enable = true;
      settings = {
        animations = true;
        animation-stiffness = 300.0;
        animation-dampening = 35.0;
        animation-clamping = false;
        animation-mass = 1;
        animation-for-workspace-switch-in = "auto";
        animation-for-workspace-switch-out = "auto";
        animation-for-open-window = "slide-down";
        animation-for-menu-window = "none";
        animation-for-transient-window = "slide-down";
        corner-radius = 12;
        rounded-corners-exclude = [
          "class_i = 'polybar'"
          "class_g = 'i3lock'"
        ];
        round-borders = 3;
        round-borders-exclude = [ ];
        round-borders-rule = [ ];
        shadow = true;
        shadow-radius = 8;
        shadow-opacity = 0.4;
        shadow-offset-x = -8;
        shadow-offset-y = -8;
        fading = false;
        inactive-opacity = 0.8;
        frame-opacity = 0.7;
        inactive-opacity-override = false;
        active-opacity = 1.0;
        focus-exclude = [
        ];

        opacity-rule = [
          "100:class_g = 'i3lock'"
          "60:class_g = 'Dunst'"
          "100:class_g = 'Alacritty' && focused"
          "90:class_g = 'Alacritty' && !focused"
        ];

        blur-kern = "3x3box";
        blur = {
          method = "kernel";
          strength = 8;
          background = false;
          background-frame = false;
          background-fixed = false;
          kern = "3x3box";
        };

        shadow-exclude = [
          "class_g = 'Dunst'"
        ];

        blur-background-exclude = [
          "class_g = 'Dunst'"
        ];

        backend = "glx";
        vsync = false;
        mark-wmwin-focused = true;
        mark-ovredir-focused = true;
        detect-rounded-corners = true;
        detect-client-opacity = false;
        detect-transient = true;
        detect-client-leader = true;
        use-damage = true;
        log-level = "info";

        wintypes = {
          normal = {
            fade = true;
            shadow = false;
          };
          tooltip = {
            fade = true;
            shadow = false;
            opacity = 0.75;
            focus = true;
            full-shadow = false;
          };
          dock = {
            shadow = false;
          };
          dnd = {
            shadow = false;
          };
          popup_menu = {
            opacity = 1.0;
          };
          dropdown_menu = {
            opacity = 1.0;
          };
        };
      };
    };

    gvfs.enable = true; # Mount, trash, and other functionalities
    tumbler.enable = true; # Thumbnail support for images

  };

  # VSCode Remote Tunnel Service
  # Systemd user service that auto-downloads and runs VSCode CLI tunnel daemon
  # Enables remote development via VS Code's Remote-Tunnels extension
  systemd.user.services.vscode-tunnel = {
    description = "VSCode Remote Tunnel Service";
    after = [ "network-online.target" ]; # Wait for network before starting
    wants = [ "network-online.target" ];
    wantedBy = [ "default.target" ]; # Auto-start on user login

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure"; # Auto-restart if crashed
      RestartSec = "5"; # Wait 5s before restart
      StartLimitBurst = 3; # Max 3 restart attempts
      StartLimitIntervalSec = 300; # Within 5 minutes

      # Security settings
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = false; # VSCode needs access to home directory

      # Working directory and environment
      WorkingDirectory = "/home/${user}";
      Environment = [
        "PATH=/run/current-system/sw/bin:/home/${user}/.nix-profile/bin"
        "XDG_CONFIG_HOME=/home/${user}/.config"
        "XDG_DATA_HOME=/home/${user}/.local/share"
      ];

      # Pre-start: Download VSCode CLI if missing or invalid
      # Uses Microsoft's official CDN with retry logic for reliability
      ExecStartPre = "${pkgs.writeShellScript "vscode-tunnel-download" ''
        set -euo pipefail

        CLI_DIR="$HOME/.vscode-server/cli"
        CLI_PATH="$CLI_DIR/code"
        ARCH="linux-x64"

        # Ensure CLI directory exists
        mkdir -p "$CLI_DIR"

        # Download VSCode CLI if not present or not executable
        if [[ ! -f "$CLI_PATH" ]] || [[ ! -x "$CLI_PATH" ]]; then
          echo "[INFO] Downloading VSCode CLI..."

          # Official Microsoft CDN URL for stable VSCode CLI
          DOWNLOAD_URL="https://update.code.visualstudio.com/commit/stable/cli-alpine-$ARCH/stable"

          # Retry download up to 3 times with 2s delay between attempts
          for attempt in {1..3}; do
            if curl -fsSL "$DOWNLOAD_URL" -o "$CLI_PATH.tmp"; then
              mv "$CLI_PATH.tmp" "$CLI_PATH"
              chmod +x "$CLI_PATH"
              echo "[INFO] VSCode CLI downloaded successfully"
              break
            else
              echo "[WARN] Download attempt $attempt failed"
              [[ $attempt -eq 3 ]] && exit 1  # Fail on 3rd attempt
              sleep 2
            fi
          done
        fi

        # Verify CLI binary works before starting service
        if ! "$CLI_PATH" --version >/dev/null 2>&1; then
          echo "[ERROR] VSCode CLI verification failed"
          rm -f "$CLI_PATH"  # Remove corrupted binary
          exit 1
        fi

        echo "[INFO] VSCode CLI ready: $("$CLI_PATH" --version)"
      ''}";

      ExecStart = "${pkgs.writeShellScript "vscode-tunnel-start" ''
        set -euo pipefail

        CLI_PATH="$HOME/.vscode-server/cli/code"

        echo "[INFO] Starting VSCode Remote Tunnel..."
        echo "[INFO] VSCode CLI version: $("$CLI_PATH" --version)"

        # Start tunnel with structured logging
        exec "$CLI_PATH" tunnel --accept-server-license-terms --log trace
      ''}";

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "vscode-tunnel";
    };
  };

  # Enable sound
  # sound.enable = true;

  # Video support
  hardware = {
    graphics.enable = true;
    # pulseaudio.enable = true;
    # hardware.nvidia.modesetting.enable = true;

    # Enable Xbox support
    # hardware.xone.enable = true;

    # Crypto wallet support
    ledger.enable = true;
  };

  # Add docker daemon
  virtualisation = {
    docker = {
      enable = true;
      logDriver = "json-file";
    };
  };

  # It's me, it's you, it's everyone
  users.users = {
    ${user} = {
      isNormalUser = true;
      group = "users";
      extraGroups = [
        "wheel" # Enable 'sudo' for the user.
        "docker"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
    };

    root = {
      openssh.authorizedKeys.keys = keys;
    };
  };

  fonts.packages = with pkgs; [
    dejavu_fonts
    jetbrains-mono
    font-awesome
    noto-fonts
    noto-fonts-emoji
  ];

  environment.systemPackages =
    with pkgs;
    [
      git
      inetutils
      # VSCode tunnel client command
      (writeShellScriptBin "code" ''
        # VSCode Remote Tunnel client command
        # Routes to local VSCode tunnel when available

        CLI_PATH="$HOME/.vscode-server/cli/code"

        if [[ -x "$CLI_PATH" ]]; then
          # Use tunnel CLI if available
          exec "$CLI_PATH" "$@"
        else
          echo "VSCode Remote Tunnel not available. Ensure vscode-tunnel service is running."
          echo "Start with: systemctl --user start vscode-tunnel"
          exit 1
        fi
      '')
    ]
    ++ (import ../../modules/shared/packages.nix { inherit pkgs; });

  system.stateVersion = "21.05"; # Don't change this

}
