# Zsh AI CLI shortcut tests
#
# Verifies the retained cc/co/oc commands under a real Zsh with fake CLIs.
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
    isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
    config = mockConfig.mkEmptyConfig // {
      modules.programs.zsh.enable = true;
      home = {
        homeDirectory = "/home/testuser";
      };
    };
  };
  zshConfigBody = zshModule.config.content;

  aliases = zshConfigBody.programs.zsh.shellAliases or { };
  claudeWrapper = import ../../users/shared/programs/zsh/claude-wrappers.nix;

  runtimeTest =
    pkgs.runCommand "zsh-ai-cli-shortcuts-runtime"
      {
        nativeBuildInputs = [
          pkgs.zsh
          pkgs.coreutils
        ];
      }
      ''
        mkdir -p bin

        cat > bin/claude <<'EOF'
        #!/bin/sh
        printf '%s\n' "$@" > "$CLAUDE_ARGS"
        EOF

        cat > bin/codex <<'EOF'
        #!/bin/sh
        printf '%s\n' "$@" > "$CODEX_ARGS"
        EOF

        cat > bin/opencode <<'EOF'
        #!/bin/sh
        printf '%s\n' "$@" > "$OPENCODE_ARGS"
        EOF

        chmod +x bin/claude bin/codex bin/opencode

        cat > shortcuts.zsh <<'EOF'
        ${claudeWrapper}
        alias co=${lib.escapeShellArg aliases.co}
        alias oc=${lib.escapeShellArg aliases.oc}
        EOF

        PATH="$PWD/bin:$PATH" \
        CLAUDE_ARGS="$PWD/claude.args" \
        CODEX_ARGS="$PWD/codex.args" \
        OPENCODE_ARGS="$PWD/opencode.args" \
        zsh -f <<'EOF'
        source ./shortcuts.zsh

        cc -m opus
        printf '%s\n' \
          --dangerously-skip-permissions \
          -m \
          opus > expected-claude.args
        diff -u expected-claude.args "$CLAUDE_ARGS"

        cc
        printf '%s\n' \
          --dangerously-skip-permissions > expected-claude.args
        diff -u expected-claude.args "$CLAUDE_ARGS"

        co -m gpt-5.6-sol
        printf '%s\n' \
          --dangerously-bypass-approvals-and-sandbox \
          -m \
          gpt-5.6-sol > expected-codex.args
        diff -u expected-codex.args "$CODEX_ARGS"

        co
        printf '%s\n' \
          --dangerously-bypass-approvals-and-sandbox > expected-codex.args
        diff -u expected-codex.args "$CODEX_ARGS"

        oc run
        printf '%s\n' run > expected-opencode.args
        diff -u expected-opencode.args "$OPENCODE_ARGS"

        for name in \
          _cc_run _cc_parse_model_flags \
          cc-h cc-m cc-l \
          cco cco-h cco-m cco-l \
          ccz cck \
          co-h co-m co-l; do
          if whence -w "$name" >/dev/null 2>&1; then
            print -u2 -- "unexpected AI CLI command: $name"
            exit 1
          fi
        done
        EOF

        touch "$out"
      '';

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "zsh-ai-cli-shortcuts" [
    (helpers.assertTest "zsh-ai-cli-runtime" (builtins.pathExists runtimeTest)
      "cc/co/oc runtime behavior failed"
    )
  ];
}
