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

_:

{
  # mas uses Spotlight metadata to find installed Mac App Store apps. Keep the
  # index enabled for the root volume and import the configured apps when their
  # Adam ID is not available yet.
  system.activationScripts.preActivation.text = ''
    spotlight_status=$(/usr/bin/mdutil -s / 2>/dev/null || true)
    if echo "$spotlight_status" | grep -qi "disabled"; then
      echo "Enabling Spotlight indexing for App Store app detection..." >&2
      /usr/bin/mdutil -E -i on / >&2 || true
    fi

    for app in \
      "/Applications/KakaoTalk.app" \
      "/Applications/Magnet.app"; do
      adam_id=$(/usr/bin/mdls -raw -name kMDItemAppStoreAdamID "$app" 2>/dev/null || true)
      if [ -d "$app" ] && { [ -z "$adam_id" ] || [ "$adam_id" = "(null)" ]; }; then
        /usr/bin/mdimport "$app" 2>/dev/null || true
      fi
    done
  '';

  system.activationScripts.postActivation.text = ''
    # Remote Login (SSH)
    # Enables macOS Remote Login so the machine accepts incoming SSH connections.
    # nix-darwin has no dedicated option for this, so we toggle it via systemsetup.
    # Idempotent: only flips the setting when it is currently off.
    echo "Enabling Remote Login (SSH)..." >&2

    if /usr/sbin/systemsetup -getremotelogin 2>/dev/null | grep -q "On"; then
      echo "  ✓  Remote Login already enabled" >&2
    else
      /usr/sbin/systemsetup -setremotelogin -f on >&2
      echo "  Remote Login enabled" >&2
    fi

    # macOS App Cleanup
    # Automated storage optimization through removal of unused default macOS applications
    # Saves 6-8GB of storage space and reduces system resource consumption
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "Removing unused macOS default apps..." >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

    # 제거할 앱 목록
    apps=(
      "GarageBand.app"
      "iMovie.app"
      "TV.app"
      "Podcasts.app"
      "News.app"
      "Stocks.app"
      "Freeform.app"
    )

    removed_count=0
    skipped_count=0

    for app in "''${apps[@]}"; do
      app_path="/Applications/$app"

      if [ -e "$app_path" ]; then
        echo "  Removing: $app" >&2

        # activation already runs as root, so no sudo needed; SIP still wins
        if rm -rf "$app_path" 2>/dev/null; then
          removed_count=$((removed_count + 1))
        else
          echo "     Failed to remove (SIP protected): $app" >&2
          skipped_count=$((skipped_count + 1))
        fi
      else
        echo "  ✓  Already removed: $app" >&2
      fi
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "Cleanup complete!" >&2
    echo "   - Removed: $removed_count apps" >&2
    echo "   - Skipped: $skipped_count apps (protected)" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  '';

  # Keyboard input source configuration is deliberately absent.
  #
  # It used to live here as `system.activationScripts.configureKeyboard`, which
  # never ran for the reason described above. Moving it into postActivation would
  # start it running, and its hotkey payload is wrong: it wrote
  # `parameters = (49, 1048576, 131072)` for hotkey 60, while the working value
  # on this machine is `(32, 49, 1179648)` -- character, keycode, modifiers, in
  # that order. Enabling it as-written would break cmd+shift+space input
  # switching, which already works, so it was dropped rather than resurrected.
}
