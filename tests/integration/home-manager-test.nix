# tests/integration/home-manager-test.nix
#
# Covers users/shared/home-manager.nix, the entry point every host shares.
#
# It is imported raw rather than evaluated, so `imports` here is a list of Nix
# *paths* — comparing against "./git.nix" silently never matches, which is why
# these assertions go through toString and a suffix check.
#
# Package contents are deliberately not asserted here: home.packages is
# contributed by the imported category modules and only exists after the module
# system merges them (see unit/security-packages-test.nix).
{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  mkConfig =
    user:
    import ../../users/shared/home-manager.nix {
      inherit pkgs lib inputs;
      currentSystemUser = user;
      isDarwin = true;
    };

  hmConfig = mkConfig "baleen";
  hmConfigJito = mkConfig "jito.hello";

  homeDirBaleen = hmConfig.home.homeDirectory;
  homeDirJito = hmConfigJito.home.homeDirectory;

  importedPaths = map builtins.toString hmConfig.imports;
  importsModule =
    relativePath:
    let
      suffix = "/users/shared/${relativePath}";
    in
    lib.any (path: lib.hasSuffix suffix path) importedPaths;

  expectedModules = [
    "darwin/vscode-launchservices.nix"
    "programs/git.nix"
    "programs/vim.nix"
    "programs/zsh"
    "programs/starship.nix"
    "programs/tmux.nix"
    "programs/claude-code.nix"
    "programs/codex.nix"
    "programs/opencode.nix"
    "programs/ghostty.nix"
    "programs/ssh.nix"
    "programs/alfred.nix"
    "programs/hammerspoon.nix"
    "programs/karabiner.nix"
    "packages/core.nix"
    "packages/dev.nix"
    "packages/security.nix"
    "packages/ai.nix"
  ];

  slug = lib.stringAsChars (c: if builtins.match "[a-zA-Z0-9]" c != null then c else "-");

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "home-manager" (
    [
      # The point of the currentSystemUser indirection: nothing is hardcoded to
      # one username, including the home directory.
      (helpers.assertTest "username-follows-current-system-user" (
        hmConfig.home.username == "baleen" && hmConfigJito.home.username == "jito.hello"
      ) "home.username must come from currentSystemUser")

      (helpers.assertTest "home-directory-follows-current-system-user" (
        homeDirBaleen == "/Users/baleen" && homeDirJito == "/Users/jito.hello"
      ) "home.homeDirectory must be derived from currentSystemUser")

      (helpers.assertTest "state-version-is-pinned" (
        hmConfig.home.stateVersion == "24.11"
      ) "home.stateVersion must stay pinned; bumping it silently changes defaults")

      (helpers.assertTest "xdg-enabled" hmConfig.xdg.enable
        "xdg.enable must be true; several modules write into XDG paths"
      )

      # Alfred, hammerspoon, and karabiner are imported unconditionally and gated
      # by their own platform defaults (see unit/platform-defaults-test.nix), so
      # they must not appear in this enable block.
      (helpers.assertTest "platform-gated-modules-not-force-enabled" (
        !(hmConfig.modules.programs ? alfred)
        && !(hmConfig.modules.programs ? hammerspoon)
        && !(hmConfig.modules.programs ? karabiner)
      ) "alfred/hammerspoon/karabiner must be left to their module-level platform default")

      (helpers.assertTest "every-package-category-enabled" (lib.all
        (category: hmConfig.modules.packages.${category}.enable)
        (builtins.attrNames hmConfig.modules.packages)
      ) "every package category listed in home-manager.nix should be enabled")
    ]
    ++ map (
      modulePath:
      helpers.assertTest "imports-${slug modulePath}" (importsModule modulePath)
        "users/shared/home-manager.nix should import ${modulePath}"
    ) expectedModules
  );
}
