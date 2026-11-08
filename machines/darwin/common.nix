# machines/darwin/common.nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # A newer app may have migrated the local vault to an incompatible schema.
  system.activationScripts.preActivation.text = lib.mkIf config.programs._1password-gui.enable ''
    if [ -f /Applications/1Password.app/Contents/Info.plist ]; then
      installed=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' /Applications/1Password.app/Contents/Info.plist) || exit 1
      target=${lib.escapeShellArg config.programs._1password-gui.package.version}
      oldest=$(printf '%s\n' "$installed" "$target" | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/head -n1)
      if [ "$installed" != "$target" ] && [ "$oldest" = "$target" ]; then
        echo "Refusing to downgrade 1Password from $installed to $target; update the Nix package first." >&2
        exit 1
      fi
    fi
  '';

  # Minimal system-level settings
  environment.systemPackages = with pkgs; [
    home-manager
    # `make switch` runs `nh clean all` after every switch.
    nh
  ];

  # Enable essential programs
  programs.zsh = {
    enable = true;
    # Home Manager's .zshrc runs compinit and sets the prompt; doing both here
    # too ran compinit twice and loaded a prompt theme that is then replaced.
    enableGlobalCompInit = false;
    promptInit = "";
  };

  # Remote Login (SSH). nix-darwin turns it on with launchctl, not
  # `systemsetup -setremotelogin`, which needs Full Disk Access.
  services.openssh.enable = true;

  # Touch ID for sudo. Non-interactive shells (Claude Code, scripts) cannot
  # answer a password prompt at all; Touch ID gives them a path that works.
  # `reattach` keeps it working inside tmux sessions.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # System state version
  system.stateVersion = 5;
}
