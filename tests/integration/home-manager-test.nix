# tests/integration/home-manager-test.nix
#
# Tests the Home Manager configuration in users/shared/home-manager.nix
# Verifies imports, currentSystemUser usage, dynamic home directory configuration, and XDG settings.
{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Expected imports list
  expectedImports = [
    "./git.nix"
    "./vim.nix"
    "./zsh.nix"
    "./starship.nix"
    "./tmux.nix"
    "./claude-code.nix"
    "./opencode.nix"
    "./hammerspoon.nix"
    "./karabiner.nix"
    "./ghostty.nix"
  ];

  # Test with default user (baleen)
  hmConfig = import ../../users/shared/home-manager.nix {
    inherit pkgs lib inputs;
    currentSystemUser = "baleen";
    config = {
      home = {
        homeDirectory = "/Users/baleen";
      };
    };
  };

  # Test with alternative user (jito.hello)
  hmConfigJito = import ../../users/shared/home-manager.nix {
    inherit pkgs lib inputs;
    currentSystemUser = "jito.hello";
    config = {
      home = {
        homeDirectory = "/Users/jito.hello";
      };
    };
  };

  # Test helper to check if import exists
  hasImport = importPath:
    builtins.any (imp: imp == importPath) (hmConfig.imports or []);

  # Test helper to check if all expected imports are present
  hasAllExpectedImports =
    builtins.all (imp: hasImport imp) expectedImports;

  # Test helper to check if package is installed
  hasPackage = packageName:
    builtins.any (pkg: pkg.pname or null == packageName) (hmConfig.home.packages or []);

in
helpers.testSuite "home-manager" [
  # Test that imports list exists
  (helpers.assertTest "hm-has-imports" (hmConfig ? imports) "home-manager.nix should have imports")

  # Test that home attribute exists
  (helpers.assertTest "hm-has-home" (hmConfig ? home) "home-manager.nix should have home attribute")

  # Test that username is set from currentSystemUser (baleen test)
  (helpers.assertTest "hm-username-baleen" (
    hmConfig.home.username == "baleen"
  ) "Username should match currentSystemUser (baleen in test)")

  # Test that username is set from currentSystemUser (jito.hello test)
  (helpers.assertTest "hm-username-jito" (
    hmConfigJito.home.username == "jito.hello"
  ) "Username should match currentSystemUser (jito.hello in test)")

  # Test that home directory is dynamically set for Darwin (baleen test)
  (helpers.assertTest "hm-home-dir-darwin-baleen" (
    hmConfig.home.homeDirectory == "/Users/baleen"
  ) "Home directory should be /Users/baleen on Darwin (baleen test)")

  # Test that home directory is dynamically set for Darwin (jito.hello test)
  (helpers.assertTest "hm-home-dir-darwin-jito" (
    hmConfigJito.home.homeDirectory == "/Users/jito.hello"
  ) "Home directory should be /Users/jito.hello on Darwin (jito.hello test)")

  # Test that all expected imports are present
  (helpers.assertTest "hm-has-all-expected-imports" hasAllExpectedImports
    "All expected imports should be present (git, vim, zsh, starship, tmux, claude-code, opencode, hammerspoon, karabiner, ghostty)")

  # Test that git.nix is imported
  (helpers.assertTest "hm-imports-git" (hasImport "./git.nix")
    "git.nix should be imported")

  # Test that vim.nix is imported
  (helpers.assertTest "hm-imports-vim" (hasImport "./vim.nix")
    "vim.nix should be imported")

  # Test that zsh.nix is imported
  (helpers.assertTest "hm-imports-zsh" (hasImport "./zsh.nix")
    "zsh.nix should be imported")

  # Test that starship.nix is imported
  (helpers.assertTest "hm-imports-starship" (hasImport "./starship.nix")
    "starship.nix should be imported")

  # Test that tmux.nix is imported
  (helpers.assertTest "hm-imports-tmux" (hasImport "./tmux.nix")
    "tmux.nix should be imported")

  # Test that claude-code.nix is imported
  (helpers.assertTest "hm-imports-claude-code" (hasImport "./claude-code.nix")
    "claude-code.nix should be imported")

  # Test that opencode.nix is imported
  (helpers.assertTest "hm-imports-opencode" (hasImport "./opencode.nix")
    "opencode.nix should be imported")

  # Test that hammerspoon.nix is imported
  (helpers.assertTest "hm-imports-hammerspoon" (hasImport "./hammerspoon.nix")
    "hammerspoon.nix should be imported")

  # Test that karabiner.nix is imported
  (helpers.assertTest "hm-imports-karabiner" (hasImport "./karabiner.nix")
    "karabiner.nix should be imported")

  # Test that ghostty.nix is imported
  (helpers.assertTest "hm-imports-ghostty" (hasImport "./ghostty.nix")
    "ghostty.nix should be imported")

  # Test that XDG is enabled
  (helpers.assertTest "hm-xdg-enabled" (hmConfig.xdg.enable == true)
    "XDG directories should be enabled")

  # Test that stateVersion is set
  (helpers.assertTest "hm-has-state-version" (hmConfig.home.stateVersion != null)
    "stateVersion should be set")

  # Test that packages list exists
  (helpers.assertTest "hm-has-packages" (hmConfig.home.packages != null)
    "packages list should exist")

  # Test that packages list is not empty
  (helpers.assertTest "hm-has-packages-nonempty" (builtins.length (hmConfig.home.packages or []) > 0)
    "packages list should not be empty")

  # Test that claude-code package is included
  (helpers.assertTest "hm-has-claude-code-package" (hasPackage "claude-code")
    "claude-code package should be included")

  # Test that opencode package is included
  (helpers.assertTest "hm-has-opencode-package" (hasPackage "opencode")
    "opencode package should be included")

  # Test that git package is included
  (helpers.assertTest "hm-has-git-package" (hasPackage "git")
    "git package should be included")

  # Test that vim package is included
  (helpers.assertTest "hm-has-vim-package" (hasPackage "vim")
    "vim package should be included")
]
