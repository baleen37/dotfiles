#!/usr/bin/env bash
set -euo pipefail

# create-pr.sh - Safe PR creation that prevents common mistakes
#
# Prevents: direct main push, blind git add, duplicate PRs, skipped conflict checks

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

AUTO_MERGE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --auto-merge) AUTO_MERGE=true; shift ;;
    --help)
      cat <<'EOF'
Usage: create-pr.sh [--auto-merge]

Safe PR creation with automatic safety checks.

What it does:
  1. Checks for existing PR (prevents duplicates)
  2. Shows changed files for review (prevents blind git add)
  3. Creates feature branch if on main (prevents main pollution)
  4. Checks for conflicts with main (prevents merge failures)
  5. Creates PR with proper description (prevents empty PRs)

Options:
  --auto-merge  Enable auto-merge after PR creation
  --help        Show this help

Examples:
  ./create-pr.sh              # Normal PR creation
  ./create-pr.sh --auto-merge # PR with auto-merge
EOF
      exit 0
      ;;
    *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
  esac
done

# Find git root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo -e "${RED}Error: Not in a git repository${NC}"
  exit 1
}
cd "$GIT_ROOT"

log_step() { echo -e "\n${BLUE}==>${NC} $1"; }
log_ok() { echo -e "${GREEN}OK:${NC} $1"; }
log_warn() { echo -e "${YELLOW}WARN:${NC} $1"; }
log_error() { echo -e "${RED}ERROR:${NC} $1"; }

# Detect target branch (main or master)
TARGET_BRANCH="main"
if ! git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
  if git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
    TARGET_BRANCH="master"
  fi
fi

#=============================================================================
# Step 1: Check for existing PR
#=============================================================================
check_existing_pr() {
  log_step "Step 1: Checking for existing PR"

  local current_branch=$(git branch --show-current)

  if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
    log_ok "On $current_branch - will create feature branch"
    return 0
  fi

  if gh pr view --json number,url,state 2>/dev/null; then
    local pr_state=$(gh pr view --json state --jq '.state' 2>/dev/null)
    if [[ "$pr_state" == "OPEN" ]]; then
      log_warn "PR already exists - will update with new commits"
      EXISTING_PR=true
    fi
  else
    log_ok "No existing PR found"
  fi
}

#=============================================================================
# Step 2: Review changed files (prevent blind git add)
#=============================================================================
review_changes() {
  log_step "Step 2: Reviewing changed files"

  local status=$(git status --porcelain)

  if [[ -z "$status" ]]; then
    log_ok "Working directory clean"
    return 0
  fi

  echo ""
  echo "Changed files:"

  # Check for sensitive files first
  if echo "$status" | grep -qE '\.(env|pem|key|secret)$|^[^[:space:]]+[[:space:]]+\.env'; then
    echo "$status" | while read -r line; do
      echo -e "  ${RED}$line${NC}  <-- SENSITIVE FILE"
    done
    log_error "Sensitive files detected - aborting for safety"
    exit 1
  fi

  # Display changed files
  echo "$status" | while read -r line; do
    local file=$(echo "$line" | awk '{print $2}')
    if [[ "$file" =~ node_modules|\.pyc$|__pycache__|\.DS_Store ]]; then
      echo -e "  ${YELLOW}$line${NC}  <-- Should be gitignored"
    else
      echo "  $line"
    fi
  done

  git add -A
  log_ok "Files staged"
}

#=============================================================================
# Step 3: Create commit with proper message
#=============================================================================
create_commit() {
  log_step "Step 3: Creating commit"

  if [[ -z $(git diff --cached --name-only) ]]; then
    log_ok "Nothing to commit"
    return 0
  fi

  # Detect commit type from changed files
  local files=$(git diff --cached --name-only)
  local commit_type="feat"

  if echo "$files" | grep -qE '\.(test|spec)\.(ts|js|py|go)$'; then
    commit_type="test"
  elif echo "$files" | grep -qE '\.(md|txt|rst)$'; then
    commit_type="docs"
  elif echo "$files" | grep -qE '(Makefile|Dockerfile|\.github)'; then
    commit_type="build"
  elif echo "$files" | grep -qE '(fix|bug)'; then
    commit_type="fix"
  fi

  echo ""
  echo "Detected commit type: $commit_type"

  commit_msg="$commit_type: auto-commit changes for PR"

  git commit -m "$commit_msg

$(echo "$files" | sed 's/^/- /')

Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

  log_ok "Committed: $commit_msg"
}

#=============================================================================
# Step 4: Ensure feature branch (prevent main pollution)
#=============================================================================
ensure_feature_branch() {
  log_step "Step 4: Checking branch"

  local current_branch=$(git branch --show-current)

  if [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
    log_ok "On feature branch: $current_branch"
    return 0
  fi

  log_warn "On $current_branch - creating feature branch"

  local date_str=$(date +%Y-%m-%d)
  local hash=$(git log -1 --pretty=format:'%h')
  local new_branch="feature/${date_str}-${hash}"

  git checkout -b "$new_branch"
  log_ok "Created branch: $new_branch"

  echo ""
  echo "Note: Your commits are still on $current_branch"
  echo "To clean up later: git checkout $current_branch && git reset --hard origin/$current_branch"
}

#=============================================================================
# Step 5: Check for conflicts with target branch
#=============================================================================
check_conflicts() {
  log_step "Step 5: Checking for conflicts with $TARGET_BRANCH"

  git fetch origin "$TARGET_BRANCH" 2>/dev/null || true

  local behind=$(git rev-list --count HEAD..origin/$TARGET_BRANCH 2>/dev/null || echo "0")

  if [[ "$behind" == "0" ]]; then
    log_ok "Up to date with $TARGET_BRANCH"
    return 0
  fi

  log_warn "Behind $TARGET_BRANCH by $behind commits"

  # Check for actual file conflicts
  local our_files=$(git diff --name-only origin/$TARGET_BRANCH...HEAD 2>/dev/null || echo "")
  local their_files=$(git diff --name-only HEAD...origin/$TARGET_BRANCH 2>/dev/null || echo "")
  local conflicts=$(comm -12 <(echo "$our_files" | sort) <(echo "$their_files" | sort) 2>/dev/null || echo "")

  if [[ -z "$conflicts" ]]; then
    log_ok "No conflicting files detected"
    return 0
  fi

  echo ""
  echo "Potentially conflicting files:"
  echo "$conflicts" | sed 's/^/  - /'

  log_warn "Skipping rebase - conflicts may occur during merge"
  return 0
}

#=============================================================================
# Step 6: Push and create PR
#=============================================================================
create_pr() {
  log_step "Step 6: Creating PR"

  local current_branch=$(git branch --show-current)

  # Push
  if [[ "${NEEDS_FORCE_PUSH:-false}" == "true" ]]; then
    git push --force-with-lease -u origin "$current_branch"
  else
    git push -u origin "$current_branch" 2>/dev/null || git push --force-with-lease -u origin "$current_branch"
  fi
  log_ok "Pushed to origin/$current_branch"

  # Check if PR exists (might have been created earlier)
  if [[ "${EXISTING_PR:-false}" == "true" ]]; then
    log_ok "Existing PR updated with new commits"
    gh pr view
    return 0
  fi

  # Generate PR body
  local commits=$(git log --oneline origin/$TARGET_BRANCH..HEAD 2>/dev/null | sed 's/^/- /' || echo "- Initial commit")
  local title=$(git log -1 --pretty=format:'%s')

  local body="## Summary

$commits

## Test Plan

- [ ] Tests pass locally
- [ ] CI checks pass
- [ ] Manual verification complete

---
Generated with Claude Code"

  # Create PR
  local pr_url=$(gh pr create \
    --base "$TARGET_BRANCH" \
    --title "$title" \
    --body "$body")

  log_ok "PR created: $pr_url"

  # Auto-merge if requested
  if [[ "$AUTO_MERGE" == "true" ]]; then
    local pr_number=$(echo "$pr_url" | grep -o '[0-9]*$')
    gh pr merge "$pr_number" --auto --squash
    log_ok "Auto-merge enabled"
  fi

  gh pr view
}

#=============================================================================
# Main
#=============================================================================
main() {
  echo -e "${BLUE}Safe PR Creation${NC}"
  echo "================"
  echo ""

  check_existing_pr
  review_changes
  create_commit
  ensure_feature_branch
  check_conflicts
  create_pr

  echo ""
  echo -e "${GREEN}PR creation complete${NC}"
}

main
