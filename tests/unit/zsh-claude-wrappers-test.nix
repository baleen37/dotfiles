# Zsh Claude Code wrapper function tests
#
# Tests that cc/cco/ccz/cck wrapper functions with model flags
# are properly defined in zsh initContent with correct model mappings.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  nixtest ? { },
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  mockConfig = import ../lib/mock-config.nix { inherit pkgs lib; };

  zshConfig = import ../../users/shared/zsh.nix {
    inherit pkgs lib;
    config = mockConfig.mkEmptyConfig;
  };

  initContent = zshConfig.programs.zsh.initContent.content or "";

  # Main wrapper functions that must be defined (model variants now use flags)
  expectedFunctions = [
    "cc"
    "cco"
    "ccz"
    "cck"
  ];

  # Helper: check function definition exists
  assertFnDefined = name:
    helpers.assertTest "zsh-fn-${name}-defined"
      (lib.hasInfix "${name}()" initContent)
      "Function ${name}() not found in zsh initContent";

  # Helper: check string present in initContent
  assertInitHas = name: needle:
    helpers.assertTest "zsh-init-${name}"
      (lib.hasInfix needle initContent)
      "${needle} not found in zsh initContent";

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "zsh-claude-wrappers" (
    # 1. Main wrapper functions are defined
    (map assertFnDefined expectedFunctions)

    # 2. Internal helpers are defined
    ++ [
      (assertFnDefined "_cc_run")
      (assertFnDefined "_cco_run")
      (assertFnDefined "_ccz_run")
      (assertFnDefined "_cck_run")
    ]

    # 3. cc supports model flags via _cc_parse_model_flags helper
    #    and rewrites positional args for wrapper-specific flags
    ++ [
      (assertInitHas "cc-parse-model-flags" "_cc_parse_model_flags")
      (assertInitHas "cc-flag-high" "-h|--high")
      (assertInitHas "cc-flag-low" "-l|--low")
      (assertInitHas "cc-parse-var-name" "local var_name")
      (assertInitHas "cc-parse-args" "local args=()")
      (assertInitHas "cc-parse-eval" "eval \"$(_cc_parse_model_flags")
      (assertInitHas "cc-parse-set-positional" "set --")
    ]

    # 4. cco requires CCO_ env vars (no silent fallback)
    ++ [
      (assertInitHas "cco-requires-sonnet-env" "CCO_SONNET_MODEL:?Set")
      (assertInitHas "cco-high-requires-env"   "CCO_OPUS_MODEL:?Set")
      (assertInitHas "cco-low-requires-env"    "CCO_HAIKU_MODEL:?Set")
    ]

    # 5. ccz requires CCZ_ env vars (no silent fallback)
    ++ [
      (assertInitHas "ccz-requires-sonnet-env" "CCZ_SONNET_MODEL:?Set")
      (assertInitHas "ccz-high-requires-env"   "CCZ_OPUS_MODEL:?Set")
      (assertInitHas "ccz-low-requires-env"    "CCZ_HAIKU_MODEL:?Set")
    ]

    # 6. _cc_run passes --model flag and common options
    ++ [
      (assertInitHas "cc-run-model-flag" "--model \"$model\"")
      (assertInitHas "cc-run-skip-perms" "--dangerously-skip-permissions")
    ]

    # 7. cco sets ANTHROPIC env vars for OpenAI-compatible proxy
    ++ [
      (assertInitHas "cco-base-url"    "ANTHROPIC_BASE_URL")
      (assertInitHas "cco-auth-token"  "ANTHROPIC_AUTH_TOKEN")
      (assertInitHas "cco-default-url" "http://127.0.0.1:8317")
    ]

    # 8. ccz sets Z.ai-specific env vars
    ++ [
      (assertInitHas "ccz-base-url"   "https://api.z.ai/api/anthropic")
      (assertInitHas "ccz-auth-token" "CCZ_TOKEN")
    ]

    # 9. cck sets Kimi-specific env vars
    ++ [
      (assertInitHas "cck-base-url"   "CCK_BASE_URL")
      (assertInitHas "cck-auth-token" "CCK_AUTH_TOKEN")
    ]

    # 10. gw supports all subcmds including cco and cck
    ++ [
      (assertInitHas "gw-cco-subcmd" "cc|cco|ccz|cck|oc")
    ]
  );
}
