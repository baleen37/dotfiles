# Darwin bgc compatibility wrapper tests
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  mockConfig = import ../lib/mock-config.nix { inherit pkgs lib; };

  zshModule = import ../../users/shared/programs/zsh {
    inherit pkgs lib;
    isDarwin = true;
    config = mockConfig.mkEmptyConfig // {
      modules.programs.zsh.enable = true;
      home.homeDirectory = "/Users/testuser";
    };
  };
  zshConfigBody = zshModule.config.content;
  initContent = zshConfigBody.programs.zsh.initContent.content or "";
  aliases = zshConfigBody.programs.zsh.shellAliases or { };

  assertInitHas =
    name: needle:
    helpers.assertTest "zsh-bgc-${name}" (lib.hasInfix needle initContent)
      "Expected '${needle}' in zsh initContent";
in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "zsh-bgc" [
    (assertInitHas "function" "bgc() {")
    (assertInitHas "delegates-to-bl" "bl gc")
    (helpers.assertTest "zsh-bgc-preserves-gc-alias" (
      aliases.gc == "git commit"
    ) "the existing gc git alias must remain unchanged")
  ];
}
