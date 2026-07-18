# tmux Split Bindings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace tmux's default `%` and `"` split keys with `|` for left/right panes and `-` for top/bottom panes.

**Architecture:** Keep the existing Home Manager tmux module and change only its split binding declarations, documentation comments, and focused integration assertions. Preserve `-c "#{pane_current_path}"` so both new panes open in the active pane's directory.

**Tech Stack:** Nix, Home Manager, tmux

## Global Constraints

- `Prefix+|` runs `split-window -h -c "#{pane_current_path}"`.
- `Prefix+-` runs `split-window -v -c "#{pane_current_path}"`.
- Default `%` and `"` bindings are explicitly unbound.
- No unrelated tmux settings change.

---

### Task 1: Replace and verify split bindings

**Files:**

- Modify: `tests/integration/tmux-functionality-test.nix`
- Modify: `users/shared/programs/tmux.nix`

**Interfaces:**

- Consumes: `programs.tmux.extraConfig` from the shared Home Manager module.
- Produces: prefix-table bindings `|` and `-`, with `%` and `"` removed.

- [ ] **Step 1: Write failing integration assertions**

Replace the two existing split assertions and add the default-key assertion:

```nix
  tmux-split-vertical =
    mkConfigTest "tmux-split-vertical" (hasConfigString "bind | split-window -h")
      "tmux should bind | to a left/right split with the current pane path";

  tmux-split-horizontal =
    mkConfigTest "tmux-split-horizontal" (hasConfigString "bind - split-window -v")
      "tmux should bind - to a top/bottom split with the current pane path";

  tmux-default-split-bindings-unbound =
    mkConfigTest "tmux-default-split-bindings-unbound"
      (hasConfigString "unbind '%'" && hasConfigString "unbind '\"'")
      "tmux should unbind the default % and double-quote split keys";
```

- [ ] **Step 2: Run the focused assertions and verify RED**

Run each new contract against the unchanged module:

```bash
for testName in tmux-split-vertical tmux-split-horizontal tmux-default-split-bindings-unbound; do
  nix --extra-experimental-features 'nix-command flakes' build --no-link --impure \
    --expr "let flake = builtins.getFlake (toString ./.); in (import ./tests/integration/tmux-functionality-test.nix { inputs = flake.inputs; system = builtins.currentSystem; }).${testName}" || true
done
```

Expected: all three builds fail with their corresponding assertion messages because `|`, `-`, and the explicit unbinds are absent.

- [ ] **Step 3: Implement the minimal tmux configuration change**

Update the top-level comments to describe `|` and `-`, then replace the pane-management declarations with:

```tmux
        # Intuitive split bindings, keeping the current pane's path
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        unbind '%'
        unbind '"'
```

- [ ] **Step 4: Run focused and full verification**

Run the three focused builds from Step 2 without `|| true`, then run:

```bash
nix --extra-experimental-features 'nix-command flakes' build --no-link --impure \
  --expr 'let flake = builtins.getFlake (toString ./.); tests = import ./tests/integration/tmux-functionality-test.nix { inputs = flake.inputs; system = builtins.currentSystem; }; in builtins.attrValues tests'
git diff --check
```

Expected: all derivations build and `git diff --check` exits 0.

- [ ] **Step 5: Commit the verified implementation**

```bash
git add docs/superpowers/plans/2026-07-19-tmux-split-bindings.md \
  tests/integration/tmux-functionality-test.nix users/shared/programs/tmux.nix
git commit -m "feat(tmux): use intuitive split bindings"
```
