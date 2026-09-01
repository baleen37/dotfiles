# Guards that our activation scripts end up in the script nix-darwin runs.
#
# nix-darwin assembles `system.activationScripts.script.text` from a fixed list of
# segment names (preActivation, extraActivation, defaults, homebrew,
# postActivation, ...). A custom `system.activationScripts.<name>` type-checks and
# evaluates, but is never spliced in, so it silently never runs. Asserting that
# the attribute exists passes in exactly that case -- which is how the Remote
# Login and app cleanup scripts sat dead until someone diffed the generated
# activate script against the source.
#
# So assert on the assembled text, which is the only thing that proves execution.
{
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  activation = self.darwinConfigurations.kakaostyle-jito.config.system.activationScripts;
  systemActivationSource = builtins.readFile ../../users/shared/darwin/scripts.nix;
  userActivation = self.homeConfigurations."jito.hello".config.home.activation.vscodeLaunchServices;
in
{
  platforms = [ "darwin" ];
  value = {
    remote-login-runs =
      helpers.assertTest "remote login script runs"
        (lib.hasInfix "systemsetup -setremotelogin" activation.script.text)
        "Remote Login enablement should be spliced into the assembled activation script";

    app-cleanup-runs =
      helpers.assertTest "app cleanup script runs" (lib.hasInfix "GarageBand.app" activation.script.text)
        "App cleanup should be spliced into the assembled activation script";

    vscode-launchservices-repair-is-user-scoped =
      helpers.assertTest "VS Code LaunchServices repair is user-scoped"
        (
          !(lib.hasInfix "vscode-launchservices.sh" systemActivationSource)
          && lib.hasInfix "vscode-launchservices.sh" userActivation.data
        )
        "LaunchServices repair must stay in Home Manager user activation, not run directly from the root system activation";

    bluetooth-remote-wake-disabled-runs =
      helpers.assertTest "bluetooth remote wake disable runs"
        (lib.hasInfix "RemoteWakeEnabled" activation.script.text)
        "Bluetooth remote wake must be disabled during activation, or paired input devices wake the machine from clamshell sleep on battery";

    # The regression itself: a segment name nix-darwin does not know about.
    no-orphaned-custom-segments = helpers.assertTest "no orphaned custom activation segments" (
      !(activation ? enableRemoteLogin)
      && !(activation ? cleanupMacOSApps)
      && !(activation ? configureKeyboard)
    ) "custom activationScripts attributes are never run by nix-darwin; use postActivation instead";
  };
}
