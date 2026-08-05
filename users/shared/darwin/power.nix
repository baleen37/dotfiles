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
}
