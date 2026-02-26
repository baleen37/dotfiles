# Regression tests: verifies that previously removed parameters
# have not been re-introduced in git.nix and vim.nix.
#
# Uses builtins.functionArgs to inspect actual parameter declarations,
# preventing unnecessary coupling between modules and their callers.
#
# Checked modules:
#   - git.nix: should only use `...` (no pkgs, no lib)
#   - vim.nix: should only use `pkgs` and `...` (no lib, no config)
{
  inputs,
  system,
  pkgs,
  lib,
  nixtest ? { },
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  gitNixFn = import ../../users/shared/git.nix;
  vimNixFn = import ../../users/shared/vim.nix;

  gitArgs = builtins.functionArgs gitNixFn;
  vimArgs = builtins.functionArgs vimNixFn;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "unused-params" [
    # git.nix should not declare pkgs (it doesn't use it)
    (helpers.assertTest "git-nix-no-unused-pkgs" (
      !(builtins.hasAttr "pkgs" gitArgs)
    ) "git.nix should not declare unused pkgs parameter")

    # git.nix should not declare lib (it imports user-info.nix directly)
    (helpers.assertTest "git-nix-no-unused-lib" (
      !(builtins.hasAttr "lib" gitArgs)
    ) "git.nix should not declare unused lib parameter")

    # vim.nix should not declare lib (it doesn't use it)
    (helpers.assertTest "vim-nix-no-unused-lib" (
      !(builtins.hasAttr "lib" vimArgs)
    ) "vim.nix should not declare unused lib parameter")

    # vim.nix should not declare config (it doesn't use it)
    (helpers.assertTest "vim-nix-no-unused-config" (
      !(builtins.hasAttr "config" vimArgs)
    ) "vim.nix should not declare unused config parameter")

    # vim.nix SHOULD still declare pkgs (it uses pkgs.vimPlugins)
    (helpers.assertTest "vim-nix-keeps-pkgs" (builtins.hasAttr "pkgs" vimArgs)
      "vim.nix should keep pkgs parameter (used for pkgs.vimPlugins)"
    )
  ];
}
