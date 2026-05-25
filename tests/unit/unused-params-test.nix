# Regression tests: verifies that previously removed parameters
# have not been re-introduced unnecessarily in git.nix and vim.nix.
#
# Uses builtins.functionArgs to inspect actual parameter declarations,
# preventing unnecessary coupling between modules and their callers.
#
# Checked modules:
#   - git.nix: should use `config` and `lib` (for modules.programs.git option), no pkgs
#   - vim.nix: should use `config`, `lib`, and `pkgs` (for pkgs.vimPlugins)
{
  pkgs,
  lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  gitNixFn = import ../../users/shared/programs/git.nix;
  vimNixFn = import ../../users/shared/programs/vim.nix;

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

    # git.nix SHOULD declare lib (used for mkEnableOption / mkIf)
    (helpers.assertTest "git-nix-has-lib" (builtins.hasAttr "lib" gitArgs)
      "git.nix should declare lib parameter (used for modules option)"
    )

    # git.nix SHOULD declare config (used for modules.programs.git.enable)
    (helpers.assertTest "git-nix-has-config" (builtins.hasAttr "config" gitArgs)
      "git.nix should declare config parameter (used for modules option)"
    )

    # vim.nix SHOULD declare lib (used for mkEnableOption / mkIf)
    (helpers.assertTest "vim-nix-has-lib" (builtins.hasAttr "lib" vimArgs)
      "vim.nix should declare lib parameter (used for modules option)"
    )

    # vim.nix SHOULD declare config (used for modules.programs.vim.enable)
    (helpers.assertTest "vim-nix-has-config" (builtins.hasAttr "config" vimArgs)
      "vim.nix should declare config parameter (used for modules option)"
    )

    # vim.nix SHOULD still declare pkgs (it uses pkgs.vimPlugins)
    (helpers.assertTest "vim-nix-keeps-pkgs" (builtins.hasAttr "pkgs" vimArgs)
      "vim.nix should keep pkgs parameter (used for pkgs.vimPlugins)"
    )
  ];
}
