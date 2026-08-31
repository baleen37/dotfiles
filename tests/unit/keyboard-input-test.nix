{
  inputs,
  system,
  self,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  activation =
    self.homeConfigurations."jito.hello".config.home.activation.keyboardInputSource or null;
  activationText = if activation == null then "" else activation.data;
in
{
  platforms = [ "darwin" ];
  value = {
    activation-exists = helpers.assertTest "keyboard input activation exists" (
      activation != null
    ) "Darwin Home Manager must define the keyboard input source activation";

    activation-uses-input-hotkey =
      helpers.assertTest "keyboard input hotkey id"
        (lib.hasInfix "AppleSymbolicHotKeys -dict-add 60" activationText)
        "input source switching must configure macOS hotkey 60";

    activation-uses-control-space =
      helpers.assertTest "keyboard input uses Ctrl+Space"
        (lib.hasInfix "parameters = (32, 49, 262144);" activationText)
        "input source switching must use Ctrl+Space parameters";
  };
}
