# Homebrew Configuration
#
# GUI applications and Mac App Store apps managed via Homebrew.
# Casks, taps, and MAS apps.

{ config, lib, ... }:

let
  cfg = config.homebrew;
  bundleCmd = cfg.onActivation.brewBundleCmd { onlyCheck = false; };
  # The command embeds the Brewfile's store path and every flag, so its hash
  # changes whenever there is anything new for `brew bundle` to do.
  bundleKey = builtins.hashString "sha256" bundleCmd;
  bundleStamp = "${config.users.users.${cfg.user}.home}/.cache/nix-darwin/brew-bundle";
  # Homebrew Cask definitions (GUI applications)
  homebrew-casks = [
    # Development Tools
    "herdr-app" # Herdr desktop app for terminals and coding agents
    "visual-studio-code" # Code editor (not via nix: store-path launches stamp com.apple.macl and block GC)

    # Fonts
    "font-jetbrains-mono" # JetBrains Mono font for terminal

    # Communication Tools
    "notion"
    "slack"
    "obsidian"

    # Utility Tools
    "claude"
    "karabiner-elements" # Key remapping and modification tool
    "Sanyam-G/switch/switch" # Keyboard-driven window switcher
    "orbstack" # Docker and Linux VM management
    "tailscale-app" # VPN mesh network with GUI

    # Productivity Tools
    "raycast"

    # Password Management
    "1password"
    "1password-cli"

    # Browsers
    "google-chrome"
    "brave-browser"

    "hammerspoon"
  ];
in
{
  # Optimized Homebrew setup for development workflow with performance considerations
  homebrew = {
    enable = true;
    casks = homebrew-casks;

    # Performance Optimization: Selective Cleanup Strategy
    # Prevents unexpected interruptions during development while maintaining system hygiene
    onActivation = {
      autoUpdate = false; # Manual updates for predictability and control
      upgrade = false; # Avoid automatic upgrades during system rebuilds
      # cleanup = "uninstall";  # Commented for safety during development - enable when needed
    };

    # Optimized Global Homebrew Settings
    # Enhances package management efficiency and dependency tracking
    global = {
      brewfile = true; # Enable Brewfile support for reproducible setups
    };

    # Mac App Store Applications (Optimized Metadata)
    # Carefully selected apps for development productivity and system management
    # IDs obtained via: nix shell nixpkgs#mas && mas search <app name>
    masApps = {
      "KakaoTalk" = 869223134; # Communication platform (if needed)
    };

    # mas discovers installed App Store apps through Spotlight. Keep existing
    # apps out of `brew bundle` while Spotlight is being enabled or rebuilt.
    extraConfig = ''
      masSkip = [
        ("869223134" if File.directory?("/Applications/KakaoTalk.app")),
      ].compact
      ENV["HOMEBREW_BUNDLE_MAS_SKIP"] = [ENV["HOMEBREW_BUNDLE_MAS_SKIP"], *masSkip].compact.join(" ")
    '';

    # Extended Package Repository Access
    # Additional Homebrew taps for specialized packages and development tools
    # Note: homebrew/cask is now built into Homebrew by default (since 2023)
    taps = [
      # switch window switcher. Homebrew 6 ignores casks from an untrusted tap.
      {
        name = "Sanyam-G/switch";
        trusted = true;
      }
    ];
  };

  # nix-darwin runs `brew bundle` on every activation, which costs 5-15s even
  # when nothing changed. Skip it while the bundle command is the one last
  # applied. Removing the stamp forces a run, e.g. after uninstalling an app by
  # hand. Replaces nix-darwin's script, so keep it in step with
  # system.activationScripts.homebrew in nix-darwin's modules/homebrew.nix.
  system.activationScripts.homebrew.text = lib.mkForce ''
    # Homebrew Bundle
    echo >&2 "Homebrew bundle..."
    if [ ! -f "${cfg.prefix}/bin/brew" ]; then
      echo -e "\e[1;31merror: Homebrew is not installed, skipping...\e[0m" >&2
    elif [ "$(cat '${bundleStamp}' 2>/dev/null)" = '${bundleKey}' ]; then
      echo >&2 "Brewfile unchanged, skipping (rm ${bundleStamp} to force)"
    elif ${bundleCmd}; then
      sudo --user=${lib.escapeShellArg cfg.user} --set-home \
        sh -c 'mkdir -p "$(dirname "$1")" && printf "%s\n" "$2" > "$1"' _ '${bundleStamp}' '${bundleKey}'
    else
      # Under `set -e` a failed bundle (e.g. masApps while signed out of the App
      # Store) would abort the rest of activation; no stamp, so the next switch retries.
      echo -e "\e[1;33mwarning: brew bundle failed, continuing (it is retried on the next switch)\e[0m" >&2
    fi
  '';
}
