#!/usr/bin/env bash
# WorktreeCreate hook: create the worktree where `wt switch -c` would put it.
#
# Mirrors wt's path rule:
#   <repo_root>/.worktrees/<branch with / replaced by ->
# It does not call `wt switch -c`, which fetches origin, pulls the base branch
# and refuses a dirty base worktree. tests/unit/wt-hook-consistency-test.nix
# runs both and requires the same placement.
#
# Input:  JSON on stdin, { "name": "...", "cwd": "..." }
# Output: the worktree path on stdout

set -euo pipefail

INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name')
CWD=$(echo "$INPUT" | jq -r '.cwd')

if [[ -z $NAME || $NAME == "null" ]]; then
  echo "setup-worktree: missing .name in hook input" >&2
  exit 1
fi
if [[ -z $CWD || $CWD == "null" ]]; then
  echo "setup-worktree: missing .cwd in hook input" >&2
  exit 1
fi

# Resolve the main worktree root, so running from inside a worktree does not
# nest a new one underneath it.
REPO_ROOT=$(git -C "$CWD" worktree list --porcelain | sed -n 's/^worktree //p' | head -1)

DIR="$REPO_ROOT/.worktrees/${NAME//\//-}"

mkdir -p "$REPO_ROOT/.worktrees"

if git -C "$CWD" rev-parse --verify main > /dev/null 2>&1; then
  BASE="main"
elif git -C "$CWD" rev-parse --verify master > /dev/null 2>&1; then
  BASE="master"
else
  echo "No main or master branch found" >&2
  exit 1
fi

git -C "$CWD" worktree add -b "$NAME" "$DIR" "$BASE" >&2

echo "$DIR"
