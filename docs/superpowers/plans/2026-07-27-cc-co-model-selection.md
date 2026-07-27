# cc/co Native Model Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove every `h/m/l` command-name variant for `cc` and `co` while proving both commands forward native `-m/--model` arguments unchanged.

**Architecture:** Keep the existing `cc` function and `co` alias as thin permission-bypass launchers. Exercise the generated shell code against fake `claude` and `codex` executables so tests assert observable argv forwarding and command removal instead of source text alone.

**Tech Stack:** Nix, Home Manager module output, Zsh, shell-based fake executables

## Global Constraints

- Remove `cc-h`, `cc-m`, `cc-l`, `co-h`, `co-m`, and `co-l`.
- Preserve model-less `cc` and `co` behavior and their permission-bypass options.
- Use each CLI's existing `-m/--model` option without adding a parser or model registry.
- Do not change `cco`, `ccz`, or `cck`.

---

## File Structure

- `tests/unit/zsh-claude-wrappers-test.nix`: run the generated `cc` wrapper and `co` alias under real Zsh with controlled fake CLI executables.
- `users/shared/programs/zsh/claude-wrappers.nix`: retain the base Claude launcher and remove only the three `cc-*` functions and obsolete comments.
- `users/shared/programs/zsh/default.nix`: retain the base Codex alias and remove only the three `co-*` aliases.

### Task 1: Replace tier command names with native model options

**Files:**

- Modify: `tests/unit/zsh-claude-wrappers-test.nix`
- Modify: `users/shared/programs/zsh/claude-wrappers.nix`
- Modify: `users/shared/programs/zsh/default.nix`

**Interfaces:**

- Consumes: `cc "$@"` forwarding to `claude --dangerously-skip-permissions`; `co` alias forwarding to `codex --dangerously-bypass-approvals-and-sandbox`.
- Produces: `cc -m <model>` and `co -m <model>` argv forwarding with no `cc-*` or `co-*` tier commands.

- [ ] **Step 1: Write the failing runtime test**

Import the Claude wrapper string and the generated Codex alias:

```nix
claudeWrappers = import ../../users/shared/programs/zsh/claude-wrappers.nix;
coAlias = zshConfigBody.programs.zsh.shellAliases.co;
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

  chmod +x bin/claude bin/codex

  cat > wrappers.zsh <<'EOF'
  ${claudeWrappers}
  alias co=${lib.escapeShellArg coAlias}
  EOF

  PATH="$PWD/bin:$PATH" \
  CLAUDE_ARGS="$PWD/claude.args" \
  CODEX_ARGS="$PWD/codex.args" \
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

  for name in cc-h cc-m cc-l co-h co-m co-l; do
    if whence -w "$name" >/dev/null 2>&1; then
      print -u2 -- "unexpected tier command: $name"
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

Expected: FAIL with `unexpected tier command`, initially for `cc-h`.

- [ ] **Step 3: Remove only the obsolete tier commands**

In `claude-wrappers.nix`, update the header to list base commands and delete:

```zsh
cc-h() {
  ENABLE_TOOL_SEARCH=true command claude --dangerously-skip-permissions --model claude-opus-4-7 "$@"
}

cc-m() {
  ENABLE_TOOL_SEARCH=true command claude --dangerously-skip-permissions --model claude-sonnet-4-6 "$@"
}

cc-l() {
  ENABLE_TOOL_SEARCH=true command claude --dangerously-skip-permissions --model claude-haiku-4-5 "$@"
}
```

Do not change:

```zsh
cc() {
  ENABLE_TOOL_SEARCH=true command claude --dangerously-skip-permissions "$@"
}
```

In `default.nix`, delete only:

```nix
"co-l" = "codex --dangerously-bypass-approvals-and-sandbox -c model_reasoning_effort=low";
"co-m" = "codex --dangerously-bypass-approvals-and-sandbox -c model_reasoning_effort=medium";
"co-h" = "codex --dangerously-bypass-approvals-and-sandbox -c model_reasoning_effort=high";
```

Keep:

```nix
co = "codex --dangerously-bypass-approvals-and-sandbox";
```

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
  users/shared/programs/zsh/claude-wrappers.nix \
  users/shared/programs/zsh/default.nix
git diff --check
git diff -- \
  tests/unit/zsh-claude-wrappers-test.nix \
  users/shared/programs/zsh/claude-wrappers.nix \
  users/shared/programs/zsh/default.nix
```

Expected: formatting succeeds, `git diff --check` prints nothing, and every changed production line traces to removing the six tier commands.

- [ ] **Step 6: Verify the real installed CLIs expose native model selection**

Run:

```shell
claude --help
codex --help
```

Expected: Claude lists `--model <model>` and Codex lists `-m, --model <MODEL>`. The fake-CLI runtime test remains the authoritative proof that the dotfiles wrappers forward those options unchanged.

- [ ] **Step 7: Commit the implementation**

```shell
git add \
  tests/unit/zsh-claude-wrappers-test.nix \
  users/shared/programs/zsh/claude-wrappers.nix \
  users/shared/programs/zsh/default.nix
git commit -m "refactor(zsh): use native model flags for cc and co"
```
