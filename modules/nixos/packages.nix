{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [

  # Security and authentication
  yubikey-agent
  keepassxc

  # App and package management
  appimage-run
  gnumake
  cmake
  home-manager

  # Media and design tools
  vlc
  fontconfig
  font-manager

  # Productivity tools
  bc # old school calculator
  galculator

  # Audio tools
  pavucontrol # Pulse audio controls

  # Testing and development tools
  rofi
  rofi-calc
  postgresql
  libnotify
  pcmanfm # File browser
  sqlite
  xdg-utils

  # Other utilities
  yad # yad-calendar is used with polybar
  xdotool
  google-chrome

  # PDF viewer
  zathura

  # Music and entertainment
  spotify
]
