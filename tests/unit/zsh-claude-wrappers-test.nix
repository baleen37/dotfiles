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
  claudeWrapper = import ../../users/shared/programs/zsh/claude-wrappers.nix {
    inherit lib;
    isDarwin = false;
  };
  darwinClaudeWrapper = import ../../users/shared/programs/zsh/claude-wrappers.nix {
    inherit lib;
    isDarwin = true;
  };

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

  darwinKeychainRuntimeTest =
    pkgs.runCommand "zsh-claude-keychain-runtime"
      {
        nativeBuildInputs = [
          pkgs.zsh
          pkgs.coreutils
        ];
      }
      ''
        mkdir -p bin home/Library/Keychains

        cat > bin/claude <<'EOF'
        #!/bin/sh
        printf '%s\n' "$@" > "$CLAUDE_ARGS"
        EOF

        cat > bin/security <<'EOF'
        #!/bin/sh
        printf '%s\n' "$*" >> "$SECURITY_LOG"
        case "$1" in
          show-keychain-info)
            test -e "$KEYCHAIN_UNLOCKED"
            ;;
          unlock-keychain)
            test -z "$SECURITY_UNLOCK_FAIL" || exit 1
            touch "$KEYCHAIN_UNLOCKED"
            ;;
          set-keychain-settings)
            ;;
          *)
            exit 2
            ;;
        esac
        EOF

        chmod +x bin/claude bin/security

        cat > shortcuts.zsh <<'EOF'
        ${darwinClaudeWrapper}
        EOF

        PATH="$PWD/bin:$PATH" \
        HOME="$PWD/home" \
        CLAUDE_ARGS="$PWD/claude.args" \
        SECURITY_LOG="$PWD/security.log" \
        KEYCHAIN_UNLOCKED="$PWD/keychain-unlocked" \
        zsh -f <<'EOF'
        source ./shortcuts.zsh

        # Loading the shell configuration must not touch the keychain.
        test ! -e "$SECURITY_LOG"

        # Local Claude usage must not touch the SSH-only keychain path.
        cc
        test ! -e "$SECURITY_LOG"

        # The first SSH invocation unlocks the keychain and clears its timeout.
        export SSH_CONNECTION="client 1234 server 22"
        cc -m opus
        keychain="$HOME/Library/Keychains/login.keychain-db"
        printf '%s\n' \
          "show-keychain-info $keychain" \
          "unlock-keychain $keychain" \
          "set-keychain-settings $keychain" > expected-security.log
        diff -u expected-security.log "$SECURITY_LOG"

        # Later invocations only check that the keychain remains unlocked.
        cc
        printf '%s\n' \
          "show-keychain-info $keychain" >> expected-security.log
        diff -u expected-security.log "$SECURITY_LOG"

        # A failed unlock must not start Claude.
        rm -f "$KEYCHAIN_UNLOCKED" "$CLAUDE_ARGS"
        export SECURITY_UNLOCK_FAIL=1
        if cc; then
          print -u2 -- "cc succeeded after a failed keychain unlock"
          exit 1
        fi
        test ! -e "$CLAUDE_ARGS"
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
    (helpers.assertTest "zsh-claude-keychain-runtime" (builtins.pathExists darwinKeychainRuntimeTest)
      "Claude keychain lazy-unlock behavior failed"
    )
  ];
}
