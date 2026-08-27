# macOS Power Management
#
# Keeps the machine awake with the lid closed while the power adapter is
# connected, and lets it sleep normally on battery.
#
# The only knob that suppresses clamshell sleep is pmset's undocumented
# `disablesleep`, and it is system-wide: `pmset -c disablesleep 1` stores
# `SleepDisabled` under `SystemPowerSettings` in
# /Library/Preferences/com.apple.PowerManagement.plist, so the -c/-b/-a
# power-source flag is ignored. A single declarative value therefore cannot mean
# "AC only" -- something has to follow the power source and toggle it, which is
# what this daemon does.
#
# `pmset -g pslog` blocks until the power source changes and flushes per line
# even when piped, so the daemon sits idle on a read instead of polling, and
# reacts in about a second rather than within a poll window. It also prints the
# current state right after registering, which is what performs the initial
# reconcile at load.
#
# Separately, Bluetooth input devices wake the machine from clamshell sleep on
# battery. A paired trackpad nudged in a bag produced a 45s-wake / 10s-sleep
# DarkWake loop ("due to ... wifibt ... bluetooth-pcie" in `pmset -g log`),
# which drains the battery while the lid is shut. `RemoteWakeEnabled` is the
# system-wide switch behind Settings > General > Sharing > Advanced, and
# nix-darwin has no option for it, so it is written directly below.

_:

{
  launchd.daemons.lid-awake-on-ac = {
    script = ''
      reconcile() {
        if /usr/bin/pmset -g ps | /usr/bin/grep -q "AC Power"; then
          want=1
        else
          want=0
        fi

        # Absent from `pmset -g` until it has been set once; treat that as 0.
        current=$(/usr/bin/pmset -g | /usr/bin/awk '/SleepDisabled/ { print $2 }')
        [ -n "$current" ] || current=0

        if [ "$current" != "$want" ]; then
          /usr/bin/pmset -a disablesleep "$want"
        fi
      }

      # Reconcile on every line rather than only on "Now drawing from": the
      # toggle is idempotent, so an extra check costs two pmset reads, while a
      # missed transition leaves the machine awake on battery.
      /usr/bin/pmset -g pslog | while IFS= read -r _; do
        reconcile
      done
    '';

    serviceConfig = {
      RunAtLoad = true;
      # The daemon is the pslog stream; if pmset ever exits, restart it.
      KeepAlive = true;
      StandardErrorPath = "/var/log/lid-awake-on-ac.log";
    };
  };

  # Stop Bluetooth peripherals from waking the machine with the lid closed.
  # The key is absent until it has been written once, so `read` failing is the
  # unset case and is treated as "not yet disabled".
  system.activationScripts.postActivation.text = ''
    echo "Disabling Bluetooth remote wake..." >&2

    bt_plist=/Library/Preferences/com.apple.Bluetooth
    bt_wake=$(/usr/bin/defaults read "$bt_plist" RemoteWakeEnabled 2>/dev/null || echo 1)

    if [ "$bt_wake" = "0" ]; then
      echo "  ✓  Bluetooth remote wake already disabled" >&2
    else
      /usr/bin/defaults write "$bt_plist" RemoteWakeEnabled -bool false >&2 || true
      echo "  Bluetooth remote wake disabled" >&2
    fi
  '';
}
