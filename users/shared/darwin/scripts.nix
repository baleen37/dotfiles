# macOS Activation Scripts
#
# System activation scripts for:
# - Remote Login (SSH) enablement
# - Automated cleanup of unused default macOS applications
#
# Everything lives under `system.activationScripts.postActivation.text` on
# purpose. nix-darwin assembles the activation script from a fixed list of
# segments (preActivation, extraActivation, defaults, homebrew, postActivation,
# ...) in modules/system/activation-scripts.nix, so a custom attribute name like
# `system.activationScripts.enableRemoteLogin` type-checks and evaluates but is
# never spliced into the script that actually runs -- it silently does nothing.
# These scripts sat unused that way until this was noticed.
#
# The whole segment runs under `set -e` and `set -o pipefail`, and nix-darwin has
# no per-segment failure isolation (unlike the NixOS activation script, which
# wraps each one in a trap). A non-zero exit here aborts the rest of the switch,
# including the homebrew and launchd segments, so keep failures contained: guard
# with `if`, and use `|| true` on best-effort side effects.

{ pkgs, ... }:

{
  # The bash lives in ./activation.sh so its behaviour is testable against stub
  # binaries (tests/integration/darwin-activation-script-test.nix). A non-zero
  # exit still propagates and aborts the switch, as it did when inlined.
  system.activationScripts.preActivation.text = ''
    ${pkgs.bash}/bin/bash ${./activation.sh} spotlight
  '';

  system.activationScripts.postActivation.text = ''
    ${pkgs.bash}/bin/bash ${./activation.sh} remote-login
    ${pkgs.bash}/bin/bash ${./activation.sh} app-cleanup
  '';

  # Keyboard input source configuration lives in the Darwin Home Manager module
  # at `darwin/keyboard-input.nix`, where activation runs as the target user.
}
