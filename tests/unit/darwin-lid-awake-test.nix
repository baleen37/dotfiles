# Guards the closed-lid-on-AC daemon in users/shared/darwin/power.nix.
#
# Every part of it fails silently: a daemon with no RunAtLoad is installed but
# never runs, and a script that stops gating on the power source
# keeps the machine awake on battery -- the failure mode being a MacBook cooking
# itself in a bag. Nothing here surfaces at switch time, so assert on the
# rendered daemon.
{
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  daemons = self.darwinConfigurations.kakaostyle-jito.config.launchd.daemons;
  daemon = daemons.lid-awake-on-ac or null;
  script = if daemon == null then "" else daemon.script;
in
{
  platforms = [ "darwin" ];
  value = {
    daemon-declared = helpers.assertTest "lid awake daemon declared" (
      daemon != null
    ) "launchd.daemons.lid-awake-on-ac is what keeps the lid-closed machine awake on AC";

    toggles-disablesleep =
      helpers.assertTest "toggles pmset disablesleep" (lib.hasInfix "pmset -a disablesleep" script)
        "disablesleep is the only setting that suppresses clamshell sleep; nothing else in pmset substitutes for it";

    gated-on-ac-power =
      helpers.assertTest "gated on AC power" (lib.hasInfix "AC Power" script)
        "without the power-source check the machine also stays awake on battery with the lid shut";

    actually-runs =
      helpers.assertTest "runs at load and stays running"
        (daemon != null && daemon.serviceConfig.RunAtLoad == true && daemon.serviceConfig.KeepAlive == true)
        "without RunAtLoad the daemon never starts, and without KeepAlive a dead pslog stream is never restarted";

    event-driven =
      helpers.assertTest "waits on power source events" (lib.hasInfix "pmset -g pslog" script)
        "the daemon is meant to block on the pslog stream; falling back to polling wakes the CPU on a timer forever";
  };
}
