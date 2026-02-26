# Codebase Hygiene & Bug Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use core:executing-plans to implement this plan task-by-task.

**Goal:** Fix actual bugs, remove dead code, and improve infrastructure consistency across the dotfiles codebase.

**Architecture:** Ten independent tasks organized by priority. Bug fixes first, then cleanup, then infrastructure improvements. Each task is self-contained and independently committable.

**Tech Stack:** Nix, Bash, Make, GitHub Actions YAML

---

## Task 1: Fix pipe-while subshell bug in nix-app-linker.sh

The `find ... | while read` on line 109 runs the while loop in a subshell, so `new_apps` counter modifications are never visible to the parent shell. The `[ $new_apps -eq 0 ]` check on line 128 always sees 0.

**Files:**
- Modify: `lib/nix-app-linker.sh:106-129`

**Step 1: Write a test script to reproduce the bug**

Create a test that verifies the counter works:

```bash
# tests/unit/nix-app-linker-test.sh
#!/usr/bin/env bash
set -euo pipefail

# Setup: create fake profile with .app directories
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

profile_dir="$test_dir/profile"
home_apps="$test_dir/Applications"
nix_store="$test_dir/nix-store"

mkdir -p "$profile_dir/share/Applications/TestApp1.app"
mkdir -p "$profile_dir/share/Applications/TestApp2.app"
mkdir -p "$home_apps"
mkdir -p "$nix_store"

# Source the function
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../lib/nix-app-linker.sh"

# Run and capture output
output=$(link_nix_apps "$home_apps" "$nix_store" "$profile_dir" 2>&1)

# The bug: "No new apps to link" is printed even when apps ARE linked
if echo "$output" | grep -q "No new apps to link"; then
  echo "FAIL: Bug reproduced - counter not tracking new apps"
  exit 1
else
  echo "PASS: Counter correctly tracks new apps"
fi
```

**Step 2: Run test to verify it fails**

Run: `bash tests/unit/nix-app-linker-test.sh`
Expected: FAIL (subshell bug causes counter to stay 0)

**Step 3: Fix the bug using process substitution instead of pipe**

In `lib/nix-app-linker.sh`, replace lines 108-128:

```bash
  # 4. Profile app linking (performance optimized)
  if [ -d "$profile" ]; then
    local new_apps=0
    while IFS= read -r app_path; do
      [ ! -d "$app_path" ] && continue

      local app_name=$(basename "$app_path")

      # Skip specialized apps
      [ "$app_name" = "WezTerm.app" ] && continue

      # Skip if valid link already exists
      if [ -L "$home_apps/$app_name" ] && [ -e "$home_apps/$app_name" ]; then
        continue
      fi

      rm -f "$home_apps/$app_name"
      ln -sf "$app_path" "$home_apps/$app_name"
      echo "  ✅ $app_name linked"
      new_apps=$((new_apps + 1))
    done < <(find "$profile" -maxdepth 3 -name "*.app" -type d 2>/dev/null)

    [ $new_apps -eq 0 ] && echo "  ⚡ No new apps to link (all up-to-date)"
  fi
```

Key change: `find ... | while read` → `while read ... done < <(find ...)`. This runs the while loop in the current shell, so `new_apps` modifications persist.

**Step 4: Run test to verify it passes**

Run: `bash tests/unit/nix-app-linker-test.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/nix-app-linker.sh tests/unit/nix-app-linker-test.sh
git commit -m "fix(nix-app-linker): use process substitution to fix subshell counter bug

The pipe-while pattern (find | while read) ran the loop in a subshell,
so new_apps counter was always 0 in the parent shell. Switch to process
substitution (while read < <(find)) to keep the loop in the current shell."
```

---

## Task 2: Fix grep regex injection in gw.nix

In `users/shared/zsh/gw.nix` line 100, `$branch` is interpolated directly into a grep regex pattern. Branch names containing regex metacharacters (`+`, `.`, `*`, etc.) will cause incorrect matches or errors.

**Files:**
- Modify: `users/shared/zsh/gw.nix:98-103`
- Test: `tests/unit/gw-sanitization-test.nix` (new)

**Step 1: Write the failing test**

Add a test that verifies branch name sanitization handles special characters.

In `tests/unit/gw-sanitization-test.nix`:

```nix
{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  gwScript = import ../../users/shared/zsh/gw.nix;
in
{
  gw-grep-uses-fixed-strings = helpers.assertTest "gw-grep-uses-fixed-strings"
    (builtins.match ".*grep -F.*" gwScript != null
      || builtins.match ".*grep --fixed-strings.*" gwScript != null)
    "gw _handle_ref_conflict should use grep -F for literal branch matching";
}
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL - grep currently uses `-E` (regex mode)

**Step 3: Fix by using grep -F for literal string matching**

In `users/shared/zsh/gw.nix`, replace line 100:

Old:
```bash
      local existing_branch=$(git branch --list | grep -E "^\s+$branch/" | head -1 | sed 's/^[* ]*//')
```

New:
```bash
      local existing_branch=$(git branch --list | sed 's/^[* ]*//' | grep -F "$branch/" | head -1)
```

This change:
1. Uses `grep -F` (fixed strings) instead of `grep -E` (extended regex) — no regex metacharacter injection
2. Moves `sed` before `grep` so we strip leading whitespace/asterisks first, then do a simple prefix match

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: PASS

**Step 5: Commit**

```bash
git add users/shared/zsh/gw.nix tests/unit/gw-sanitization-test.nix
git commit -m "fix(gw): use grep -F for literal branch matching in ref conflict handler

Branch names with regex metacharacters (+, ., *, etc.) could cause
incorrect matches or errors. Switch from grep -E to grep -F for
safe literal string matching."
```

---

## Task 3: Remove leftover test-hook files

`test-hook.txt` and `test-hook2.txt` are pre-commit hook testing artifacts left in the repo root.

**Files:**
- Delete: `test-hook.txt`
- Delete: `test-hook2.txt`

**Step 1: Verify files are indeed test artifacts**

```bash
cat test-hook.txt   # Expected: "test change for hook validation"
cat test-hook2.txt  # Expected: "test change for --no-verify"
```

**Step 2: Remove the files**

```bash
git rm test-hook.txt test-hook2.txt
```

**Step 3: Commit**

```bash
git commit -m "chore: remove leftover pre-commit hook test files"
```

---

## Task 4: Remove unused parameters in git.nix and vim.nix

**Files:**
- Modify: `users/shared/git.nix:26`
- Modify: `users/shared/vim.nix:27-32`

**Step 1: Write failing tests**

In `tests/unit/unused-params-test.nix`:

```nix
{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  gitNixContent = builtins.readFile ../../users/shared/git.nix;
  vimNixContent = builtins.readFile ../../users/shared/vim.nix;
in
{
  git-nix-no-unused-pkgs = helpers.assertTest "git-nix-no-unused-pkgs"
    (builtins.match ".*\\{ pkgs,.*" gitNixContent == null)
    "git.nix should not declare unused pkgs parameter";

  vim-nix-minimal-params = helpers.assertTest "vim-nix-minimal-params"
    (builtins.match ".*\\{ pkgs,.*" vimNixContent == null)
    "vim.nix should not declare unused pkgs parameter";
}
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL

**Step 3: Fix git.nix**

Old (line 26):
```nix
{ pkgs, lib, ... }:
```

New:
```nix
{ ... }:
```

**Step 4: Fix vim.nix**

Old (lines 27-32):
```nix
{
  pkgs,
  lib,
  config,
  ...
}:
```

New:
```nix
{ pkgs, ... }:
```

Note: `pkgs` IS used in vim.nix — `with pkgs.vimPlugins` on line 38. Only `lib` and `config` are unused.

**Step 5: Run tests to verify they pass**

Run: `make test`
Expected: PASS (adjust test expectations for vim.nix — pkgs is actually used)

**Step 6: Commit**

```bash
git add users/shared/git.nix users/shared/vim.nix tests/unit/unused-params-test.nix
git commit -m "refactor: remove unused parameters from git.nix and vim.nix

git.nix: remove pkgs and lib (only imports lib/user-info.nix directly)
vim.nix: remove lib and config (only uses pkgs for vimPlugins)"
```

---

## Task 5: Add `format` target to Makefile

CLAUDE.md and devShell shellHook reference `make format` but the target doesn't exist.

**Files:**
- Modify: `Makefile` (add target after line 76, update .PHONY on line 223)

**Step 1: Verify the target is missing**

```bash
make format 2>&1  # Expected: "No rule to make target 'format'"
```

**Step 2: Add the format target**

After the `test-all` target (line 77), add:

```makefile
format:
	$(NIX) fmt
```

Also update the `.PHONY` line (223) to include `format`.

**Step 3: Verify it works**

```bash
make -n format  # Dry run, should print the nix fmt command
```

**Step 4: Commit**

```bash
git add Makefile
git commit -m "feat(Makefile): add format target

CLAUDE.md and devShell shellHook reference 'make format' but the
target was missing. Uses 'nix fmt' which delegates to the flake's
formatter (nixfmt-rfc-style)."
```

---

## Task 6: Add trap cleanup to manual-statusline-test.sh

If the test fails partway through, temporary files created by `mktemp` are leaked. Add a trap-based cleanup.

**Files:**
- Modify: `tests/manual-statusline-test.sh:1-7`

**Step 1: Add trap cleanup**

After line 6 (`STATUSLINE_SCRIPT=...`), add a cleanup mechanism. Replace the individual `rm "$temp_transcript"` calls with a single trap:

Add after line 6:
```bash
# Track temp files for cleanup
TEMP_FILES=()
cleanup() { rm -f "${TEMP_FILES[@]}"; }
trap cleanup EXIT
```

Then change each `temp_transcript=$(mktemp)` to:
```bash
temp_transcript=$(mktemp)
TEMP_FILES+=("$temp_transcript")
```

And remove all individual `rm "$temp_transcript"` lines (lines 106-107, 112-113, 116, 145, 147, 178).

**Step 2: Verify the test still passes**

Run: `bash tests/manual-statusline-test.sh`
Expected: All tests pass, temp files cleaned up on exit

**Step 3: Commit**

```bash
git add tests/manual-statusline-test.sh
git commit -m "fix(tests): add trap cleanup for temp files in manual-statusline-test

Temp files from mktemp were leaked on test failure. Add EXIT trap
to ensure cleanup regardless of exit path."
```

---

## Task 7: Quote PATH variables consistently in zsh initContent

Several PATH exports in `users/shared/zsh/default.nix` don't quote `$HOME`. While `$HOME` rarely contains spaces, consistent quoting is good practice.

**Files:**
- Modify: `users/shared/zsh/default.nix:150-157`

**Step 1: Fix the unquoted PATH lines**

Old (lines 150-157):
```bash
      export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
      export PATH=$HOME/.npm-global/bin:$HOME/.npm-packages/bin:$HOME/bin:$PATH
      export PATH=$HOME/.local/share/bin:$PATH
      export PATH=$HOME/.local/bin:$PATH
      # Cargo (Rust)
      export PATH=$HOME/.cargo/bin:$PATH
      # Go
      export PATH=$HOME/go/bin:$PATH
```

New:
```bash
      export PATH="$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH"
      export PATH="$HOME/.npm-global/bin:$HOME/.npm-packages/bin:$HOME/bin:$PATH"
      export PATH="$HOME/.local/share/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
      # Cargo (Rust)
      export PATH="$HOME/.cargo/bin:$PATH"
      # Go
      export PATH="$HOME/go/bin:$PATH"
```

**Step 2: Run tests**

Run: `make test`
Expected: PASS (quoting doesn't change behavior)

**Step 3: Commit**

```bash
git add users/shared/zsh/default.nix
git commit -m "fix(zsh): quote PATH exports consistently

Several PATH exports didn't quote \$HOME. While unlikely to cause
issues in practice, consistent quoting is defensive best practice."
```

---

## Task 8: Remove redundant nixpkgs-unstable input

`nixpkgs` and `nixpkgs-unstable` both point to `github:NixOS/nixpkgs/nixpkgs-unstable` — they track the exact same branch. The overlay creates `pkgs.unstable` from `nixpkgs-unstable`, but since both are identical, this is redundant.

**Files:**
- Modify: `flake.nix:22-24` (remove nixpkgs-unstable input)
- Modify: `flake.nix:50-61` (remove from outputs args)
- Modify: `flake.nix:64-73` (update overlay to use nixpkgs directly)

**Step 1: Verify both inputs are identical**

```bash
nix flake metadata . --json 2>/dev/null | jq '.locks.nodes.nixpkgs.locked.rev, .locks.nodes["nixpkgs-unstable"].locked.rev'
```

Expected: same commit hash for both.

**Step 2: Update flake.nix**

Remove line 24:
```nix
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
```

Remove `nixpkgs-unstable,` from outputs args (line 54).

Update the overlay (lines 64-73):
```nix
      overlays = [
        (final: prev: {
          # unstable alias - nixpkgs already tracks nixpkgs-unstable
          unstable = prev;

          # Claude Code - latest from flake input
          claude-code = claude-code.packages.${prev.system}.default;
        })
      ];
```

**Step 3: Run tests**

Run: `make test`
Expected: PASS

**Step 4: Update flake.lock**

```bash
nix flake lock
```

**Step 5: Commit**

```bash
git add flake.nix flake.lock
git commit -m "refactor(flake): remove redundant nixpkgs-unstable input

Both nixpkgs and nixpkgs-unstable tracked the same branch
(nixpkgs-unstable). The overlay now aliases unstable = prev
since they're identical."
```

---

## Task 9: Add Nix linting to pre-commit hooks

`deadnix` and `statix` are in devShell but not automated. Add pre-commit hooks so they run automatically.

**Files:**
- Modify: `.pre-commit-config.yaml` (add nix hooks)

**Step 1: Add nix linting hooks**

After the bashate entry (line 28), add:

```yaml
  # Nix linting - dead code detection
  - repo: https://github.com/astro/deadnix
    rev: v1.2.1
    hooks:
      - id: deadnix
        args: ['--no-lambda-pattern-names']

  # Nix linting - anti-pattern detection
  - repo: local
    hooks:
      - id: statix
        name: Statix (Nix anti-patterns)
        entry: statix check
        language: system
        files: '\.nix$'
        pass_filenames: false
```

Note: `deadnix` has a pre-commit hook in its repo. `statix` doesn't, so we use a local hook that depends on it being in devShell.

**Step 2: Verify the hooks work**

```bash
pre-commit run deadnix --all-files
pre-commit run statix --all-files
```

Expected: Pass or report real issues to fix.

**Step 3: Fix any issues found by the linters**

Address any dead code or anti-patterns flagged. This may involve removing unused let bindings, replacing `with` expressions, etc.

**Step 4: Commit**

```bash
git add .pre-commit-config.yaml
# Also add any Nix files fixed by linters
git commit -m "feat(pre-commit): add deadnix and statix Nix linting hooks

deadnix catches unused code (variables, let bindings, function args).
statix catches Nix anti-patterns and suggests improvements.
Both tools were already in devShell but not automated."
```

---

## Task 10: Remove unnecessary CI cache clearing

`ci.yml` lines 49-54 delete `~/.cache/nix` and `~/.local/state/nix` on every run, defeating the purpose of Nix caching and increasing build times.

**Files:**
- Modify: `.github/workflows/ci.yml:49-54` (remove the step)

**Step 1: Remove the cache clearing step**

Delete lines 49-54:
```yaml
      - name: Clear Nix store cache
        shell: bash
        run: |
          echo "Clearing Nix store to avoid stale derivations..."
          rm -rf ~/.cache/nix ~/.local/state/nix || true
          echo "Nix store cache cleared"
```

**Step 2: Verify CI config is valid**

```bash
# Check YAML syntax
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"
```

**Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "perf(ci): remove unnecessary Nix cache clearing step

Every CI run was deleting ~/.cache/nix and ~/.local/state/nix,
defeating Nix caching and increasing build times. The setup-nix
action already handles cache restoration properly."
```

---

## Dependency Graph

All tasks are independent and can be executed in any order. However, a logical sequence:

```
Task 1 (bug fix) ──┐
Task 2 (bug fix) ──┤
Task 3 (cleanup) ──┤
Task 4 (cleanup) ──┼── All independent, any order
Task 5 (infra)  ───┤
Task 6 (cleanup) ──┤
Task 7 (cleanup) ──┤
Task 8 (refactor) ─┤
Task 9 (infra)  ───┤
Task 10 (infra) ───┘
```

Tasks 1-2 are bugs (highest priority). Tasks 3-4, 6-7 are quick wins. Tasks 5, 8-10 are infrastructure improvements.

## Notes for Implementer

- Run `make test` after each task to verify nothing breaks.
- Task 8 (nixpkgs-unstable removal) requires `nix flake lock` to regenerate the lock file.
- Task 9 (pre-commit hooks) may surface additional issues that need fixing — handle them in the same commit.
- Task 4: Double-check `vim.nix` actually uses `pkgs` before removing it (it does — `pkgs.vimPlugins`). Only remove `lib` and `config`.
