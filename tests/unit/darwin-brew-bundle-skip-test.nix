# Guards the stamp that lets activation skip an unchanged `brew bundle`
# (users/shared/darwin/homebrew.nix).
#
# Both ways it can break are silent: if the replaced script stops running
# nix-darwin's bundle command, new casks never install; if the stamp key stops
# tracking the Brewfile, an edited Brewfile is skipped as "unchanged".
{
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  darwin = self.darwinConfigurations.kakaostyle-jito;
  # lib.hasInfix and replaceStrings refuse patterns that reference store paths.
  plain = builtins.unsafeDiscardStringContext;
  script = plain darwin.config.system.activationScripts.homebrew.text;
  bundleCmd = plain (darwin.config.homebrew.onActivation.brewBundleCmd { onlyCheck = false; });
  extended =
    (darwin.extendModules {
      modules = [ { homebrew.casks = [ "brew-bundle-skip-test-cask" ]; } ];
    }).config;
  # Drop the bundle command itself, which embeds the Brewfile path, so what is
  # compared is the stamp key alone.
  withoutCmd = cmd: text: lib.replaceStrings [ cmd ] [ "" ] text;
  stampPart = withoutCmd bundleCmd script;
  extendedStampPart = withoutCmd (plain (
    extended.homebrew.onActivation.brewBundleCmd { onlyCheck = false; }
  )) (plain extended.system.activationScripts.homebrew.text);
in
{
  platforms = [ "darwin" ];
  value = {
    runs-nix-darwin-bundle-command =
      helpers.assertTest "runs nix-darwin bundle command" (lib.hasInfix bundleCmd script)
        "the replaced activation script must still run nix-darwin's brew bundle command, or Brewfile changes never install";

    skips-on-matching-stamp =
      helpers.assertTest "skips on matching stamp" (lib.hasInfix "Brewfile unchanged, skipping" script)
        "activation should skip brew bundle when the stamp matches; otherwise every switch pays 5-15s";

    brewfile-change-invalidates-stamp = helpers.assertTest "brewfile change invalidates stamp" (
      stampPart != extendedStampPart
    ) "adding a cask must change the stamp key, or the new cask is skipped as unchanged";
  };
}
