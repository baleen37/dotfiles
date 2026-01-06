#!/usr/bin/env bash
# Gather all context needed for creating/updating a PR

set -euo pipefail

echo "# Git Status"
git status --porcelain
git branch --show-current
echo

echo "# Base Branch & Diff"
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
echo "BASE=$BASE"
git log --oneline "$BASE..HEAD"
git diff "$BASE..HEAD" --stat
echo

echo "# PR State"
gh pr view --json state,number,url -q '{state: .state, number: .number, url: .url}' 2>/dev/null || echo "NO_PR"
echo

echo "# PR Template"
find .github -maxdepth 2 -iname '*pull_request_template*' -type f 2>/dev/null | head -1 | xargs cat 2>/dev/null || echo "None"
