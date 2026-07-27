# cc/co Native Model Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep only the `cc`, `co`, and `oc` AI CLI shortcuts while proving `cc` and `co` forward native `-m/--model` arguments unchanged.

**Architecture:** Keep the existing `cc` function plus the `co` and `oc` aliases as thin launchers. Exercise the generated shell code against fake `claude`, `codex`, and `opencode` executables so tests assert observable argv forwarding and command removal instead of source text alone.

**Tech Stack:** Nix, Home Manager module output, Zsh, shell-based fake executables

## Global Constraints

- Remove `cco`, `ccz`, `cck`, all tier variants, and the shared tier parser.
- Preserve model-less `cc` and `co` behavior and their permission-bypass options.
- Use each CLI's existing `-m/--model` option without adding a parser or model registry.
- Preserve the existing `oc = "opencode"` alias.

---

## File Structure

- `tests/unit/zsh-claude-wrappers-test.nix`: run the generated `cc` wrapper plus `co` and `oc` aliases under real Zsh with controlled fake CLI executables.
- `tests/integration/zsh-test.nix`: expect only the retained AI CLI shortcuts from the evaluated Zsh module.
- `users/shared/programs/zsh/claude-wrappers.nix`: retain only the base `cc` launcher.
- `users/shared/programs/zsh/default.nix`: retain only the base `co` and `oc` aliases.

### Task 1: Replace tier command names with native model options

**Files:**

- Modify: `tests/unit/zsh-claude-wrappers-test.nix`
- Modify: `tests/integration/zsh-test.nix`
- Modify: `users/shared/programs/zsh/claude-wrappers.nix`
- Modify: `users/shared/programs/zsh/default.nix`

**Interfaces:**

- Consumes: `cc "$@"` forwarding to `claude --dangerously-skip-permissions`; `co` forwarding to `codex --dangerously-bypass-approvals-and-sandbox`; `oc` forwarding to `opencode`.
- Produces: exactly three AI CLI shortcuts, with native model argv forwarding through `cc` and `co`.

- [ ] **Step 1: Write the failing runtime test**

Import the Claude wrapper string and the generated Codex alias:

```nix
claudeWrappers = import ../../users/shared/programs/zsh/claude-wrappers.nix;
coAlias = zshConfigBody.programs.zsh.shellAliases.co;
ocAlias = zshConfigBody.programs.zsh.shellAliases.oc;
```

Add a `pkgs.runCommand` test with fake executables that record one argument per line:

```nix
runtimeTest = pkgs.runCommand "zsh-cc-co-model-runtime" {
  nativeBuildInputs = [
    pkgs.zsh
    pkgs.coreutils
  ];
} ''
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

  cat > wrappers.zsh <<'EOF'
  ${claudeWrappers}
  alias co=${lib.escapeShellArg coAlias}
  alias oc=${lib.escapeShellArg ocAlias}
  EOF

  PATH="$PWD/bin:$PATH" \
  CLAUDE_ARGS="$PWD/claude.args" \
  CODEX_ARGS="$PWD/codex.args" \
  OPENCODE_ARGS="$PWD/opencode.args" \
  zsh -f <<'EOF'
  source ./wrappers.zsh

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
```

Include `runtimeTest` in the existing suite with `builtins.pathExists`. The production change that makes this test pass is removal of the six tier commands; changing either base launcher to drop `"$@"` or either bypass option makes its argv comparison fail.

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```shell
nix build ".#checks.$(nix eval --raw --impure --expr builtins.currentSystem).unit-zsh-claude-wrappers" -L
```

Expected: FAIL with `unexpected AI CLI command`, initially for `_cc_run`.

- [ ] **Step 3: Retain only `cc`, `co`, and `oc`**

Replace `claude-wrappers.nix` with the single retained wrapper:

```nix
# Claude Code wrapper function for Zsh
''
cc() {
  ENABLE_TOOL_SEARCH=true command claude --dangerously-skip-permissions "$@"
}
''
```

In `default.nix`, remove the three Codex tier aliases and keep:

```nix
oc = "opencode";
co = "codex --dangerously-bypass-approvals-and-sandbox";
```

Update `tests/integration/zsh-test.nix` to retain positive assertions for `cc`,
`co`, and `oc`, and remove the old positive assertions for `cco`, `ccz`,
`cck`, and `_cc_parse_model_flags`.

- [ ] **Step 4: Run focused and neighboring tests and verify GREEN**

Run:

```shell
nix build \
  ".#checks.$(nix eval --raw --impure --expr builtins.currentSystem).unit-zsh-claude-wrappers" \
  ".#checks.$(nix eval --raw --impure --expr builtins.currentSystem).integration-zsh" \
  -L
```

Expected: both derivations build successfully and the runtime test emits no diff.

- [ ] **Step 5: Format and inspect the exact scope**

Run:

```shell
nix fmt -- \
  tests/unit/zsh-claude-wrappers-test.nix \
  tests/integration/zsh-test.nix \
  users/shared/programs/zsh/claude-wrappers.nix \
  users/shared/programs/zsh/default.nix
git diff --check
git diff -- \
  tests/unit/zsh-claude-wrappers-test.nix \
  tests/integration/zsh-test.nix \
  users/shared/programs/zsh/claude-wrappers.nix \
  users/shared/programs/zsh/default.nix
```

Expected: formatting succeeds, `git diff --check` prints nothing, and every changed production line traces to removing the six tier commands.

- [ ] **Step 6: Verify the real installed CLIs expose native model selection**

Run:

```shell
claude -m opus --version
codex -m gpt-5.6-sol --version
```

Expected: both installed CLIs accept the native model option and print their
versions without starting a paid model request. The fake-CLI runtime test
remains the authoritative proof that the dotfiles wrappers forward those
options unchanged.

- [ ] **Step 7: Commit the implementation**

```shell
git add \
  tests/unit/zsh-claude-wrappers-test.nix \
  tests/integration/zsh-test.nix \
  users/shared/programs/zsh/claude-wrappers.nix \
  users/shared/programs/zsh/default.nix
git commit -m "refactor(zsh): use native model flags for cc and co"
```
