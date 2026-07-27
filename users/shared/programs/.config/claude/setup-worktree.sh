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

DATE_PREFIX=$(date +%y%m%d)
DIR="$REPO_ROOT/.worktrees/${DATE_PREFIX}-${NAME//\//-}"

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
