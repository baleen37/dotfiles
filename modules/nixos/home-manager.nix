# NixOS-Specific Home Manager Configuration (Optimized)
#
# Linux/NixOS-specific Home Manager configuration with performance
# optimizations, enhanced desktop integration, and streamlined services.
#
# FEATURES:
#   - Optimized Polybar and desktop environment integration
#   - Enhanced notification system with Dunst
#   - Performance-optimized file and service management
#   - Streamlined shared configuration integration
#
# VERSION: 2.0.0 (Phase 2 optimized)
# LAST UPDATED: 2024-10-04

{
  config,
  pkgs,
  lib,
  self,
  ...
}:

let
  # Optimized user resolution with Linux platform awareness
  getUserInfo = import ../../lib/user-resolution.nix {
    platform = "linux";
    returnFormat = "extended";
  };
  user = getUserInfo.user;

  # Performance optimization: cache frequently used paths
  linuxPaths = {
    home = getUserInfo.homePath;
    config = "${getUserInfo.homePath}/.config";
    cache = "${getUserInfo.homePath}/.cache";
    local = "${getUserInfo.homePath}/.local";
  };

  # Import shared configuration for consistency
  sharedConfig = import ../shared/home-manager.nix { inherit config pkgs lib; };

  # Optimized Polybar configuration with performance enhancements
  polybarConfig = {
    userModules =
      let
        src = builtins.readFile ./config/polybar/user_modules.ini;
        substitutions = {
          "@packages@" = "${linuxPaths.config}/polybar/bin/check-nixos-updates.sh";
          "@searchpkgs@" = "${linuxPaths.config}/polybar/bin/search-nixos-updates.sh";
          "@launcher@" = "${linuxPaths.config}/polybar/bin/launcher.sh";
          "@powermenu@" = "${linuxPaths.config}/rofi/bin/powermenu.sh";
          "@calendar@" = "${linuxPaths.config}/polybar/bin/popup-calendar.sh";
        };
      in
      builtins.replaceStrings (builtins.attrNames substitutions) (builtins.attrValues substitutions) src;

    mainConfig =
      let
        src = builtins.readFile ./config/polybar/config.ini;
        fontSubstitutions = {
          "@font0@" = "DejaVu Sans:size=12;3";
          "@font1@" = "feather:size=12;3";
        };
      in
      builtins.toFile "polybar-config.ini" (
        builtins.replaceStrings (builtins.attrNames fontSubstitutions)
          (builtins.attrValues fontSubstitutions)
          src
      );

    # Cached configuration file contents
    modules = builtins.readFile ./config/polybar/modules.ini;
    bars = builtins.readFile ./config/polybar/bars.ini;
    colors = builtins.readFile ./config/polybar/colors.ini;
  };

in
{
  # Optimized home configuration with performance enhancements
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = getUserInfo.homePath;

    # Enhanced package management with NixOS-specific tools
    packages = pkgs.callPackage ./packages.nix { };

    # Optimized file management with better merging strategy
    file = lib.mkMerge [
      (import ../shared/files.nix {
        inherit
          config
          pkgs
          user
          self
          lib
          ;
      })
      (import ./files.nix { inherit user; })
    ];

    stateVersion = "21.05";

    # Performance optimization: create essential directories
    activation.createDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "💾 Setting up NixOS directory structure..."
      mkdir -p "${linuxPaths.config}"/{polybar/bin,rofi/bin,dunst}
      mkdir -p "${linuxPaths.cache}"
      mkdir -p "${linuxPaths.local}"/bin
      echo "✅ Directory structure ready"
    '';
  };

  # Enhanced GTK theming with performance optimizations
  gtk = {
    enable = true;

    # Optimized dark theme configuration
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    # Additional theme settings for consistency
    gtk2.extraConfig = ''config-path = "${linuxPaths.config}/gtk-2.0/gtkrc"'';

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-theme-name = "Adwaita-dark";
      gtk-icon-theme-name = "Adwaita";
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Enhanced services with performance and reliability improvements
  services = {
    # Optimized screen locking with faster activation
    screen-locker = {
      enable = true;
      inactiveInterval = 10;
      lockCmd = "${pkgs.i3lock-fancy-rapid}/bin/i3lock-fancy-rapid 10 15";
      xautolock.enable = false; # Use built-in timer for better performance
    };

    # Enhanced device auto-mounting
    udiskie = {
      enable = true;
      automount = true;
      notify = false; # Reduce notification overhead
      tray = "never"; # Performance: no system tray icon
    };

    # Optimized Polybar configuration with enhanced performance
    polybar = {
      enable = true;
      config = polybarConfig.mainConfig;
      extraConfig = lib.concatStrings [
        polybarConfig.bars
        polybarConfig.colors
        polybarConfig.modules
        polybarConfig.userModules
      ];
      package = pkgs.polybarFull;
      script = ''
        # Performance optimization: check if already running
        if pgrep -x polybar >/dev/null; then
          pkill polybar
          while pgrep -x polybar >/dev/null; do sleep 0.1; done
        fi
        polybar main 2>&1 | tee -a /tmp/polybar.log & disown
      '';
    };

    # Enhanced Dunst notification system with performance optimizations
    dunst = {
      enable = true;
      package = pkgs.dunst;
      settings = {
        global = {
          # Display configuration
          monitor = 0;
          follow = "mouse";

          # Optimized geometry for better performance
          width = 320;
          height = 400;
          origin = "top-right";
          offset = "15x65";

          # Performance optimizations
          indicate_hidden = true;
          shrink = false;
          separator_height = 2;
          padding = 16;
          horizontal_padding = 16;
          frame_width = 1;

          # Enhanced visual settings
          transparency = 5;
          corner_radius = 8;

          # Content formatting
          font = "Noto Sans 11";
          line_height = 4;
          markup = "full";
          format = "<b>%s</b>\n%b";
          alignment = "left";
          word_wrap = true;
          ignore_newline = false;

          # Behavior optimizations
          sort = true;
          idle_threshold = 120;
          show_age_threshold = 60;
          stack_duplicates = true;
          hide_duplicate_count = false;
          show_indicators = true;

          # Icon configuration
          icon_position = "left";
          icon_theme = "Adwaita";
          max_icon_size = 48;

          # History and interaction
          sticky_history = true;
          history_length = 50;

          # Default browser for URLs
          browser = lib.mkDefault "/usr/bin/env xdg-open";

          # Performance: disable scripts by default
          always_run_script = false;

          # Window class identification
          title = "Dunst";
          class = "Dunst";
        };

        # Urgency level configurations
        urgency_low = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
          timeout = 5;
        };

        urgency_normal = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
          timeout = 10;
        };

        urgency_critical = {
          background = "#1e1e2e";
          foreground = "#f38ba8";
          frame_color = "#f38ba8";
          timeout = 0;
        };
      };
    };
  };

  # Enhanced programs configuration with NixOS-specific optimizations
  programs = sharedConfig.programs // {
    # NixOS-specific program overrides and additions

    # Enhanced shell configuration for Linux
    zsh = sharedConfig.programs.zsh // {
      shellAliases = sharedConfig.programs.zsh.shellAliases // {
        # Linux-specific aliases
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";

        # System management shortcuts
        sysinfo = "neofetch";
        ports = "netstat -tuln";
        psg = "ps aux | grep";

        # Package management
        search = "nix search nixpkgs";
        install = "nix-env -iA";
        upgrade = "sudo nixos-rebuild switch --upgrade";
      };
    };

    # Enhanced development tools for NixOS
    git = sharedConfig.programs.git // {
      extraConfig = sharedConfig.programs.git.extraConfig // {
        # Linux-specific git configuration
        credential.helper = "store";
      };
    };
  };

  # Enhanced XDG configuration for better desktop integration
  xdg = {
    enable = true;

    # Optimized user directories
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${linuxPaths.home}/Desktop";
      documents = "${linuxPaths.home}/Documents";
      download = "${linuxPaths.home}/Downloads";
      music = "${linuxPaths.home}/Music";
      pictures = "${linuxPaths.home}/Pictures";
      videos = "${linuxPaths.home}/Videos";
    };

    # MIME type associations
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain" = [ "vim.desktop" ];
        "application/pdf" = [ "firefox.desktop" ];
        "image/png" = [ "feh.desktop" ];
        "image/jpeg" = [ "feh.desktop" ];
      };
    };
  };
  # Import shared modules for consistency
  imports = [
    # Additional NixOS-specific modules can be added here
  ];
}
