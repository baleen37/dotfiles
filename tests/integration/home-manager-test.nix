# tests/integration/home-manager-test.nix
#
# Covers users/shared/home-manager.nix, the entry point every host shares.
#
# Identity settings are read from a raw import of the file. Module wiring is
# read from the merged configuration of real hosts: home-manager.nix imports
# whatever lib/home-modules.nix discovers and sets no enable flags, so the
# merged config is the only place a module that failed to load, or one turned
# off by a stray definition, shows up.
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
      config = { };
      currentSystemUser = user;
      isDarwin = true;
    };

  hmConfig = mkConfig "baleen";
  hmConfigJito = mkConfig "jito.hello";

  homeDirBaleen = hmConfig.home.homeDirectory;
  homeDirJito = hmConfigJito.home.homeDirectory;

  homeModules = import ../../lib/home-modules.nix { inherit lib; };

  hmUsers = host: builtins.attrValues host.config.home-manager.users;
  darwinUsers = hmUsers inputs.self.darwinConfigurations.macbook-pro;
  linuxUsers = [ inputs.self.homeConfigurations.baleen-linux.config ];

  # attrNames is sorted, so this compares the declared module set exactly.
  importsEveryModule =
    category: users:
    users != [ ]
    && lib.all (
      u: builtins.attrNames u.modules.${category} == builtins.attrNames homeModules.${category}
    ) users;

  # Check that the shared selection reaches real outputs; optional categories
  # added for one platform must not become mandatory on every other platform.
  development = (import ../../users/shared/development.nix { }).modules;
  enablesDevelopment =
    users:
    lib.all (
      u:
      lib.all
        (
          category:
          lib.all (name: u.modules.${category}.${name}.enable) (builtins.attrNames development.${category})
        )
        [
          "programs"
          "packages"
        ]
    ) users;

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "home-manager" [
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

    # Enabling is owned by each module's option default (see
    # unit/platform-defaults-test.nix); an enable block here would override it.
    (helpers.assertTest "sets-no-enable-flags" (
      !(hmConfig ? modules)
    ) "home-manager.nix must not set modules.*; each module's enable default owns the decision")

    (helpers.assertTest "darwin-imports-every-program" (importsEveryModule "programs" darwinUsers)
      "macbook-pro Home Manager config must declare exactly the modules under users/shared/programs"
    )

    (helpers.assertTest "darwin-imports-every-package-category"
      (importsEveryModule "packages" darwinUsers)
      "macbook-pro Home Manager config must declare exactly the modules under users/shared/packages"
    )

    (helpers.assertTest "linux-imports-every-program" (importsEveryModule "programs" linuxUsers)
      "Linux Home Manager config must declare exactly the modules under users/shared/programs"
    )

    (helpers.assertTest "linux-imports-every-package-category"
      (importsEveryModule "packages" linuxUsers)
      "Linux Home Manager config must declare exactly the modules under users/shared/packages"
    )

    (helpers.assertTest "darwin-selects-shared-development" (enablesDevelopment darwinUsers)
      "the Mac development composition must apply every shared development selection"
    )

    (helpers.assertTest "linux-selects-shared-development" (enablesDevelopment linuxUsers)
      "standalone Linux must apply every shared development selection"
    )
  ];
}
