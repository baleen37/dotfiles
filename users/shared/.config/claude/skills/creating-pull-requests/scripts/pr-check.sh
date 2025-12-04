#!/usr/bin/env bash
# Gather all context needed for creating/updating a PR
# Runs 4 independent checks in parallel for speed

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Git Status & Current Branch ===${NC}"
git status --porcelain && git branch --show-current
echo

echo -e "${BLUE}=== Base Branch & Diff ===${NC}"
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
echo "BASE=$BASE"
echo
echo "Commits:"
git log --oneline "$BASE..HEAD"
echo
echo "Files changed:"
git diff "$BASE..HEAD" --stat
echo

echo -e "${BLUE}=== PR State ===${NC}"
gh pr view --json state,number,url -q '{state: .state, number: .number, url: .url}' 2>/dev/null || echo "NO_PR"
echo

echo -e "${BLUE}=== PR Template ===${NC}"
TEMPLATE=$(find .github -maxdepth 2 -iname '*pull_request_template*' -type f 2>/dev/null | head -1)
if [ -n "$TEMPLATE" ]; then
  cat "$TEMPLATE"
else
  echo "No PR template found"
fi
