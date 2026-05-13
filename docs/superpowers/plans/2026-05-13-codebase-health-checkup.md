# Codebase Health Checkup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 이전 두 번의 리팩토링 이후 남은 잔재(문서-Make 타겟 불일치, 사용되지 않는 헬퍼, 거짓 의존 신호, 흩어진 테스트 문서, 미정렬 nix 파일)를 외과적으로 정리한다.

**Architecture:** 2단계 구조. **Stage 1** = 문서-현실 정합성(Makefile 별칭 3개, README/CONTRIBUTING 정정, `.envrc` USER 자동화, nixfmt 일괄). **Stage 2** = dead code removal(중복 helper 삭제, 거짓 파라미터 정리, 테스트 문서 통합). 각 task가 독립 커밋이라 단일 `git revert`로 되돌릴 수 있다.

**Tech Stack:** Nix flakes, flake-parts, Make, pre-commit, direnv, nixfmt-rfc-style.

**Spec:** [`docs/superpowers/specs/2026-05-13-codebase-health-checkup-design.md`](../specs/2026-05-13-codebase-health-checkup-design.md)

---

## File Inventory

| File | Action |
|---|---|
| `Makefile` | Modify — add 3 targets (`install-hooks`, `lint`, `update`) |
| `README.md` | Modify — replace 9+ fake make calls, soften USER export note |
| `CONTRIBUTING.md` | Modify — replace 4+ fake make calls |
| `CLAUDE.md` | Modify — soften "USER required" note |
| `.envrc` | Modify — add USER fallback |
| flake.nix, lib/mksystem.nix, flake-modules/{dev-shells,checks,packages}.nix, users/shared/{zsh/{env,functions,ssh-agent},ghostty}.nix | Modify via `make format` |
| `tests/lib/test-helpers-darwin.nix` | Delete |
| `tests/lib/test-helpers.nix` | Modify — remove the dead reference if any |
| `users/shared/claude-code.nix` | Modify — `_: { }` |
| `docs/testing-guide.md` | Delete (stale, lists non-existent file names) |
| `tests/TESTING_GUIDE.md` | Keep as-is (Korean companion to README.md, distinct value) |
| Anything linking to `docs/testing-guide.md` | Modify — repoint to `tests/README.md` |

---

## Stage 1 — Doc-Reality Alignment

### Task 1: Add `install-hooks`, `lint`, `update` Makefile targets

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Inspect current Makefile structure to choose insertion point**

Run: `grep -n '^[a-zA-Z][a-zA-Z0-9_-]*:' Makefile`
Expected: existing targets include `switch`, `test`, `test-integration`, `test-all`, `format`, `test-containers`, `cache`, `wsl`. Find the line of the `.PHONY` declaration (if any) and the location of an existing simple target like `format` to use as a placement reference.

- [ ] **Step 2: Add three new targets at the end of the Makefile**

Append (exact text, with tabs not spaces for recipe lines — Make requirement):

```makefile

install-hooks:
	pre-commit install --hook-type pre-commit --hook-type pre-push

lint:
	pre-commit run --all-files

update:
	nix flake update
```

If the Makefile uses `.PHONY:` declarations, add `install-hooks lint update` to the list. Check with:

```bash
grep -n '^\.PHONY' Makefile
```

If `.PHONY` exists, edit it to include the new names.

- [ ] **Step 3: Verify each target is invocable**

Run:
```bash
make -n install-hooks
make -n lint
make -n update
```

Expected: each prints the recipe without errors. Real execution skipped to keep the step fast and side-effect-free.

- [ ] **Step 4: Run `make lint` for real to confirm it works end-to-end**

Run: `make lint`
Expected: pre-commit executes all hooks and either reports PASS or specific issues. Either is acceptable — issues will be addressed in later tasks.

- [ ] **Step 5: Commit**

```bash
git add Makefile
git commit -m "build(make): add install-hooks, lint, update target aliases

README and CONTRIBUTING already reference these targets. Each is a
one-line alias to the underlying tool (pre-commit, nix flake update),
matching what the docs promise."
```

---

### Task 2: Strip fake make targets from README.md

**Files:**
- Modify: `README.md`

Fake targets referenced in README that DO NOT exist in Makefile (verified via `grep -E '^[a-z][a-z0-9_-]*:' Makefile`):
- `make build` (lines 100, 217, 385)
- `make build-darwin` (line 115)
- `make build-linux` (line 116)
- `make vm/bootstrap0`, `make vm/bootstrap`, `make vm/copy`, `make vm/switch`, `make vm/secrets` (lines 264, 267, 270, 273, 276)

Targets that DO exist after Task 1: `install-hooks`, `lint`, `update`, `test`, `test-all`, `test-integration`, `switch`, `build-switch`, `format`, `test-containers`, `cache`, `wsl`.

- [ ] **Step 1: Read the README sections that mention the fake targets**

Read: `README.md` at lines 95-120, 215-280, 380-390. Identify each `make build*` and `make vm/*` reference and the surrounding context — some are in shell code blocks, some in bullet lists.

- [ ] **Step 2: Replace `make build` references with direct nix invocations**

For each occurrence of `make build` (not `build-switch`), replace with `nix build '.#darwinConfigurations.macbook-pro.system' --impure` (or the appropriate machine name from context). Use the Edit tool with surrounding context to disambiguate; do NOT use replace_all because the surrounding sentences differ.

Example edit at README.md ~line 100:
```
# Before:
make build             # Build everything

# After:
nix build '.#darwinConfigurations.macbook-pro.system' --impure   # Build (substitute your machine)
```

For the troubleshooting section (~line 385: "make build  # Retry"), use `nix build '.#darwinConfigurations.<your-machine>.system' --impure  # Retry`.

- [ ] **Step 3: Replace `make build-darwin` and `make build-linux`**

At README.md lines 115-116:

```
# Before:
make build-darwin   # macOS configurations (x86_64, aarch64)
make build-linux    # NixOS configurations (x86_64, aarch64)

# After:
nix build '.#darwinConfigurations.macbook-pro.system' --impure   # macOS
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel' --impure   # NixOS
```

- [ ] **Step 4: Remove the `make vm/*` block (lines ~260-280)**

This entire VM bootstrap section refers to targets that don't exist. Replace the code block with a short pointer:

```
# Before (the block with vm/bootstrap0, vm/bootstrap, vm/copy, vm/switch, vm/secrets):
...

# After:
For NixOS VM workflows, build with:

\`\`\`bash
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel' --impure
\`\`\`

See `machines/nixos/` for available VM configurations.
```

(Adapt the wording to match README's existing tone — keep neighboring headings intact.)

- [ ] **Step 5: Soften the "USER export required" note**

Find each "export USER=$(whoami)" in README.md (Bash check):
```bash
grep -n 'export USER' README.md
```

For each occurrence, change the surrounding text from "Required before any Nix commands" to "Required for Nix commands (set automatically by direnv when entering the directory)".

Be surgical: only the explanatory comment changes, not the command itself — first-time setup users may not have direnv ready.

- [ ] **Step 6: Verify no fake targets remain**

Run:
```bash
grep -oE 'make [a-z0-9/_-]+' README.md | sort -u
```

Expected output should be a subset of:
```
make build-switch
make cache
make format
make install-hooks
make lint
make switch
make test
make test-all
make test-containers
make test-integration
make update
make wsl
```

No `make build`, `make build-darwin`, `make build-linux`, or `make vm/*` should appear.

- [ ] **Step 7: Commit**

```bash
git add README.md
git commit -m "docs(readme): replace non-existent make targets with nix build calls

make build, build-darwin, build-linux, and vm/* were never real targets.
Replace with direct \`nix build '.#…'\` invocations that match what the
flake actually exposes. Soften the USER export note to mention direnv."
```

---

### Task 3: Strip fake make targets from CONTRIBUTING.md

**Files:**
- Modify: `CONTRIBUTING.md`

Fake targets in CONTRIBUTING.md (verified):
- `make build` (lines 69, 83, 217, 411)
- `make test-unit` (line 96)
- `make test-e2e` (line 98)
- `make test-status` (line 393)

After Task 1, `make lint` is real, so the lines 29, 66, 80 references are now valid.

- [ ] **Step 1: Replace `make build` references**

For each `make build` in CONTRIBUTING.md, substitute with `nix build '.#darwinConfigurations.macbook-pro.system' --impure`. Use Edit with surrounding context for each line.

- [ ] **Step 2: Handle `make test-unit`, `make test-e2e`, `make test-status`**

At lines 96-98:
```
# Before:
make test-unit                    # Unit tests only
make test-integration             # Integration tests only
make test-e2e                     # End-to-end tests only (Linux only)

# After:
nix flake check --impure          # All checks (auto-discovered tests)
make test-integration             # Traditional integration tests
nix build '.#checks.x86_64-linux.basic' --impure   # Single check (Linux containers)
```

At line 393, replace `make test-status` with a real diagnostic invocation or remove the line if it has no real equivalent:
```bash
grep -B2 -A2 'make test-status' CONTRIBUTING.md
```
If the surrounding context promises a "test status" command that doesn't exist, replace with `nix flake show --impure` (the closest real diagnostic).

- [ ] **Step 3: Verify**

Run:
```bash
grep -oE 'make [a-z0-9/_-]+' CONTRIBUTING.md | sort -u
```

Expected subset (no `build`, `test-unit`, `test-e2e`, `test-status`):
```
make format
make install-hooks
make lint
make switch
make test
make test-all
make test-integration
make update
```

- [ ] **Step 4: Commit**

```bash
git add CONTRIBUTING.md
git commit -m "docs(contributing): replace non-existent make targets with real commands

Same cleanup as the README pass: substitute fake make build*, test-unit,
test-e2e, test-status references with the equivalent nix or make calls
that actually work."
```

---

### Task 4: Soften USER export note in CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Find the note**

Run:
```bash
grep -n 'export USER\|USER environment' CLAUDE.md
```

The note lives near the "Environment Setup" section.

- [ ] **Step 2: Update wording**

Find the block (approximately):
```
All build operations require the USER environment variable:

\`\`\`bash
export USER=$(whoami)  # Required before any Nix commands
\`\`\`
```

Replace with:
```
All build operations require the USER environment variable. When working
inside the project directory, direnv sets this automatically. For shells
without direnv:

\`\`\`bash
export USER=$(whoami)
\`\`\`
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude): note direnv handles USER export automatically"
```

---

### Task 5: Auto-set USER in `.envrc`

**Files:**
- Modify: `.envrc`

- [ ] **Step 1: Verify current contents**

Run: `cat .envrc`
Expected output:
```
use flake
```

- [ ] **Step 2: Edit `.envrc`**

Replace contents with:
```
export USER=${USER:-$(whoami)}
use flake
```

The `${USER:-…}` form preserves explicit overrides; users who set USER manually for cross-user builds keep that behavior.

- [ ] **Step 3: Reload direnv and verify**

Run:
```bash
direnv reload
echo "$USER"
```

Expected: a non-empty username (e.g., `jito.hello`).

If direnv isn't installed in the shell, skip live reload — the change is verified by `cat .envrc` showing the new content.

- [ ] **Step 4: Commit**

```bash
git add .envrc
git commit -m "build(envrc): auto-set USER fallback for shells without it

\${USER:-\$(whoami)} preserves explicit overrides while removing the need
for manual export in fresh shells."
```

---

### Task 6: Run `make format` and commit nixfmt baseline

**Files:**
- Modify: flake.nix, lib/mksystem.nix, flake-modules/dev-shells.nix, flake-modules/checks.nix, flake-modules/packages.nix, users/shared/zsh/env.nix, users/shared/zsh/functions.nix, users/shared/zsh/ssh-agent.nix, users/shared/ghostty.nix (any other file `make format` touches)

- [ ] **Step 1: Confirm `make format` exists and uses the project formatter**

Run: `grep -A3 '^format:' Makefile`
Expected: invokes `nix run .#format` or `nixfmt-rfc-style`. If unclear, run `make -n format` to see the recipe.

- [ ] **Step 2: Run formatter**

Run: `USER=$(whoami) make format`

Expected: command exits 0. Some files in the worktree are reformatted in place.

- [ ] **Step 3: Inspect the diff**

Run: `git status && git diff --stat`

Expected: 1-9 .nix files modified, only whitespace/layout changes. If non-whitespace diffs appear, STOP and inspect — formatter shouldn't change semantics.

- [ ] **Step 4: Run tests to confirm no regression**

Run: `USER=$(whoami) make test`
Expected: PASS (Linux) or validation mode succeeds (macOS).

- [ ] **Step 5: Verify formatter is idempotent**

Run:
```bash
USER=$(whoami) make format
git diff --quiet
```

Expected: `git diff --quiet` exits 0 (no diff after second run). If it fails, the formatter has drift between runs — investigate before committing.

- [ ] **Step 6: Commit**

```bash
git add -u
git commit -m "style: nixfmt baseline across previously-unformatted files

Catch-up pass for files that drifted before pre-commit covered them.
No semantic changes — pure whitespace/layout."
```

---

## Stage 2 — Dead Code Removal

### Task 7: Delete duplicate `tests/lib/test-helpers-darwin.nix`

**Files:**
- Delete: `tests/lib/test-helpers-darwin.nix`
- Modify: `tests/lib/test-helpers.nix` (only if it references the deleted file)

- [ ] **Step 1: Confirm zero usage**

Run:
```bash
grep -rn 'test-helpers-darwin' .
```

Expected: hits only in `tests/lib/test-helpers-darwin.nix` itself (self) and possibly comments/imports in `tests/lib/test-helpers.nix`. NO test file should import this name.

If a real import surfaces, STOP — the audit assumed zero usage; investigate before deleting.

- [ ] **Step 2: Locate references to remove from `test-helpers.nix`**

Run:
```bash
grep -n 'test-helpers-darwin' tests/lib/test-helpers.nix
```

If results found, prepare to remove those lines. If empty, skip Step 4.

- [ ] **Step 3: Delete the file**

Run: `git rm tests/lib/test-helpers-darwin.nix`

- [ ] **Step 4: Remove references from `test-helpers.nix` (if any)**

For each reference found in Step 2, use Edit to remove the line(s). Typical patterns to remove:
- `import ./test-helpers-darwin.nix { ... };`
- A `darwinHelpers` let binding plus its `// darwinHelpers` merge
- Comments mentioning the file

After edits, verify with:
```bash
grep -n 'test-helpers-darwin' tests/lib/test-helpers.nix
```
Expected: empty.

- [ ] **Step 5: Run tests**

Run: `USER=$(whoami) make test-all`
Expected: PASS. The real Darwin helpers are in `darwin-test-helpers.nix` (still present), which is what the actual Darwin tests import.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "test(lib): drop unused test-helpers-darwin.nix

161-line shim that was never imported by any test. The Darwin assertion
helpers actually used by tests live in darwin-test-helpers.nix (514
lines), which remains the canonical source."
```

---

### Task 8: Remove false parameters from `users/shared/claude-code.nix`

**Files:**
- Modify: `users/shared/claude-code.nix`

- [ ] **Step 1: Read the file**

Run: `cat users/shared/claude-code.nix`

Expected: ~14 lines, signature `{ pkgs, lib, ... }:` returning `{ }` (or near-empty).

- [ ] **Step 2: Replace the signature**

Edit `users/shared/claude-code.nix`:

```
# Before:
{ pkgs, lib, ... }:
{ }

# After:
_: { }
```

If the file has any body content beyond `{ }` (top comments, etc.), keep them; only the parameter pattern changes.

- [ ] **Step 3: Build the home configuration to confirm the import path still works**

Run:
```bash
USER=$(whoami) nix build '.#homeConfigurations."jito.hello".activationPackage' --impure --dry-run
```

Expected: builds successfully. (Substitute another user/machine name if the worktree's user differs.)

- [ ] **Step 4: Run tests**

Run: `USER=$(whoami) make test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add users/shared/claude-code.nix
git commit -m "refactor(claude-code): drop unused pkgs/lib parameters

The module returns {} and never references pkgs or lib. The named
parameters were a false signal of dependency on the module system."
```

---

### Task 9: Delete stale `docs/testing-guide.md` and repoint references

**Files:**
- Delete: `docs/testing-guide.md`
- Modify: any markdown file linking to `docs/testing-guide.md`

`tests/README.md` is canonical. `tests/TESTING_GUIDE.md` (Korean) stays — it's a distinct artifact, not a duplicate.

- [ ] **Step 1: Find every reference to `docs/testing-guide.md`**

Run:
```bash
grep -rln 'docs/testing-guide.md\|docs/testing-guide' . 2>/dev/null | grep -v '.git\|\.direnv\|\.worktrees'
```

Note the files that link to the doc.

- [ ] **Step 2: Repoint each reference to `tests/README.md`**

For each file found, use Edit to replace the path. Examples:
- `[Testing Guide](docs/testing-guide.md)` → `[Testing Guide](tests/README.md)` (adjust relative path for the linking file's location)
- Plain-text mentions: `docs/testing-guide.md` → `tests/README.md`

Repeat until no references remain.

- [ ] **Step 3: Delete the file**

Run: `git rm docs/testing-guide.md`

- [ ] **Step 4: Verify no broken links**

Run:
```bash
grep -rln 'docs/testing-guide' . 2>/dev/null | grep -v '.git\|\.direnv\|\.worktrees'
```
Expected: empty.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "docs: drop stale docs/testing-guide.md, repoint to tests/README.md

The file referenced renamed helpers (enhanced-assertions.nix,
test-runner.nix, mksystem-factory-validation.nix) that no longer exist.
tests/README.md is the canonical guide; tests/TESTING_GUIDE.md (Korean)
remains as its language companion."
```

---

## Final Verification

### Task 10: Full regression check

- [ ] **Step 1: Re-run all checks together**

Run:
```bash
USER=$(whoami) make test-all
pre-commit run --all-files
```

Expected: both PASS. If `pre-commit` shows new format issues, run `make format` and amend the last commit (or add a follow-up commit).

- [ ] **Step 2: Verify branch ahead of main with clean tree**

Run:
```bash
git status
git log main..HEAD --oneline
```

Expected:
- working tree clean
- 9 commits on top of main: Tasks 1–9 each = 1 commit; Task 10 has no commit (verification only)

- [ ] **Step 3: Spot-check each fake target is gone**

Run:
```bash
grep -oE 'make [a-z0-9/_-]+' README.md CONTRIBUTING.md | sort -u
```

Expected: every listed `make X` corresponds to a target that exists in `Makefile`. Cross-reference with `grep -E '^[a-zA-Z][a-zA-Z0-9_-]*:' Makefile`.

- [ ] **Step 4: Verify deleted files stay deleted**

Run:
```bash
test ! -f tests/lib/test-helpers-darwin.nix && echo "OK"
test ! -f docs/testing-guide.md && echo "OK"
```

Expected: two OKs.

---

## Notes for the Implementer

- **No flag-skipping**: never use `--no-verify` on commits. If pre-commit fails, fix the issue and recommit (do not amend silently — make a new commit so history is honest).
- **One task per commit**: don't bundle. Tasks 1–9 each get exactly one commit (some have a `git add -u` for files touched by `make format`, but it's still one commit).
- **USER env**: every nix command in this plan needs `USER=$(whoami)` or `--impure` (or both). The Makefile already wraps this for `make test`; direct `nix build` calls do not.
- **Worktree**: this work runs in `.worktrees/00041-refactor-improve-structure`. Stay there — don't accidentally edit the main worktree.
- **If a step fails**: STOP and report the failure. Don't paper over. The audit confirmed every assumption in this plan, but real edits surface surprises (e.g., a make target's recipe was different than expected).
