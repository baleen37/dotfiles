# Zsh Claude Code wrapper function tests
#
# Tests that cc/cco/ccz wrapper functions and their -h/-l variants
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

  # All wrapper functions that must be defined
  expectedFunctions = [
    "cc"    "cc-h"  "cc-l"
    "cco"   "cco-h" "cco-l"
    "ccz"   "ccz-h" "ccz-l"
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
    # 1. All wrapper functions are defined
    (map assertFnDefined expectedFunctions)

    # 2. Internal helpers are defined
    ++ [
      (assertFnDefined "_cc_run")
      (assertFnDefined "_cco_run")
      (assertFnDefined "_ccz_run")
    ]

    # 3. cc uses hardcoded Anthropic model names (no env var indirection)
    ++ [
      (assertInitHas "cc-h-uses-opus"  "_cc_run opus")
      (assertInitHas "cc-l-uses-haiku" "_cc_run haiku")
    ]

    # 4. cco requires OPENAI_ env vars for all tiers (no silent fallback)
    ++ [
      (assertInitHas "cco-requires-sonnet-env" "OPENAI_SONNET_MODEL:?Set")
      (assertInitHas "cco-h-requires-env"      "OPENAI_OPUS_MODEL:?Set")
      (assertInitHas "cco-l-requires-env"      "OPENAI_HAIKU_MODEL:?Set")
    ]

    # 5. ccz requires ZAI_ env vars for all tiers (no silent fallback)
    ++ [
      (assertInitHas "ccz-requires-sonnet-env" "ZAI_SONNET_MODEL:?Set")
      (assertInitHas "ccz-h-requires-env"      "ZAI_OPUS_MODEL:?Set")
      (assertInitHas "ccz-l-requires-env"      "ZAI_HAIKU_MODEL:?Set")
    ]

    # 6. _cc_run passes --model flag and common options
    ++ [
      (assertInitHas "cc-run-model-flag" "--model \"$model\"")
      (assertInitHas "cc-run-skip-perms" "--dangerously-skip-permissions")
      (assertInitHas "cc-run-lsp"        "ENABLE_LSP_TOOL=true")
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
      (assertInitHas "ccz-auth-token" "ZAI_TOKEN")
    ]

    # 9. gw supports all subcmds including cco
    ++ [
      (assertInitHas "gw-cco-subcmd" "cc|cco|ccz|oc")
    ]
  );
}
