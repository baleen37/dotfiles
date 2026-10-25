#!/usr/bin/env bash
# WorktreeRemove hook: remove a worktree that setup-worktree.sh created.
#
# With a WorktreeRemove hook configured, Claude Code does not fall back to git
# and never deletes the branch, so both happen here. Removal stays
# conservative:
#   - only a linked git worktree is removed, never a main checkout or a plain
#     directory;
#   - `git worktree remove` without --force, so a worktree with modified or
#     untracked (non-ignored) files is kept and the hook exits non-zero;
#   - the branch is deleted only when merging it into main/master would add
#     nothing (worktrunk's "merge adds nothing" rule), which also catches
#     squash merges; any other branch is kept.
#
# Input: JSON on stdin, { "worktree_path": "..." }

set -euo pipefail

INPUT=$(cat)
DIR=$(echo "$INPUT" | jq -r '.worktree_path')

if [[ -z $DIR || $DIR == "null" ]]; then
  echo "remove-worktree: missing .worktree_path in hook input" >&2
  exit 1
fi

# Already gone: nothing to do, and Claude Code counts it as removed.
[[ -e $DIR ]] || exit 0

GIT_DIR=$(git -C "$DIR" rev-parse --absolute-git-dir 2> /dev/null) || {
  echo "remove-worktree: $DIR is not a git worktree; leaving it in place" >&2
  exit 1
}
COMMON_DIR=$(cd "$DIR" && cd "$(git rev-parse --git-common-dir)" && pwd -P)
if [[ $GIT_DIR == "$COMMON_DIR" ]]; then
  echo "remove-worktree: $DIR is a main checkout, not a linked worktree" >&2
  exit 1
fi

BRANCH=$(git -C "$DIR" branch --show-current)

git --git-dir="$COMMON_DIR" worktree remove "$DIR" >&2

[[ -n $BRANCH ]] || exit 0

if git --git-dir="$COMMON_DIR" rev-parse --verify -q refs/heads/main > /dev/null; then
  BASE=main
elif git --git-dir="$COMMON_DIR" rev-parse --verify -q refs/heads/master > /dev/null; then
  BASE=master
else
  echo "remove-worktree: no main or master branch; kept branch $BRANCH" >&2
  exit 0
fi

# A conflicting merge exits non-zero and leaves MERGED empty, so the branch stays.
MERGED=$(git --git-dir="$COMMON_DIR" merge-tree --write-tree "$BASE" "$BRANCH" 2> /dev/null || true)
if [[ $MERGED == "$(git --git-dir="$COMMON_DIR" rev-parse "$BASE^{tree}")" ]]; then
  git --git-dir="$COMMON_DIR" branch -D "$BRANCH" >&2
else
  echo "remove-worktree: kept branch $BRANCH; it has changes not in $BASE" >&2
fi
