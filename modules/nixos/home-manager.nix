{ config, pkgs, lib, self, ... }:

let
  # Resolve user with platform information
  getUserInfo = import ../../lib/user-resolution.nix {
    platform = "linux";
    returnFormat = "extended";
  };
  user = getUserInfo.user;
  xdg_configHome = "${getUserInfo.homePath}/.config";
  shared-programs = import ../shared/home-manager.nix { inherit config pkgs lib; };

  polybar-user_modules =
    let
      src = builtins.readFile ./config/polybar/user_modules.ini;
      from = [
        "@packages@"
        "@searchpkgs@"
        "@launcher@"
        "@powermenu@"
        "@calendar@"
      ];
      to = [
        "${xdg_configHome}/polybar/bin/check-nixos-updates.sh"
        "${xdg_configHome}/polybar/bin/search-nixos-updates.sh"
        "${xdg_configHome}/polybar/bin/launcher.sh"
        "${xdg_configHome}/rofi/bin/powermenu.sh"
        "${xdg_configHome}/polybar/bin/popup-calendar.sh"
      ];
    in
    builtins.replaceStrings from to src;

  polybar-config =
    let
      src = builtins.readFile ./config/polybar/config.ini;
      text = builtins.replaceStrings [ "@font0@" "@font1@" ] [ "DejaVu Sans:size=12;3" "feather:size=12;3" ] src;
    in
    builtins.toFile "polybar-config.ini" text;

  polybar-modules = builtins.readFile ./config/polybar/modules.ini;
  polybar-bars = builtins.readFile ./config/polybar/bars.ini;
  polybar-colors = builtins.readFile ./config/polybar/colors.ini;

in
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = getUserInfo.homePath;
    packages = pkgs.callPackage ./packages.nix { };
    file = (import ../shared/files.nix { inherit config pkgs user self lib; }) // import ./files.nix { inherit user; };
    stateVersion = "21.05";
  };

  # Use a dark theme
  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
  };

  # Screen lock
  services = {
    screen-locker = {
      enable = true;
      inactiveInterval = 10;
      lockCmd = "${pkgs.i3lock-fancy-rapid}/bin/i3lock-fancy-rapid 10 15";
    };

    # Auto mount devices
    udiskie.enable = true;

    polybar = {
      enable = true;
      config = polybar-config;
      extraConfig = polybar-bars + polybar-colors + polybar-modules + polybar-user_modules;
      package = pkgs.polybarFull;
      script = "polybar main &";
    };

    dunst = {
      enable = true;
      package = pkgs.dunst;
      settings = {
        global = {
          monitor = 0;
          follow = "mouse";
          border = 0;
          height = 400;
          width = 320;
          offset = "33x65";
          indicate_hidden = "yes";
          shrink = "no";
          separator_height = 0;
          padding = 32;
          horizontal_padding = 32;
          frame_width = 0;
          sort = "no";
          idle_threshold = 120;
          font = "Noto Sans";
          line_height = 4;
          markup = "full";
          format = "<b>%s</b>\n%b";
          alignment = "left";
          transparency = 10;
          show_age_threshold = 60;
          word_wrap = "yes";
          ignore_newline = "no";
          stack_duplicates = false;
          hide_duplicate_count = "yes";
          show_indicators = "no";
          icon_position = "left";
          icon_theme = "Adwaita-dark";
          sticky_history = "yes";
          history_length = 20;
          history = "ctrl+grave";
          browser = "google-chrome-stable";
          always_run_script = true;
          title = "Dunst";
          class = "Dunst";
          max_icon_size = 64;
        };
      };
    };
  };

  programs = shared-programs // { };

  # Smart Claude config files management with user modification preservation
  # Same as Darwin implementation for platform consistency
  home.activation.copyClaudeFiles = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    import ../shared/lib/claude-activation.nix { inherit config lib self; platform = "nixos"; }
  );

}
