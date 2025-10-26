# NixOS System Configuration
#
# Consolidated NixOS system settings including disk configuration,
# desktop environment, services, and platform-specific packages.
# This file combines all NixOS-specific configurations from modules/nixos/*.
#
# COMPONENTS:
#   - Disk Configuration: Disko-based partitioning with systemd-boot
#   - Desktop Environment: bspwm window manager, polybar, rofi, theming
#   - System Services: Home Manager, user services, auto-mounting
#   - Packages: Linux-specific desktop and development tools
#
# ARCHITECTURE: Mitchell-style flat configuration - all NixOS settings in one file

{
  config,
  pkgs,
  lib,
  ...
}:

let
  user = "baleen";
  homeDir = "/home/${user}";
  xdg_configHome = "${homeDir}/.config";

  # Desktop environment files configuration
  desktopFiles = {
    # bspwm window manager configuration
    "${xdg_configHome}/bspwm/bspwmrc" = {
      executable = true;
      text = ''
        #! /bin/sh
        #
        # Set the number of workspaces
        bspc monitor -d 1 2 3 4 5 6

        # Launch keybindings daemon
        pgrep -x sxhkd > /dev/null || sxhkd &

        # Window configurations
        bspc config border_width         0
        bspc config window_gap          16
        bspc config split_ratio          0.52
        bspc config borderless_monocle   true
        bspc config gapless_monocle      true

        # Padding outside of the window
        bspc config top_padding            60
        bspc config bottom_padding         60
        bspc config left_padding           60
        bspc config right_padding          60

        # Move floating windows
        bspc config pointer_action1 move

        # Resize floating windows
        bspc config pointer_action2 resize_side
        bspc config pointer_action2 resize_corner

        # Set background and top bar
        systemctl --user start polybar

        sleep .25

        # Wait for the network to be up
        notify-send 'Waiting for network...'
        while ! systemctl is-active --quiet network-online.target; do sleep 1; done
        notify-send 'Network found.'
      '';
    };

    # sxhkd hotkey daemon configuration
    "${xdg_configHome}/sxhkd/sxhkdrc" = {
      text = ''
        # Close window
        alt + F4
              bspc node --close

        # Make split ratios equal
        super + equal
              bspc node @/ --equalize

        # Make split ratios balanced
        super + minus
              bspc node @/ --balance

        # Toogle tiling of window
        super + d
              bspc query --nodes -n focused.tiled && state=floating || state=tiled; \
              bspc node --state ~$state

        # Toggle fullscreen of window
        super + f
              bspc node --state ~fullscreen

        # Swap the current node and the biggest window
        super + g
              bspc node -s biggest.window

        # Swap the current node and the smallest window
        super + shift + g
              bspc node -s biggest.window

        # Alternate between the tiled and monocle layout
        super + m
              bspc desktop -l next

        # Move between windows in monocle layout
        super + {_, alt + }m
              bspc node -f {next, prev}.local.!hidden.window

        # Focus the node in the given direction
        super + {_,shift + }{h,j,k,l}
              bspc node -{f,s} {west,south,north,east}

        # Focus left/right occupied desktop
        super + {Left,Right}
              bspc desktop --focus {prev,next}.occupied

        # Focus left/right occupied desktop
        super + {Up,Down}
              bspc desktop --focus {prev,next}.occupied

        # Focus left/right desktop
        ctrl + alt + {Left,Right}
              bspc desktop --focus {prev,next}

        # Focus left/right desktop
        ctrl + alt + {Up, Down}
              bspc desktop --focus {prev,next}

        # Focus the older or newer node in the focus history
        super + {o,i}
              bspc wm -h off; \
              bspc node {older,newer} -f; \
              bspc wm -h on

        # Focus or send to the given desktop
        super + {_,shift + }{1-9,0}
              bspc {desktop -f,node -d} '^{1-9,10}'

        # Preselect the direction
        super + alt + {h,j,k,l}
              bspc node -p {west,south,north,east}

        # Cancel the preselect
        # For context on syntax: https://github.com/baskerville/bspwm/issues/344
        super + alt + {_,shift + }Escape
              bspc query -N -d | xargs -I id -n 1 bspc node id -p cancel

        # Preselect the direction
        super + ctrl + {h,j,k,l}
              bspc node -p {west,south,north,east}

        # Cancel the preselect
        # For context on syntax: https://github.com/baskerville/bspwm/issues/344
        super + ctrl + {_,shift + }Escape
              bspc query -N -d | xargs -I id -n 1 bspc node id -p cancel

        # Set the node flags
        super + ctrl + {m,x,s,p}
              bspc node -g {marked,locked,sticky,private}

        # Send the newest marked node to the newest preselected node
        super + y
              bspc node newest.marked.local -n newest.!automatic.local

        # Program launcher
        super + @space
              rofi -config -no-lazy-grab -show drun -modi drun -theme /home/${user}/.config/rofi/launcher.rasi

        # Terminal emulator
        super + Return
              bspc rule -a Alacritty -o state=floating rectangle=1024x768x0x0 center=true && /etc/profiles/per-user/${user}/bin/alacritty

        # Terminal emulator
        super + ctrl + Return
              /etc/profiles/per-user/${user}/bin/alacritty

        # Jump to workspaces
        super + t
              bspc desktop --focus ^2
        super + b
              bspc desktop --focus ^1
        super + w
              bspc desktop --focus ^4
        super + Tab
              bspc {node,desktop} -f last

        # Keepass XC
        super + shift + x
              /etc/profiles/per-user/${user}/bin/keepassxc

        # Web browser
        ctrl + alt + Return
             google-chrome-stable

        # File browser at home dir
        super + shift + @space
             pcmanfm

        # Take a screenshot with PrintSc
        Print
             flameshot gui -c -p $HOME/.local/share/img/screenshots

        # Lock the screen
        ctrl + alt + BackSpace
             i3lock

        # Audio controls for + volume
        XF86AudioRaiseVolume
            pactl set-sink-volume @DEFAULT_SINK@ +5%

        # Audio controls for - volume
        XF86AudioLowerVolume
            pactl set-sink-volume @DEFAULT_SINK@ -5%

        # Audio controls for mute
        XF86AudioMute
            pactl set-sink-mute @DEFAULT_SINK@ toggle
      '';
    };

    # Polybar calendar popup script
    "${xdg_configHome}/polybar/bin/popup-calendar.sh" = {
      executable = true;
      text = ''
        #!/bin/sh

        DATE="$(/run/current-system/sw/bin/date +"%B %d, %Y")"
        SCREEN_WIDTH=$(/run/current-system/sw/bin/xrandr | /run/current-system/sw/bin/grep '*' | /run/current-system/sw/bin/awk '{print $1}' | /run/current-system/sw/bin/cut -d 'x' -f1)
        POSX=$(( (SCREEN_WIDTH / 2) - ((SCREEN_WIDTH / 2 * 625) / 10000) ))

        case "$1" in
        --popup)
            /etc/profiles/per-user/${user}/bin/yad --calendar --fixed \
              --posx=$POSX --posy=80 --no-buttons --borders=0 --title="yad-calendar" \
              --close-on-unfocus
          ;;
        *)
            echo "$DATE"
          ;;
        esac
      '';
    };

    # Polybar update checker script
    "${xdg_configHome}/polybar/bin/check-nixos-updates.sh" = {
      executable = true;
      text = ''
        #!/bin/sh

        /run/current-system/sw/bin/git -C ~/.local/share/src/nixpkgs fetch upstream master
        UPDATES=$(/run/current-system/sw/bin/git -C ~/.local/share/src/nixpkgs rev-list origin/master..upstream/master --count 2>/dev/null);
        /run/current-system/sw/bin/echo " $UPDATES"; # Extra space for presentation with icon
        /run/current-system/sw/bin/sleep 1800;
      '';
    };

    # Polybar package search script
    "${xdg_configHome}/polybar/bin/search-nixos-updates.sh" = {
      executable = true;
      text = ''
        #!/bin/sh

        /etc/profiles/per-user/${user}/bin/google-chrome-stable --new-window "https://search.nixos.org/packages"
      '';
    };

    # Rofi launcher script
    "${xdg_configHome}/rofi/bin/launcher.sh" = {
      executable = true;
      text = ''
        #!/bin/sh

        rofi -no-config -no-lazy-grab -show drun -modi drun -theme ${xdg_configHome}/rofi/launcher.rasi
      '';
    };

    # Rofi power menu script
    "${xdg_configHome}/rofi/bin/powermenu.sh" = {
      executable = true;
      text = ''
              #!/bin/sh

              configDir="${xdg_configHome}/rofi"
              uptime=$(uptime -p | sed -e 's/up //g')
              rofi_command="rofi -no-config -theme $configDir/powermenu.rasi"

              # Options
              shutdown=" Shutdown"
              reboot=" Restart"
              lock=" Lock"
              suspend=" Sleep"
              logout=" Logout"

              # Confirmation
              confirm_exit() {
        	      rofi -dmenu\
                      -no-config\
        		      -i\
        		      -no-fixed-num-lines\
        		      -p "Are You Sure? : "\
        		      -theme $configDir/confirm.rasi
              }

              # Message
              msg() {
        	      rofi -no-config -theme "$configDir/message.rasi" -e "Available Options  -  yes / y / no / n"
              }

              # Variable passed to rofi
              options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"
              chosen="$(echo -e "$options" | $rofi_command -p "Uptime: $uptime" -dmenu -selected-row 0)"
              case $chosen in
                  $shutdown)
        		      ans=$(confirm_exit &)
        		      if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
        			      systemctl poweroff
        		      elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
        			      exit 0
                      else
        			      msg
                      fi
                      ;;
                  $reboot)
        		      ans=$(confirm_exit &)
        		      if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
        			      systemctl reboot
        		      elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
        			      exit 0
                      else
        			      msg
                      fi
                      ;;
                  $lock)
                  betterlockscreen -l
                      ;;
                  $suspend)
        		      ans=$(confirm_exit &)
        		      if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
        			      mpc -q pause
        			      amixer set Master mute
        			      systemctl suspend
        		      elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
        			      exit 0
                      else
        			      msg
                      fi
                      ;;
                  $logout)
        		      ans=$(confirm_exit &)
        		      if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
        			      bspc quit
        		      elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
        			      exit 0
                      else
        			      msg
                      fi
                      ;;
              esac
      '';
    };
  };

  # NixOS-specific packages (Linux desktop and development tools)
  nixosPackages = with pkgs; [
    # Linux-specific app management
    appimage-run

    # Linux desktop productivity tools
    galculator

    # Linux audio tools
    pavucontrol # Pulse audio controls

    # Linux media tools
    vlc # Cross-platform media player (Linux only)
    font-manager # Font management application (Linux only)

    # Linux desktop and window management tools
    rofi
    rofi-calc
    libnotify
    pcmanfm # File browser
    xdg-utils

    # Linux desktop utilities
    yad # yad-calendar is used with polybar
    xdotool

    # PDF viewer (Linux-focused, though available on other platforms)
    zathura
  ];

in
{
  # System configuration
  system.stateVersion = "23.11";

  # Disk configuration using Disko
  disko.devices = lib.mkDefault {
    disk = {
      vdb = {
        device = "/dev/%DISK%";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "100M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };

  # Boot loader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking configuration
  networking.networkmanager.enable = true;

  # Time zone and internationalization
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # X11 windowing system
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "";

  # Display manager
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = false;

  # Window manager
  services.xserver.windowManager.bspwm.enable = true;
  services.xserver.windowManager.bspwm.package = pkgs.bspwm;

  # Desktop environment services
  services.xserver.desktopManager.xterm.enable = false;

  # System packages
  environment.systemPackages =
    with pkgs;
    [
      # Essential system tools
      vim
      git
      wget
      curl

      # Desktop environment
      bspwm
      sxhkd
      polybar
      polybarFull
      dunst
      rofi
      rofi-calc
      libnotify
      pcmanfm
      xdg-utils

      # Theming
      gnome-themes-extra
      adwaita-icon-theme

      # Screen locking
      i3lock-fancy-rapid

      # Audio
      pulseaudio
      pavucontrol

      # Development tools
      alacritty

      # Media
      vlc

      # Utilities
      yad
      xdotool
      flameshot
      zathura
      font-manager
      appimage-run
      galculator
    ]
    ++ nixosPackages;

  # Sound configuration handled in services section below

  # User configuration
  users.users.${user} = {
    isNormalUser = true;
    description = "Baleen";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "input"
    ];
    shell = pkgs.zsh;
  };

  # Shell configuration
  programs.zsh.enable = true;

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user} = {
      home.stateVersion = "24.05";

      # Home directory files
      home.file = desktopFiles;

      # Packages
      home.packages = nixosPackages;

      # GTK theming
      gtk = {
        enable = true;
        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome-themes-extra;
        };
        iconTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-theme-name = "Adwaita-dark";
          gtk-icon-theme-name = "Adwaita";
        };
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
      };

      # Services
      services = {
        # Screen locking
        screen-locker = {
          enable = true;
          inactiveInterval = 10;
          lockCmd = "${pkgs.i3lock-fancy-rapid}/bin/i3lock-fancy-rapid 10 15";
          xautolock.enable = false;
        };

        # Device auto-mounting
        udiskie = {
          enable = true;
          automount = true;
          notify = false;
          tray = "never";
        };

        # Dunst notifications
        dunst = {
          enable = true;
          package = pkgs.dunst;
          settings = {
            global = {
              monitor = 0;
              follow = "mouse";
              width = 320;
              height = 400;
              origin = "top-right";
              offset = "15x65";
              indicate_hidden = true;
              shrink = false;
              separator_height = 2;
              padding = 16;
              horizontal_padding = 16;
              frame_width = 1;
              transparency = 5;
              corner_radius = 8;
              font = "Noto Sans 11";
              line_height = 4;
              markup = "full";
              format = "<b>%s</b>\n%b";
              alignment = "left";
              word_wrap = true;
              ignore_newline = false;
              sort = true;
              idle_threshold = 120;
              show_age_threshold = 60;
              stack_duplicates = true;
              hide_duplicate_count = false;
              show_indicators = true;
              icon_position = "left";
              icon_theme = "Adwaita";
              max_icon_size = 48;
              sticky_history = true;
              history_length = 50;
              browser = lib.mkDefault "/usr/bin/env xdg-open";
              always_run_script = false;
              title = "Dunst";
              class = "Dunst";
            };

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

      # Programs configuration
      programs = {
        # Shell aliases for Linux
        zsh.shellAliases = {
          ll = "ls -alF";
          la = "ls -A";
          l = "ls -CF";
          sysinfo = "neofetch";
          ports = "netstat -tuln";
          psg = "ps aux | grep";
          search = "nix search nixpkgs";
          install = "nix-env -iA";
          upgrade = "sudo nixos-rebuild switch --upgrade";
        };

        # Git configuration
        git.settings = {
          credential.helper = "store";
        };
      };

      # XDG configuration
      xdg = {
        enable = true;
        userDirs = {
          enable = true;
          createDirectories = true;
          desktop = "${homeDir}/Desktop";
          documents = "${homeDir}/Documents";
          download = "${homeDir}/Downloads";
          music = "${homeDir}/Music";
          pictures = "${homeDir}/Pictures";
          videos = "${homeDir}/Videos";
        };
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

      # Activation script
      home.activation.createDirectories = ''
        echo "Setting up NixOS directory structure..."
        mkdir -p "${xdg_configHome}"/{polybar/bin,rofi/bin,dunst}
        mkdir -p "${homeDir}/.cache"
        mkdir -p "${homeDir}/.local"/bin
      '';
    };
  };

  # System services
  services = {
    # Enable printing
    printing.enable = true;

    # Enable sound
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  # Hardware configuration
  hardware = {
    # Enable OpenGL
    graphics.enable = true;

    # Enable Bluetooth
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
  };

  # System settings
  system = {
    # Auto upgrade
    autoUpgrade.enable = false;

    # Automatic garbage collection
    activationScripts = {
      # Custom activation scripts can be added here
    };
  };

  # Nix settings
  nix = {
    settings = {
      # Enable flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Automatic garbage collection
      auto-optimise-store = true;
    };

    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Security settings
  security = {
    # sudo configuration
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  # Virtualization
  virtualisation = {
    # Docker support
    docker.enable = false; # Can be enabled as needed
  };

  # Environment variables
  environment.variables = {
    EDITOR = "vim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";
  };

  # Fonts
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      dejavu_fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
    ];
  };
}
