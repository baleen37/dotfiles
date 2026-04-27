# Verifies cache-config.nix entries appear consistently in all four locations
# and that URLs/public-keys have valid format.
#
# This complements scripts/check-cache-sync.sh (which only covers
# flake.nix <-> lib/cache-config.nix) by also covering CI yaml.
{
  pkgs,
  lib,
  ...
}:
let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  cacheConfig = import ../../lib/cache-config.nix;

  flakeNix = builtins.readFile ../../flake.nix;
  ciYml = builtins.readFile ../../.github/workflows/ci.yml;
  setupNixYml = builtins.readFile ../../.github/actions/setup-nix/action.yml;

  containsAll = haystack: needles: lib.all (n: lib.hasInfix n haystack) needles;

  urlOk = url: lib.hasPrefix "https://" url;

  # Cachix public key format: <name>-<digit>+:<43 base64 chars>=
  # Examples:
  #   baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k=
  #   cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
  keyOk =
    key: builtins.match "[a-zA-Z0-9._-]+-[0-9]+:[A-Za-z0-9+/]{43}=" key != null;

  subs = cacheConfig.substituters;
  keys = cacheConfig.trusted-public-keys;
in
{
  flakeNixHasAllSubstituters =
    helpers.assertTest "flake-nix-has-all-substituters" (containsAll flakeNix subs)
      "flake.nix nixConfig must contain every substituter from lib/cache-config.nix";

  flakeNixHasAllKeys =
    helpers.assertTest "flake-nix-has-all-keys" (containsAll flakeNix keys)
      "flake.nix nixConfig must contain every trusted-public-key from lib/cache-config.nix";

  ciYmlHasAllSubstituters =
    helpers.assertTest "ci-yml-has-all-substituters" (containsAll ciYml subs)
      ".github/workflows/ci.yml NIX_CONFIG must contain every substituter from lib/cache-config.nix";

  ciYmlHasAllKeys =
    helpers.assertTest "ci-yml-has-all-keys" (containsAll ciYml keys)
      ".github/workflows/ci.yml NIX_CONFIG must contain every trusted-public-key from lib/cache-config.nix";

  setupNixHasAllSubstituters =
    helpers.assertTest "setup-nix-has-all-substituters"
      (containsAll setupNixYml subs)
      ".github/actions/setup-nix/action.yml extra-conf must contain every substituter from lib/cache-config.nix";

  setupNixHasAllKeys =
    helpers.assertTest "setup-nix-has-all-keys" (containsAll setupNixYml keys)
      ".github/actions/setup-nix/action.yml extra-conf must contain every trusted-public-key from lib/cache-config.nix";

  allUrlsAreHttps =
    helpers.assertTest "substituter-urls-are-https" (lib.all urlOk subs)
      "every substituter URL must start with https://";

  allKeysHaveValidFormat =
    helpers.assertTest "public-keys-have-valid-format" (lib.all keyOk keys)
      "every trusted-public-key must match <name>-<digit>:<43-base64>=";
}
