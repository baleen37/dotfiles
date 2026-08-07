# wt 기준 브랜치 최신화 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 새 브랜치 worktree를 만들기 전에 기준 `main`/`master` worktree를 `origin`과 fast-forward 방식으로 동기화한다.

**Architecture:** `wt.nix`에 기준 브랜치가 체크아웃된 worktree 경로를 `git worktree list --porcelain`에서 찾는 `_find_base_worktree` 헬퍼와 `fetch`/`pull --ff-only`를 수행하는 `_update_base_branch` 헬퍼를 추가한다. 로컬 브랜치가 없는 새 브랜치 생성 경로에서만 최신화 헬퍼를 호출하고, 실패하면 기존 worktree 생성 로직에 진입하지 않는다.

**Tech Stack:** Nix 문자열 기반 Zsh 함수, Git worktree CLI, Nix assertion tests, Nix flake checks.

## Global Constraints

- 기존 worktree 경로, 브랜치 충돌 처리, Herdr 연동, 백그라운드 GC는 변경하지 않는다.
- 강제 reset, stash, merge, rebase는 수행하지 않는다.
- 기준 worktree가 dirty하거나 fetch/pull이 실패하면 새 worktree 생성을 중단한다.
- 이미 존재하는 브랜치로 이동하는 경우 기준 브랜치를 갱신하지 않는다.
- 테스트는 기존 `lib.hasInfix` 기반 unit test 패턴을 따른다.

---

### Task 1: 기준 브랜치 최신화 계약을 회귀 테스트로 고정

**Files:**

- Create: `tests/unit/wt-base-branch-sync-test.nix`
- Read: `users/shared/programs/zsh/wt.nix`

**Interfaces:**

- Consumes: `wt.nix`가 반환하는 Zsh 함수 문자열과 기존 `tests/lib/test-helpers.nix`의 `testSuite`/`assertTest`.
- Produces: `unit-wt-base-branch-sync` flake check가 검증하는 문자열 계약.

- [ ] **Step 1: Write the failing test**

`tests/unit/wt-base-branch-sync-test.nix`에 다음 계약을 검사하는 테스트를 만든다.

```nix
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  wtScript = import ../../users/shared/programs/zsh/wt.nix;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "wt-base-branch-sync" [
    (helpers.assertTest "wt-finds-base-worktree"
      (lib.hasInfix "git worktree list --porcelain" wtScript)
      "wt should find the worktree where the base branch is checked out")

    (helpers.assertTest "wt-defines-base-branch-updater"
      (lib.hasInfix "_update_base_branch" wtScript)
      "wt should define a helper for updating the base branch")

    (helpers.assertTest "wt-fetches-origin-before-creation"
      (lib.hasInfix "git -C \"$base_root\" fetch origin" wtScript)
      "wt should fetch origin before creating a new worktree")

    (helpers.assertTest "wt-pulls-base-fast-forward-only"
      (lib.hasInfix "git -C \"$base_root\" pull --ff-only origin \"$base_branch\"" wtScript)
      "wt should update the base branch with a fast-forward-only pull")

    (helpers.assertTest "wt-rejects-dirty-base-worktree"
      (lib.hasInfix "git -C \"$base_root\" status --porcelain" wtScript)
      "wt should check the base worktree for uncommitted changes")

    (helpers.assertTest "wt-updates-only-new-branches"
      (lib.hasInfix ''if [[ "$branch_existed" -eq 0 ]]'' wtScript)
      "wt should update the base branch only when creating a new branch")

    (helpers.assertTest "wt-stops-when-base-update-fails"
      (lib.hasInfix ''_update_base_branch "$base_branch" || return 1'' wtScript)
      "wt should stop before worktree creation when base update fails")
  ];
}
```

- [ ] **Step 2: Run the focused check and verify it fails**

Run:

```bash
nix build ".#checks.$(nix eval --raw --impure --expr builtins.currentSystem).unit-wt-base-branch-sync" --accept-flake-config --print-build-logs --no-link
```

Expected: FAIL because `_update_base_branch` and its Git commands do not exist in `wt.nix` yet.

### Task 2: Implement base branch synchronization

**Files:**

- Modify: `users/shared/programs/zsh/wt.nix` near `_find_base_branch` and the main creation flow

**Interfaces:**

- Consumes: Existing `_error`, `_msg`, `_find_base_branch`, `branch_existed`, and `_create_worktree` behavior.
- Produces: `_find_base_worktree <base_branch>` returning the matching worktree path, and `_update_base_branch <base_branch>` returning success only after fetch and fast-forward pull succeed.

- [ ] **Step 1: Add the minimal helpers**

Insert after `_find_base_branch`:

```zsh
    # Helper: Find the worktree where the base branch is checked out.
    local _find_base_worktree() {
      local base_branch="$1"
      git worktree list --porcelain |
        awk -v branch="refs/heads/$base_branch" '
          /^worktree / { path = substr($0, 10) }
          /^branch / && $2 == branch { print path; exit }
        '
    }

    # Helper: Update the base branch before creating a new branch.
    local _update_base_branch() {
      local base_branch="$1"
      local base_root=$(_find_base_worktree "$base_branch")

      if [[ -z "$base_root" ]]; then
        _error "Base branch is not checked out: $base_branch"
        return 1
      fi

      if [[ -n $(git -C "$base_root" status --porcelain 2>/dev/null) ]]; then
        _error "Base worktree has uncommitted changes: $base_root"
        return 1
      fi

      _msg "$BLUE" "Updating base branch '$base_branch'..."
      if ! git -C "$base_root" fetch origin; then
        _error "Failed to fetch origin"
        return 1
      fi
      if ! git -C "$base_root" pull --ff-only origin "$base_branch"; then
        _error "Failed to fast-forward '$base_branch'"
        return 1
      fi
    }
```

- [ ] **Step 2: Call the updater only for new branches**

After `_find_base_branch` succeeds and before `_create_worktree` is called, add:

```zsh
    if [[ "$branch_existed" -eq 0 ]]; then
      _update_base_branch "$base_branch" || return 1
    fi
```

Do not move or alter the existing conflict, Herdr, directory, or GC paths.

- [ ] **Step 3: Run the focused check and verify it passes**

Run the focused `unit-wt-base-branch-sync` build again. Expected: PASS with all seven assertions successful.

### Task 3: Verify formatting and full regression coverage

**Files:**

- Inspect: `docs/superpowers/specs/2026-08-07-wt-base-branch-sync-design.md`
- Inspect: `docs/superpowers/plans/2026-08-07-wt-base-branch-sync.md`
- Inspect: `tests/unit/wt-base-branch-sync-test.nix`
- Inspect: `users/shared/programs/zsh/wt.nix`

- [ ] **Step 1: Check the changed files for whitespace errors**

Run:

```bash
git diff --check
```

Expected: no output and exit code 0.

- [ ] **Step 2: Build all unit and integration assertions**

Run:

```bash
make test-build
```

Expected: exit code 0 and the aggregate assertion derivation reports every unit and integration assertion passed.

- [ ] **Step 3: Run the repository's formatting check**

Run:

```bash
nix fmt -- --fail-on-change
```

Expected: exit code 0 with no formatting changes required.

- [ ] **Step 4: Review the final diff against the approved scope**

Run:

```bash
git status --short
git diff --stat
git diff -- users/shared/programs/zsh/wt.nix tests/unit/wt-base-branch-sync-test.nix
```

Expected: only the approved design/plan docs, the new focused test, and the minimal `wt.nix` synchronization change are present. No commit or push is performed unless requested separately.
