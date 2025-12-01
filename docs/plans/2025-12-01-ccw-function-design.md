# ccw (Claude Code Worktree) Function Design

## Overview

Git worktree를 생성하고 해당 디렉토리에서 Claude Code를 즉시 실행하는 편의 함수

## Usage

```bash
ccw <branch-name>
```

## Behavior

### 1. Input Validation
- 브랜치 이름이 제공되지 않으면 사용법 표시 후 종료

### 2. Git Repository Check
- 현재 디렉토리가 git 저장소인지 확인
- 저장소가 아니면 에러 메시지 표시 후 종료

### 3. Path Handling
- Worktree 경로: `.worktree/<branch-name>`
- 브랜치 이름의 슬래시(`/`)를 하이픈(`-`)으로 치환
  - Example: `feature/jito/test` → `.worktree/feature-jito-test`

### 4. Worktree Directory Conflict Check
- `.worktree/<sanitized-branch-name>` 디렉토리가 이미 존재하면 에러 표시 후 종료

### 5. Base Branch Detection
- `main` 브랜치 존재 여부 확인
- 없으면 `master` 브랜치 확인
- 둘 다 없으면 에러 메시지 표시 후 종료

### 6. Worktree Creation
- 브랜치가 이미 존재하는 경우:
  - 해당 브랜치로 worktree 생성
  - `git worktree add "$WORKTREE_DIR" "$branch_name"`
- 브랜치가 없는 경우:
  - Base branch(main/master)에서 새 브랜치 생성 + worktree 생성
  - `git worktree add -b "$branch_name" "$WORKTREE_DIR" "$base_branch"`

### 7. Execution
- Worktree 생성 성공 시:
  - 성공 메시지 표시
  - Worktree 디렉토리로 이동
  - `cc` 별칭 실행 (= `claude --dangerously-skip-permissions`)
- Worktree 생성 실패 시:
  - 에러 메시지 표시 후 종료

## Implementation Details

### Error Messages

| Condition | Message |
|-----------|---------|
| No branch name provided | `Usage: ccw <branch-name>` |
| Not a git repository | `❌ Not a git repository` |
| Worktree already exists | `❌ Worktree already exists: <path>` |
| No main/master branch | `❌ No main or master branch found` |
| Worktree creation failed | `❌ Failed to create worktree` |

### Success Messages

| Event | Message |
|-------|---------|
| Worktree created | `✅ Worktree created: <path>` |

### Dependencies

- Existing `cc` alias: `claude --dangerously-skip-permissions`
- Git worktree support (Git 2.5+)

## User Experience

```bash
# Example 1: Create new branch and worktree
$ ccw feature/new-feature
✅ Worktree created: .worktree/feature-new-feature
# Claude Code starts in .worktree/feature-new-feature/

# Example 2: Use existing branch
$ ccw existing-branch
✅ Worktree created: .worktree/existing-branch
# Claude Code starts in .worktree/existing-branch/

# Example 3: Worktree already exists
$ ccw feature/new-feature
❌ Worktree already exists: .worktree/feature-new-feature

# Example 4: No argument provided
$ ccw
Usage: ccw <branch-name>
```

## Post-Execution State

- User remains in worktree directory after Claude Code exits
- Worktree cleanup options:
  - `git worktree remove .worktree/<branch-name>`
  - `rm -rf .worktree/<branch-name> && git worktree prune`

## Recommendations

1. Add `.worktree/` to `.gitignore`
2. Consider companion cleanup command for removing worktrees
3. Consider `git worktree list` integration for discovering existing worktrees

## Implementation Location

`users/shared/zsh.nix` - Add as shell function in `initContent` section
