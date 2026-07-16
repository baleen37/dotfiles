# Mosh + tmux Truecolor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve 24-bit colors when Ghostty reaches remote tmux through mosh.

**Architecture:** Keep the existing `tmux-256color` inner terminal and teach tmux that mosh's outer `xterm-256color` client supports RGB. Guard the contract with the existing Home Manager module integration test, then build and activate the `baleen` Home Manager closure remotely and verify through a fresh isolated mosh session.

**Tech Stack:** Nix, Home Manager, tmux 3.7b, mosh 1.4.0, SSH

## Global Constraints

- Retain the existing `xterm-ghostty:RGB` terminal feature.
- Add only RGB support for `xterm-256color`; do not add `extkeys`.
- Do not change mosh prediction behavior or upgrade terminal packages.
- Do not refactor unrelated tmux configuration.

---

### Task 1: Declare and test mosh truecolor support

**Files:**
- Modify: `tests/integration/tmux-functionality-test.nix`
- Modify: `users/shared/programs/tmux.nix`

**Interfaces:**
- Consumes: `programs.tmux.extraConfig` from the shared Home Manager module.
- Produces: `terminal-features` entry `xterm-256color:RGB` for mosh-facing tmux clients.

- [ ] **Step 1: Write the failing integration test**

Add this assertion after `tmux-set-titles`:

```nix
  tmux-mosh-truecolor =
    mkConfigTest "tmux-mosh-truecolor"
      (hasConfigString "set -as terminal-features ',xterm-256color:RGB'")
      "tmux should preserve truecolor when mosh presents xterm-256color";
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
nix --extra-experimental-features 'nix-command flakes' build --no-link --impure \
  --expr 'let flake = builtins.getFlake (toString ./.); in (import ./tests/integration/tmux-functionality-test.nix { inputs = flake.inputs; system = builtins.currentSystem; }).tmux-mosh-truecolor'
```

Expected: FAIL with `tmux should preserve truecolor when mosh presents xterm-256color`.

- [ ] **Step 3: Add the minimal tmux capability**

Extend the truecolor section in `users/shared/programs/tmux.nix`:

```nix
        # Mosh 1.4 preserves truecolor and exports COLORTERM=truecolor, but its
        # outer terminal is xterm-256color rather than xterm-ghostty.
        set -as terminal-features ',xterm-256color:RGB'
```

- [ ] **Step 4: Run the focused test and Darwin smoke verification**

Run the focused command from Step 2 again.

Expected: PASS and a built `test-tmux-mosh-truecolor-pass` derivation.

Run:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix --extra-experimental-features 'nix-command flakes' \
  eval '.#checks.aarch64-darwin.smoke' --impure --accept-flake-config
```

Expected: exit 0 and a smoke-test derivation.

- [ ] **Step 5: Commit the tested change**

```bash
git add tests/integration/tmux-functionality-test.nix users/shared/programs/tmux.nix
git commit -m "fix(tmux): preserve truecolor over mosh"
```

---

### Task 2: Activate and verify on baleen-macbook

**Files:**
- Read: `flake-modules/home.nix`
- Runtime target: `baleen@baleens-macbook.ojos-in.ts.net`

**Interfaces:**
- Consumes: `homeConfigurations.baleen.activationPackage` produced by the flake.
- Produces: active remote tmux config whose fresh mosh client includes `RGB`.

- [ ] **Step 1: Build and copy the Home Manager activation closure**

Run:

```bash
activation=$(NIXPKGS_ALLOW_UNFREE=1 nix --extra-experimental-features 'nix-command flakes' \
  build '.#homeConfigurations.baleen.activationPackage' --no-link \
  --print-out-paths --impure --accept-flake-config)
nix copy --to 'ssh-ng://baleen@baleens-macbook.ojos-in.ts.net' "$activation"
```

Expected: one activation package path and successful closure copy.

- [ ] **Step 2: Activate and reload the existing tmux server**

Run:

```bash
ssh baleen@baleens-macbook.ojos-in.ts.net "$activation/activate"
ssh baleen@baleens-macbook.ojos-in.ts.net \
  'tmux source-file ~/.config/tmux/tmux.conf && tmux show-options -g terminal-features'
```

Expected: activation succeeds and `terminal-features` contains both `xterm-ghostty:RGB` and `xterm-256color:RGB`.

- [ ] **Step 3: Verify through a fresh isolated mosh + tmux client**

Start mosh with `/bin/zsh -f`, then run:

```bash
tmux -L codex-mosh-verify -f ~/.config/tmux/tmux.conf new-session -s verify /bin/zsh -f
printf '\e[48;2;1;2;3mRGB_VERIFY\e[0m\n'
```

From SSH, run:

```bash
tmux -L codex-mosh-verify list-clients -F \
  'term=#{client_termname} features=#{client_termfeatures}'
```

Expected: client term is `xterm-256color`, features include `RGB`, and the mosh output preserves `48;2;1;2;3` rather than reducing it to `48;5`.

- [ ] **Step 4: Clean up verification processes and record evidence**

Exit the isolated tmux pane and mosh shell. Confirm:

```bash
ssh baleen@baleens-macbook.ojos-in.ts.net \
  'tmux -L codex-mosh-verify list-sessions 2>&1 || true; ps -axo command= | grep "[m]osh-server new" || true'
```

Expected: no `codex-mosh-verify` server and no mosh server created by verification.
