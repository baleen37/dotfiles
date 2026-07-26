# wt 워크트리 재설계 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Zsh의 `gw` 워크트리 래퍼를 `wt`로 교체하고, fzf 피커와 `prune` 서브커맨드를 추가하며, Claude Code의 `WorktreeCreate` 훅 스크립트를 저장소로 편입해 셸과 훅의 경로 규칙을 일치시킨다.

**Architecture:** `users/shared/programs/zsh/wt.nix`는 순수 문자열(셸 코드)을 반환하는 Nix 표현식이다. `default.nix`가 이를 `${import ./wt.nix}`로 zsh `initContent`에 삽입한다. 테스트는 이 문자열을 `import`해 `lib.hasInfix`로 특정 구현이 존재하는지 검사한다 — Nix 평가 시점에 셸을 실행할 수 없기 때문에 채택된 기존 방식이다. Claude Code 훅은 bash로 실행되어 zsh 함수를 호출할 수 없으므로, 경로 규칙만 동일하게 맞추고 그 일치를 테스트로 고정한다.

**Tech Stack:** Nix (flakes, flake-parts), Home Manager, Zsh, fzf, Bash, jq

## Global Constraints

- 워크트리 경로 규칙: `<repo_root>/.worktrees/<YYMMDD>-<sanitized-branch>` — `sanitized`는 `/`를 `-`로 치환한 것, `YYMMDD`는 `date +%y%m%d`
- `repo_root`는 항상 `git worktree list | head -1 | awk '{print $1}'` — 워크트리 안에서 실행해도 메인 루트를 가리켜야 하며, 중첩 워크트리를 만들면 안 된다
- 베이스 브랜치는 `main`, 없으면 `master`
- `wt.nix`는 순수 문자열을 반환한다. `{ pkgs, ... }:` 같은 인자를 받지 않는다
- Nix 문자열 안에서 셸의 `${...}`는 `''${...}`로 이스케이프한다
- `gw`는 흔적 없이 제거한다 — alias, deprecation 경고를 남기지 않는다
- `nix store gc`는 항상 분리된 백그라운드 서브셸로 실행한다: `(nix store gc >/dev/null 2>&1 &)`
- `nix-collect-garbage -d`는 절대 쓰지 않는다 (시스템 세대를 지워 롤백을 깨뜨린다)
- 테스트 파일은 `tests/unit/*-test.nix`로 자동 발견되며, 체크 이름은 `unit-<파일명에서 -test 제외>`가 된다
- **함수 정의 순서가 중요하다.** zsh에서 `local _helper() { ... }`는 그 줄이 _실행될 때_ 정의된다. `case` 블록 안에서 호출하는 헬퍼는 반드시 `case`보다 **위**에 정의해야 한다. 아래에 두면 `command not found`로 죽는다. (기존 `gw`의 `ls`/`rm`이 헬퍼를 안 써서 드러나지 않았던 제약이다.)
- 모든 커밋 전 `make format` 통과 필요 (pre-commit 훅이 `nixfmt-rfc-style`을 강제)
- 빌드 명령에는 `--impure`가 필요하다 (`USER` 환경변수 의존)

---

### Task 1: gw → wt 리네임

기능 변경 없이 이름만 바꾼다. 이 태스크가 끝나면 `wt`가 기존 `gw`와 동일하게 동작해야 한다.

**Files:**

- Rename: `users/shared/programs/zsh/gw.nix` → `users/shared/programs/zsh/wt.nix`
- Modify: `users/shared/programs/zsh/default.nix:13` (주석), `:186-188` (섹션 주석 + import)
- Modify: `CLAUDE.md:369`
- Rename: `tests/unit/gw-subcommands-test.nix` → `tests/unit/wt-subcommands-test.nix`
- Rename: `tests/unit/gw-numbering-test.nix` → `tests/unit/wt-numbering-test.nix`
- Rename: `tests/unit/gw-sanitization-test.nix` → `tests/unit/wt-sanitization-test.nix`
- Rename: `tests/unit/gw-existing-worktree-test.nix` → `tests/unit/wt-existing-worktree-test.nix`
- Rename: `tests/unit/gw-random-collision-test.nix` → `tests/unit/wt-random-collision-test.nix`

**Interfaces:**

- Consumes: 없음 (첫 태스크)
- Produces: `users/shared/programs/zsh/wt.nix` — 인자 없이 `import`하면 셸 코드 문자열을 반환. 함수명 `wt`. 내부 헬퍼 `_random_branch_name`, `_msg`, `_error`, `_sanitize_branch`, `_find_base_branch`, `_check_worktree_exists`, `_create_worktree`, `_handle_existing_worktree`, `_handle_ref_conflict`.

- [ ] **Step 1: 파일 리네임 (git mv)**

```bash
git mv users/shared/programs/zsh/gw.nix users/shared/programs/zsh/wt.nix
git mv tests/unit/gw-subcommands-test.nix tests/unit/wt-subcommands-test.nix
git mv tests/unit/gw-numbering-test.nix tests/unit/wt-numbering-test.nix
git mv tests/unit/gw-sanitization-test.nix tests/unit/wt-sanitization-test.nix
git mv tests/unit/gw-existing-worktree-test.nix tests/unit/wt-existing-worktree-test.nix
git mv tests/unit/gw-random-collision-test.nix tests/unit/wt-random-collision-test.nix
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

Run: `nix build '.#checks.aarch64-darwin.unit-wt-subcommands' --impure --no-link 2>&1 | tail -20`

Expected: FAIL — 테스트 파일이 `../../users/shared/programs/zsh/gw.nix`를 import하는데 그 파일이 사라졌으므로 경로 오류.

- [ ] **Step 3: 테스트 파일 5개의 내부 참조 갱신**

각 파일에서 다음을 치환한다.

- `import ../../users/shared/programs/zsh/gw.nix` → `import ../../users/shared/programs/zsh/wt.nix`
- 변수명 `gwScript` → `wtScript` (사용처 전부)
- `helpers.testSuite "gw-..."` → `"wt-..."`
- assert 이름의 `gw-` 프리픽스 → `wt-`
- 메시지 문자열의 `gw ` → `wt ` (예: `"gw should handle an ls subcommand"` → `"wt should handle an ls subcommand"`)
- 파일 첫 줄 주석의 경로와 설명

`wt-sanitization-test.nix`에는 `lib.hasInfix ''grep -E "^$branch/"''` 같은 검사가 있는데, 이는 `wt.nix` 내부 코드를 검사하는 문자열이므로 **바꾸지 않는다**. 셸 코드 자체를 가리키는 리터럴과 테스트 메타데이터를 구분할 것.

예시 — `wt-existing-worktree-test.nix`의 최종 형태:

```nix
# tests/unit/wt-existing-worktree-test.nix
# Verify wt handles the "branch already used by another worktree" case by
# parsing the existing path out of git's error message and cd-ing there.
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
  value = helpers.testSuite "wt-existing-worktree" [
    (helpers.assertTest "wt-defines-existing-worktree-handler"
      (lib.hasInfix "_handle_existing_worktree" wtScript)
      "wt should define _handle_existing_worktree helper"
    )

    (helpers.assertTest "wt-parses-existing-worktree-path"
      (lib.hasInfix "already used by worktree at" wtScript)
      "wt should parse 'already used by worktree at <path>' from git error output"
    )

    (helpers.assertTest "wt-warns-on-existing-worktree"
      (lib.hasInfix "is already checked out at" wtScript)
      "wt should print a warning when the branch is already checked out elsewhere"
    )

    (helpers.assertTest "wt-cds-into-existing-worktree"
      (lib.hasInfix ''cd "$existing_worktree"'' wtScript)
      "wt should cd into the existing worktree instead of failing"
    )
  ];
}
```

- [ ] **Step 4: `wt.nix` 내부의 gw 참조 갱신**

`users/shared/programs/zsh/wt.nix`에서:

- 파일 상단 주석의 `gw function`, `Usage: gw ...` → `wt`
- 함수 선언 `gw() {` → `wt() {`
- 함수 안 주석의 `Usage: gw [branch-name]` 등 → `wt`
- `-h | --help` 분기의 `echo "Usage: gw ..."` 3줄 → `wt`
- `case` 위 주석 `... cannot be used as branch names via gw.` → `via wt.`
- `_sanitize_branch` 주석의 `so gw works` → `so wt works`

`_sanitize_branch`가 `git worktree list | head -1`로 메인 루트를 잡는 로직은 그대로 둔다.

- [ ] **Step 5: `default.nix` 배선 갱신**

`users/shared/programs/zsh/default.nix` 13행:

```nix
#       - wt: Git worktree creation/switch
```

188행 부근:

```nix
        # =============================================================================
        # Section: Git worktree wrapper
        # =============================================================================
        ${import ./wt.nix}
```

- [ ] **Step 6: `CLAUDE.md` 갱신**

369행을 바꾼다:

```markdown
- `wt`: Git worktree management (fzf picker, create, list, prune)
```

- [ ] **Step 7: gw 잔여 참조 없는지 확인**

Run: `grep -rn '\bgw\b' --include='*.nix' --include='*.md' . | grep -v '\.worktrees/' | grep -v 'docs/superpowers'`

Expected: 출력 없음. (`docs/superpowers/`의 스펙·계획 문서는 히스토리 기록이므로 제외한다.)

- [ ] **Step 8: 포맷 및 전체 테스트**

```bash
make format
nix flake check --impure 2>&1 | tail -30
```

Expected: PASS. 체크 이름이 `unit-wt-*` 5개로 나타나야 한다.

- [ ] **Step 9: 커밋**

```bash
git add -A
git commit -m "refactor(zsh): rename gw worktree wrapper to wt

gw collides with the Gradle wrapper mnemonic. wt has no conflict on
macOS/Linux; the only known clash is Windows Terminal's wt.exe, which
does not apply to this macOS/NixOS-only configuration.

Pure rename, no behavior change."
```

---

### Task 2: `wt prune` 서브커맨드

정리 경로를 만든다. 현재 `.worktrees/`에 70개 2.0G가 쌓였고 그중 20개는 머지+클린 상태다.

**Files:**

- Modify: `users/shared/programs/zsh/wt.nix`
- Create: `tests/unit/wt-prune-test.nix`

**Interfaces:**

- Consumes: Task 1의 `wt.nix` (함수 `wt`, 헬퍼 `_msg`/`_error`/`_find_base_branch`)
- Produces: `wt.nix` 안에 셸 헬퍼 `_classify_worktree <path>` — `safe`/`stale`/`keep` 중 하나를 stdout에 출력. `prune` case 분기.

- [ ] **Step 1: 실패하는 테스트 작성**

`tests/unit/wt-prune-test.nix`:

```nix
# tests/unit/wt-prune-test.nix
# Verify wt prune classifies worktrees three ways, defaults to dry-run, and
# runs a single background nix store gc after all removals.
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
  value = helpers.testSuite "wt-prune" [
    (helpers.assertTest "wt-prune-subcommand" (lib.hasInfix "prune)" wtScript)
      "wt should handle a prune subcommand"
    )

    (helpers.assertTest "wt-prune-defines-classifier"
      (lib.hasInfix "_classify_worktree" wtScript)
      "wt prune should classify worktrees via a _classify_worktree helper"
    )

    (helpers.assertTest "wt-prune-three-classes" (
      lib.hasInfix "safe" wtScript && lib.hasInfix "stale" wtScript && lib.hasInfix "keep" wtScript
    ) "wt prune should use three classes: safe, stale, keep")

    (helpers.assertTest "wt-prune-detects-merged"
      (lib.hasInfix "branch --merged" wtScript)
      "wt prune should detect merged branches via git branch --merged"
    )

    (helpers.assertTest "wt-prune-detects-dirty"
      (lib.hasInfix "status --porcelain" wtScript)
      "wt prune should detect uncommitted changes via git status --porcelain"
    )

    (helpers.assertTest "wt-prune-dry-run-by-default"
      (lib.hasInfix "--yes" wtScript)
      "wt prune should require --yes to actually delete; dry-run otherwise"
    )

    (helpers.assertTest "wt-prune-stale-flag"
      (lib.hasInfix "--stale" wtScript)
      "wt prune should accept --stale to include old unmerged worktrees"
    )

    (helpers.assertTest "wt-prune-skips-main-worktree"
      (lib.hasInfix "_main_root" wtScript)
      "wt prune should resolve the main worktree root so it can exclude it"
    )
  ];
}
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

Run: `nix build '.#checks.aarch64-darwin.unit-wt-prune' --impure --no-link 2>&1 | tail -20`

Expected: FAIL — `_classify_worktree`, `prune)`, `--yes` 등이 아직 없다.

- [ ] **Step 3: `_classify_worktree` 헬퍼 구현**

`wt.nix`의 `case "$1" in` 블록 **앞**, `_random_branch_name` 정의 다음에 넣는다. 서브커맨드 분기보다 먼저 정의되어야 `prune` case에서 쓸 수 있다.

```bash
    # Helper: Classify a worktree for pruning.
    # Echoes one of: safe | stale | keep
    #   safe  - merged into the base branch and has no uncommitted changes
    #   stale - unmerged, clean, and untouched for 30+ days
    #   keep  - has uncommitted changes, or is where we are standing right now
    local _classify_worktree() {
      local wt_path="$1"
      local base="$2"
      local main_root="$3"

      # Never touch the main worktree or the one we are standing in.
      local here=$(pwd -P)
      local target=$(cd "$wt_path" 2>/dev/null && pwd -P)
      if [[ -z "$target" || "$target" == "$main_root" || "$target" == "$here" ]]; then
        echo "keep"
        return 0
      fi

      # Uncommitted work always wins.
      if [[ -n $(git -C "$wt_path" status --porcelain 2>/dev/null) ]]; then
        echo "keep"
        return 0
      fi

      local branch=$(git -C "$wt_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
      if [[ -z "$branch" || "$branch" == "HEAD" ]]; then
        echo "keep"
        return 0
      fi

      # Merged into base => safe to drop.
      if [[ -n $(git -C "$main_root" branch --merged "$base" --list "$branch" 2>/dev/null) ]]; then
        echo "safe"
        return 0
      fi

      # Unmerged but untouched for 30+ days => stale.
      if [[ -z $(find "$wt_path" -maxdepth 0 -mtime -30 2>/dev/null) ]]; then
        echo "stale"
        return 0
      fi

      echo "keep"
    }
```

- [ ] **Step 4: `prune` case 분기 구현**

`case "$1" in`의 `rm)` 분기 **뒤**, `esac` 앞에 추가한다.

```bash
      prune)
        shift
        local include_stale=0 confirmed=0 arg
        for arg in "$@"; do
          case "$arg" in
            --stale) include_stale=1 ;;
            --yes | -y) confirmed=1 ;;
            *)
              echo "Unknown option: $arg" >&2
              echo "Usage: wt prune [--stale] [--yes]" >&2
              return 1
              ;;
          esac
        done

        local _main_root=$(git worktree list 2>/dev/null | head -1 | awk '{print $1}')
        if [[ -z "$_main_root" ]]; then
          echo "Not a git repository" >&2
          return 1
        fi

        local _base
        if git -C "$_main_root" rev-parse --verify main >/dev/null 2>&1; then
          _base="main"
        elif git -C "$_main_root" rev-parse --verify master >/dev/null 2>&1; then
          _base="master"
        else
          echo "No main or master branch found" >&2
          return 1
        fi

        # Collect targets. git worktree list's first line is the main worktree.
        local _wt _class
        local -a _safe _stale
        while IFS= read -r _wt; do
          [[ -n "$_wt" ]] || continue
          _class=$(_classify_worktree "$_wt" "$_base" "$_main_root")
          case "$_class" in
            safe) _safe+=("$_wt") ;;
            stale) _stale+=("$_wt") ;;
          esac
        done < <(git worktree list | tail -n +2 | awk '{print $1}')

        local -a _targets
        _targets=("''${_safe[@]}")
        if [[ $include_stale -eq 1 ]]; then
          _targets+=("''${_stale[@]}")
        fi

        if [[ ''${#_targets[@]} -eq 0 ]]; then
          echo "Nothing to prune."
          [[ ''${#_stale[@]} -gt 0 ]] &&
            echo "(''${#_stale[@]} stale worktree(s) available with --stale)"
          return 0
        fi

        echo "merged + clean (safe):    ''${#_safe[@]}"
        echo "old + unmerged (stale):   ''${#_stale[@]}$([[ $include_stale -eq 1 ]] && echo " (included)")"
        echo ""
        printf '%s\n' "''${_targets[@]}"
        echo ""

        if [[ $confirmed -ne 1 ]]; then
          echo "Dry run. Re-run with --yes to remove ''${#_targets[@]} worktree(s)."
          return 0
        fi

        local _failed=0
        for _wt in "''${_targets[@]}"; do
          if git worktree remove "$_wt"; then
            echo "removed: $_wt"
          else
            echo "failed:  $_wt" >&2
            _failed=1
          fi
        done

        # One GC for the whole batch, not one per removal.
        (nix store gc >/dev/null 2>&1 &)
        echo "nix store gc running in background." >&2
        return $_failed
        ;;
```

- [ ] **Step 5: 도움말과 예약어 주석 갱신**

`-h | --help` 분기에 한 줄 추가한다:

```bash
        echo "       wt prune [--stale] [--yes]"
        echo "                           Remove merged+clean worktrees (dry-run by default)"
```

`case` 위 주석을 갱신한다:

```bash
    # Subcommands. Note: "ls", "rm", and "prune" are reserved and cannot be
    # used as branch names via wt.
```

- [ ] **Step 6: 테스트 통과 확인**

Run: `nix build '.#checks.aarch64-darwin.unit-wt-prune' --impure --no-link 2>&1 | tail -20`

Expected: PASS

- [ ] **Step 7: 기존 테스트 회귀 없는지 확인**

Run: `make format && nix flake check --impure 2>&1 | tail -30`

Expected: PASS — `unit-wt-*` 6개 전부.

- [ ] **Step 8: 커밋**

```bash
git add -A
git commit -m "feat(zsh): add wt prune to reclaim merged and stale worktrees

git worktree prune reports nothing prunable when the directories still
exist, so 70 worktrees / 2.0G had accumulated with no working cleanup
path. Classifies each worktree as safe (merged + clean), stale (unmerged,
clean, 30+ days), or keep (dirty, or the one you are standing in), and
defaults to a dry run.

Runs a single background nix store gc after the batch rather than one
per removal."
```

---

### Task 3: fzf 피커

인자 없는 `wt`가 피커를 띄우게 한다.

**Files:**

- Modify: `users/shared/programs/zsh/wt.nix`
- Create: `tests/unit/wt-picker-test.nix`

**Interfaces:**

- Consumes: Task 1의 `wt.nix`, Task 2의 `prune` 분기
- Produces: `wt.nix` 안에 셸 헬퍼 `_pick_worktree` — fzf로 선택된 워크트리 절대경로를 stdout에 출력하고, 취소 시 빈 문자열. 인자 없는 `wt` 호출이 이를 사용.

- [ ] **Step 1: 실패하는 테스트 작성**

`tests/unit/wt-picker-test.nix`:

```nix
# tests/unit/wt-picker-test.nix
# Verify bare `wt` opens an fzf picker over the current repo's worktrees
# instead of creating one, and that `wt new` still creates a random one.
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
  value = helpers.testSuite "wt-picker" [
    (helpers.assertTest "wt-defines-picker" (lib.hasInfix "_pick_worktree" wtScript)
      "wt should define a _pick_worktree helper"
    )

    (helpers.assertTest "wt-picker-uses-fzf" (lib.hasInfix "fzf" wtScript)
      "wt picker should use fzf"
    )

    (helpers.assertTest "wt-picker-lists-repo-worktrees"
      (lib.hasInfix "git worktree list" wtScript)
      "wt picker should enumerate the current repo's worktrees"
    )

    (helpers.assertTest "wt-picker-has-preview" (lib.hasInfix "--preview" wtScript)
      "wt picker should show a preview of each worktree"
    )

    (helpers.assertTest "wt-new-subcommand" (lib.hasInfix "new)" wtScript)
      "wt new should create a randomly named worktree"
    )

    (helpers.assertTest "wt-bare-does-not-create" (
      lib.hasInfix ''if [[ $# -eq 0 ]]'' wtScript
    ) "bare wt should branch on zero arguments to reach the picker")
  ];
}
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

Run: `nix build '.#checks.aarch64-darwin.unit-wt-picker' --impure --no-link 2>&1 | tail -20`

Expected: FAIL — `_pick_worktree`, `new)`, `--preview`가 없다.

- [ ] **Step 3: `_pick_worktree` 헬퍼 구현**

`_classify_worktree` 정의 다음에 추가한다.

```bash
    # Helper: fzf picker over this repo's worktrees.
    # Echoes the chosen absolute path, or nothing if cancelled.
    #
    # Scoped to the current repo rather than the machine-wide `wt ls`, which
    # indexes nix-direnv gc-roots and therefore only sees worktrees that have
    # been entered via direnv at least once.
    local _pick_worktree() {
      local line
      line=$(git worktree list |
        awk '{path=$1; branch=$3; gsub(/[][]/, "", branch); printf "%-40s %s\n", branch, path}' |
        fzf --no-multi \
          --prompt='worktree> ' \
          --preview='git -C {2} log --oneline -5 2>/dev/null; echo; git -C {2} status -s 2>/dev/null' \
          --preview-window='right:50%:wrap') || return 0
      [[ -n "$line" ]] && echo "''${line##* }"
    }
```

`--no-multi`는 단일 선택을 강제한다. `{2}`는 fzf가 공백으로 나눈 두 번째 필드(경로)를 가리킨다. fzf가 취소되면 비영(非零)으로 종료하므로 `|| return 0`으로 조용히 빠져나온다.

- [ ] **Step 4: 인자 없는 호출을 피커로 연결**

현재 `wt.nix`에는 인자 없을 때 랜덤 이름을 만드는 블록이 있다:

```bash
    local branch_name="$1"

    if [[ $# -eq 0 ]]; then
      local _attempt
      for _attempt in 1 2 3 4 5; do
        branch_name=$(_random_branch_name)
        git rev-parse --verify "$branch_name" >/dev/null 2>&1 || break
      done
    fi
```

이 앞에, `esac` 바로 다음 위치에 피커 분기를 넣는다:

```bash
    # Bare `wt` opens the picker. Creating now lives behind `wt new` or an
    # explicit name, since with dozens of worktrees around, finding one is the
    # more common need.
    if [[ $# -eq 0 ]]; then
      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Not a git repository" >&2
        return 1
      fi
      local _picked=$(_pick_worktree)
      [[ -n "$_picked" ]] && cd "$_picked"
      return 0
    fi
```

그리고 위의 랜덤 생성 블록의 조건을 `$# -eq 0`에서 플래그 검사로 바꾼다. 인자 없는 경우는 이제 위 피커 분기가 먼저 잡아가므로 여기 도달하지 않는다.

```bash
    local branch_name="$1"

    # Set by the `new` subcommand below.
    if [[ $_wt_random -eq 1 ]]; then
      local _attempt
      for _attempt in 1 2 3 4 5; do
        branch_name=$(_random_branch_name)
        git rev-parse --verify "$branch_name" >/dev/null 2>&1 || break
      done
    fi
```

- [ ] **Step 5: `new` 서브커맨드 추가**

플래그를 함수 진입부, `_random_branch_name` 정의 **앞**에 선언한다:

```bash
    local _wt_random=0
```

그리고 `case` 블록에 `prune)` 뒤로 분기를 추가한다:

```bash
      new)
        _wt_random=1
        ;;
```

`return`하지 않고 빠져나와 아래 생성 경로로 흘러가게 한다. `branch_name="$1"`이 `new`로 채워지지만 `_wt_random=1`이라 곧바로 랜덤 이름으로 덮어써진다.

재귀 호출(`wt --random`) 대신 플래그를 쓰는 이유는, `case`에 `*)` 폴스루가 없어 `--random` 같은 내부 표식이 사용자가 직접 입력해도 브랜치 이름으로 통과해버리기 때문이다.

- [ ] **Step 6: 도움말 갱신**

`-h | --help` 분기 전체를 다음으로 교체한다:

```bash
        echo "Usage: wt                  Pick a worktree with fzf and cd into it"
        echo "       wt <branch-name>    Create worktree and cd into it"
        echo "       wt new              Create a randomly named worktree"
        echo "       wt ls               List worktrees left on this machine (all repos)"
        echo "       wt rm <path> [...]  Remove worktree, then run nix store gc in background"
        echo "       wt prune [--stale] [--yes]"
        echo "                           Remove merged+clean worktrees (dry-run by default)"
        return 0
```

- [ ] **Step 7: 예약어 주석 갱신**

```bash
    # Subcommands. Note: "ls", "rm", "new", and "prune" are reserved and
    # cannot be used as branch names via wt.
```

- [ ] **Step 8: 테스트 통과 확인**

Run: `nix build '.#checks.aarch64-darwin.unit-wt-picker' --impure --no-link 2>&1 | tail -20`

Expected: PASS

- [ ] **Step 9: 전체 테스트**

Run: `make format && nix flake check --impure 2>&1 | tail -30`

Expected: PASS — `unit-wt-*` 7개.

- [ ] **Step 10: 커밋**

```bash
git add -A
git commit -m "feat(zsh): make bare wt an fzf worktree picker

With dozens of worktrees around, finding one is more common than making
one, so bare wt now picks and cds. Random-name creation moves to wt new.

Scoped to the current repo rather than the machine-wide wt ls, which only
sees worktrees that have been entered via direnv at least once."
```

---

### Task 4: Claude Code 훅 스크립트 편입

`settings.json`이 참조하는 `~/.claude/setup-worktree.sh`가 저장소에 없어 새 머신에서 훅이 깨진다. 게다가 현재 머신의 사본은 구식 `00000-` 규칙을 쓴다.

**Files:**

- Create: `users/shared/programs/.config/claude/setup-worktree.sh`
- Modify: `users/shared/programs/claude-code.nix:27`
- Create: `tests/unit/wt-hook-consistency-test.nix`

**Interfaces:**

- Consumes: Task 1의 `wt.nix` (경로 규칙의 기준)
- Produces: `users/shared/programs/.config/claude/setup-worktree.sh` — stdin으로 `{name, cwd}` JSON을 받아 워크트리를 만들고 경로를 stdout에 출력하는 bash 스크립트.

- [ ] **Step 1: 실패하는 테스트 작성**

`tests/unit/wt-hook-consistency-test.nix`:

```nix
# tests/unit/wt-hook-consistency-test.nix
# The Claude Code WorktreeCreate hook runs under bash and cannot call the zsh
# `wt` function, so the path rule is necessarily written twice. Pin both copies
# to the same rule here — they drifted apart once already (the hook was still
# on the old 00000- numbering after wt moved to YYMMDD-).
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
  hookScript = builtins.readFile ../../users/shared/programs/.config/claude/setup-worktree.sh;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "wt-hook-consistency" [
    (helpers.assertTest "hook-uses-worktrees-dir" (lib.hasInfix ".worktrees" hookScript)
      "hook should place worktrees under .worktrees/"
    )

    (helpers.assertTest "hook-uses-date-prefix" (lib.hasInfix "date +%y%m%d" hookScript)
      "hook should use the same YYMMDD prefix as wt"
    )

    (helpers.assertTest "wt-uses-date-prefix" (lib.hasInfix "date +%y%m%d" wtScript)
      "wt should use a YYMMDD prefix (the rule the hook mirrors)"
    )

    (helpers.assertTest "hook-drops-numeric-prefix" (
      !(lib.hasInfix "%05d" hookScript)
    ) "hook should not use the old zero-padded numeric prefix")

    (helpers.assertTest "hook-resolves-main-root"
      (lib.hasInfix "worktree list" hookScript)
      "hook should resolve the main worktree root so it never nests worktrees"
    )

    (helpers.assertTest "hook-has-shebang" (lib.hasPrefix "#!" hookScript)
      "hook script should have a shebang"
    )
  ];
}
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

Run: `nix build '.#checks.aarch64-darwin.unit-wt-hook-consistency' --impure --no-link 2>&1 | tail -20`

Expected: FAIL — `setup-worktree.sh`가 없어 `builtins.readFile`이 실패한다.

- [ ] **Step 3: 훅 스크립트 작성**

`users/shared/programs/.config/claude/setup-worktree.sh`:

```bash
#!/usr/bin/env bash
# WorktreeCreate hook: create the worktree where wt() would put it.
#
# Mirrors the path rule in users/shared/programs/zsh/wt.nix:
#   <repo_root>/.worktrees/<YYMMDD>-<branch with / replaced by ->
# The hook runs under bash and cannot call the zsh wt function, so the rule
# lives in two places; tests/unit/wt-hook-consistency-test.nix pins them
# together.
#
# Input:  JSON on stdin, { "name": "...", "cwd": "..." }
# Output: the worktree path on stdout

set -euo pipefail

INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name')
CWD=$(echo "$INPUT" | jq -r '.cwd')

# Resolve the main worktree root, so running from inside a worktree does not
# nest a new one underneath it.
REPO_ROOT=$(git -C "$CWD" worktree list | head -1 | awk '{print $1}')

DATE_PREFIX=$(date +%y%m%d)
DIR="$REPO_ROOT/.worktrees/${DATE_PREFIX}-${NAME//\//-}"

mkdir -p "$REPO_ROOT/.worktrees"

if git -C "$CWD" rev-parse --verify main >/dev/null 2>&1; then
  BASE="main"
elif git -C "$CWD" rev-parse --verify master >/dev/null 2>&1; then
  BASE="master"
else
  echo "No main or master branch found" >&2
  exit 1
fi

git -C "$CWD" worktree add -b "$NAME" "$DIR" "$BASE" >&2

echo "$DIR"
```

실행 권한을 준다 (pre-commit의 shebang 훅이 요구한다):

```bash
chmod +x users/shared/programs/.config/claude/setup-worktree.sh
```

- [ ] **Step 4: `claude-code.nix` 배포 목록에 추가**

27행의 루프에 파일을 넣고, `statusline.sh`처럼 실행 권한을 준다.

```nix
      for f in CLAUDE.md local.md settings.json statusline.sh setup-worktree.sh; do
```

그리고 `chmod +x` 줄 옆에 추가한다:

```nix
      run chmod +x ~/.claude/statusline.sh
      run chmod +x ~/.claude/setup-worktree.sh
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `nix build '.#checks.aarch64-darwin.unit-wt-hook-consistency' --impure --no-link 2>&1 | tail -20`

Expected: PASS

- [ ] **Step 6: 셸 린터 통과 확인**

Run: `pre-commit run shellcheck --files users/shared/programs/.config/claude/setup-worktree.sh`

Expected: PASS. 실패하면 shellcheck 지적사항을 고친다 — `SC2086`(따옴표 누락)이 가장 흔하다.

- [ ] **Step 7: 전체 테스트**

Run: `make format && nix flake check --impure 2>&1 | tail -30`

Expected: PASS — `unit-wt-*` 8개.

- [ ] **Step 8: 커밋**

```bash
git add -A
git commit -m "fix(claude-code): ship the WorktreeCreate hook script

settings.json referenced ~/.claude/setup-worktree.sh but the repo never
provided it, so the hook broke on any fresh machine. The copy on this
machine had also drifted to the old 00000- numbering while wt moved to
YYMMDD-.

Brings the script into the repo on wt's path rule and pins the two
copies together with a test."
```

---

### Task 5: 적용 및 실전 정리

빌드가 아니라 실제 동작을 확인하고, 새 `prune`으로 2.0G를 회수한다.

**Files:** 없음 (검증 및 실행)

**Interfaces:**

- Consumes: Task 1-4 전부

- [ ] **Step 1: 설정 적용**

```bash
make switch
```

Expected: 성공. 실패하면 출력의 Nix 오류를 읽고 해당 태스크로 돌아간다.

- [ ] **Step 2: 새 셸에서 명령 표면 확인**

```bash
exec zsh -l
wt -h
```

Expected: 6줄 도움말이 출력되고 `wt`, `wt new`, `wt ls`, `wt rm`, `wt prune`이 보인다. `gw` 명령은 `command not found`여야 한다.

Run: `type gw 2>&1`
Expected: `gw not found`

- [ ] **Step 3: 피커 동작 확인**

```bash
wt
```

Expected: fzf가 열리고 브랜치명과 경로가 보이며, 프리뷰에 커밋 로그가 뜬다. 하나 선택하면 그 디렉터리로 이동한다. ESC로 나가면 현재 위치 그대로.

- [ ] **Step 4: prune dry-run 확인 (메인 워크트리에서)**

```bash
cd /Users/jito.hello/dotfiles
wt prune
```

Expected: `merged + clean (safe): 20` 근처의 수치와 대상 목록이 출력되고, 마지막 줄이 `Dry run. Re-run with --yes to remove N worktree(s).`. **이 시점에 아무것도 지워지지 않아야 한다.**

Run: `git worktree list | wc -l`
Expected: 여전히 70

- [ ] **Step 5: 목록 육안 검토**

출력된 경로 중 지워지면 안 되는 것이 있는지 확인한다. 특히 현재 작업 중인 `260727-feat-gw-to-wt`가 목록에 **없어야** 한다 (아직 미머지이므로 stale도 아니고, `--stale` 없이는 대상이 아니다).

- [ ] **Step 6: 실제 정리**

```bash
wt prune --yes
```

Expected: `removed: ...`가 대상 수만큼 출력되고, 마지막에 `nix store gc running in background.`

Run: `git worktree list | wc -l`
Expected: 70에서 대상 수만큼 감소.

- [ ] **Step 7: stale 검토**

```bash
wt prune --stale
```

Expected: 30일 이상 미머지 워크트리 목록. 이 목록은 **작업이 유실될 수 있으므로** 실행 전 사용자에게 보여주고 확인을 받는다. 자동으로 `--yes`를 붙이지 말 것.

- [ ] **Step 8: 훅 갱신 및 확인**

기존 활성화 스크립트는 파일이 있으면 덮어쓰지 않으므로 수동 삭제가 필요하다.

```bash
rm ~/.claude/setup-worktree.sh
make switch
grep -c "date +%y%m%d" ~/.claude/setup-worktree.sh
```

Expected: `1` — 새 스크립트가 배포됐다.

- [ ] **Step 9: 디스크 회수 확인**

```bash
du -sh /Users/jito.hello/dotfiles/.worktrees
```

Expected: 2.0G보다 유의미하게 작다.

- [ ] **Step 10: 결과 보고**

사용자에게 보고한다: 회수한 워크트리 수, 회수 전후 용량, `--stale`로 남은 후보 수, 훅 갱신 여부.

---

## 검증 요약

| 단계        | 명령                                                                                                 | 기대                 |
| ----------- | ---------------------------------------------------------------------------------------------------- | -------------------- |
| 포맷        | `make format`                                                                                        | 통과                 |
| 전체 테스트 | `nix flake check --impure`                                                                           | `unit-wt-*` 8개 통과 |
| 잔여 gw     | `grep -rn '\bgw\b' --include='*.nix' --include='*.md' . \| grep -v '\.worktrees/\|docs/superpowers'` | 출력 없음            |
| 적용        | `make switch`                                                                                        | 성공                 |
| 동작        | `wt -h`, `wt`, `wt prune`                                                                            | 스펙대로             |
