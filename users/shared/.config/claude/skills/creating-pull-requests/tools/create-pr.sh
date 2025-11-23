#!/usr/bin/env bash
set -euo pipefail

# create-pr.sh - Automated pull request creation with safety checks
# Usage: ./create-pr.sh [--auto-merge]

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AUTO_MERGE=false
TARGET_BRANCH="main"

# Parse arguments first (before git root detection)
while [[ $# -gt 0 ]]; do
  case $1 in
    --auto-merge)
      AUTO_MERGE=true
      shift
      ;;
    --help)
      cat <<EOF
Usage: ./create-pr.sh [OPTIONS]

Automated pull request creation with safety checks and branch hygiene.

OPTIONS:
  --auto-merge    Enable auto-merge on PR after creation
  --help          Show this help message

WORKFLOW:
  1. Check project conventions (CONTRIBUTING, PR templates)
  2. Analyze repository state
  3. Auto-commit uncommitted changes
  4. Create feature branch if on main/master
  5. Check conflicts and rebase only if needed
  6. Create pull request

EXAMPLES:
  ./create-pr.sh                 # Create PR normally
  ./create-pr.sh --auto-merge    # Create PR with auto-merge enabled
EOF
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Run with --help for usage information"
      exit 1
      ;;
  esac
done

# Find git root and change to it
# Strategy:
# 1. Try from PWD (Claude Code's working directory)
# 2. Try from script's directory (handles symlinked script location)
# 3. Try from OLDPWD (handles directory changes by shell)

# Save directories to try
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DIR="$PWD"

# Try multiple locations to find git root
GIT_ROOT=""

# Try 1: From current working directory (PWD) - most likely location
if [ -z "$GIT_ROOT" ]; then
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
fi

# Try 2: From script's directory (if script is in git repo)
if [ -z "$GIT_ROOT" ]; then
  (cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null) && \
    GIT_ROOT=$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null || true)
fi

# Try 3: From OLDPWD if available
if [ -z "$GIT_ROOT" ] && [ -n "${OLDPWD:-}" ]; then
  (cd "$OLDPWD" && git rev-parse --show-toplevel 2>/dev/null) && \
    GIT_ROOT=$(cd "$OLDPWD" && git rev-parse --show-toplevel 2>/dev/null || true)
fi

# If still not found, error out with helpful message
if [ -z "$GIT_ROOT" ]; then
  echo -e "${RED}Error: Not in a git repository${NC}"
  echo "Tried looking for git repository in:"
  echo "  - Current directory: $CURRENT_DIR"
  echo "  - Script directory: $SCRIPT_DIR"
  [ -n "${OLDPWD:-}" ] && echo "  - Previous directory: $OLDPWD"
  echo ""
  echo "Please ensure you're running this from within a git repository"
  exit 1
fi

# Change to git root directory
cd "$GIT_ROOT"
echo -e "${BLUE}Working directory:${NC} $GIT_ROOT"

# Helper functions
log_step() {
  echo -e "\n${BLUE}==>${NC} $1"
}

log_success() {
  echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Step 0: Check project conventions
check_conventions() {
  log_step "Step 0: Checking project conventions"

  local found_files=$(find . -maxdepth 2 \( -name "CONTRIBUTING*" -o -name "PULL_REQUEST*" \) -type f 2>/dev/null || true)

  if [ -n "$found_files" ]; then
    log_success "Found contribution guidelines:"
    echo "$found_files" | sed 's/^/  - /'
    echo ""
    echo "Please review for:"
    echo "  - Commit message format requirements"
    echo "  - Branch naming conventions"
    echo "  - PR template/checklist requirements"
    echo "  - Target branch (main vs master vs develop)"
  else
    log_warning "No CONTRIBUTING or PULL_REQUEST template found"
  fi
}

# Step 1: Analyze repository state
analyze_repo_state() {
  log_step "Step 1: Analyzing repository state"

  echo "Working directory state:"
  git status --short

  echo -e "\nRecent commits:"
  git log --oneline -5

  echo -e "\nFetching latest changes..."
  git fetch origin

  echo -e "\nCommits ahead of $TARGET_BRANCH:"
  git log --oneline origin/$TARGET_BRANCH..HEAD || log_warning "Unable to compare with origin/$TARGET_BRANCH"

  echo -e "\nCommits behind $TARGET_BRANCH:"
  git log --oneline HEAD..origin/$TARGET_BRANCH || log_warning "Unable to compare with origin/$TARGET_BRANCH"
}

# Step 2: Handle uncommitted changes
commit_changes() {
  log_step "Step 2: Checking for uncommitted changes"

  if [[ -z $(git status --porcelain) ]]; then
    log_success "No uncommitted changes"
    return
  fi

  log_warning "Found uncommitted changes - auto-committing..."

  # Show what's being committed
  echo -e "\nFiles to commit:"
  git status --short

  # Analyze changes for commit message
  local changed_files=$(git diff --cached --name-only 2>/dev/null || git diff --name-only)
  local recent_style=$(git log -1 --pretty=format:'%s' 2>/dev/null || echo "")

  git add .

  # Generate commit message
  local commit_msg="feat: auto-commit changes for PR

Files changed:
$(echo "$changed_files" | sed 's/^/- /')

Generated with Claude Code (https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

  git commit -m "$commit_msg"
  log_success "Changes committed"
}

# Step 3: Branch management
manage_branches() {
  log_step "Step 3: Managing branches"

  local current_branch=$(git branch --show-current)

  if [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
    log_success "Already on feature branch: $current_branch"
    return
  fi

  log_warning "On $current_branch - creating feature branch..."

  # Generate feature branch name
  local timestamp=$(date +%Y-%m-%d)
  local commit_hash=$(git log -1 --pretty=format:'%h')
  local feature_branch="feature/${timestamp}-${commit_hash}"

  # Create and push feature branch
  git checkout -b "$feature_branch"
  git push -u origin "$feature_branch"

  log_success "Created feature branch: $feature_branch"
  log_warning "Note: $current_branch still contains these commits"
  echo "  You can clean up $current_branch later with:"
  echo "  git checkout $current_branch && git reset --hard origin/$current_branch"
}

# Step 4: Check conflicts and rebase if needed
check_and_rebase() {
  log_step "Step 4: Checking for conflicts with $TARGET_BRANCH"

  # Get merge base
  local merge_base=$(git merge-base HEAD origin/$TARGET_BRANCH 2>/dev/null || echo "")

  if [ -z "$merge_base" ]; then
    log_error "Unable to find merge base with origin/$TARGET_BRANCH"
    exit 1
  fi

  # Check for potential conflicts
  local conflicts=$(git diff --name-only "$merge_base"..HEAD "$merge_base"..origin/$TARGET_BRANCH 2>/dev/null | sort | uniq -d || true)

  if [ -z "$conflicts" ]; then
    log_success "No conflicts detected - rebase not needed"
    return
  fi

  log_warning "Potential conflicts detected in:"
  echo "$conflicts" | sed 's/^/  - /'

  echo -e "\nAttempting rebase..."
  if git rebase origin/$TARGET_BRANCH; then
    log_success "Rebase completed successfully"
  else
    log_error "Rebase conflicts detected. Please resolve manually:"
    echo ""
    git diff --name-only --diff-filter=U | sed 's/^/  - /'
    echo ""
    echo "After resolving conflicts, run:"
    echo "  git add ."
    echo "  git rebase --continue"
    echo "  git push origin \$(git branch --show-current) --force-with-lease"
    echo "  gh pr create ..."
    exit 1
  fi
}

# Step 5: Create pull request
create_pr() {
  log_step "Step 5: Creating pull request"

  local current_branch=$(git branch --show-current)

  # Check if PR already exists
  if gh pr view --json number >/dev/null 2>&1; then
    local pr_number=$(gh pr view --json number --jq '.number')
    log_warning "PR already exists for this branch: #$pr_number"

    if [ "$AUTO_MERGE" = true ]; then
      log_step "Enabling auto-merge on existing PR..."
      gh pr merge "$pr_number" --auto --squash
      log_success "Auto-merge enabled on PR #$pr_number"
    fi

    gh pr view
    exit 0
  fi

  # Push changes (force-with-lease if rebased)
  if git log --oneline origin/$TARGET_BRANCH..HEAD | grep -q "rebase"; then
    git push origin "$current_branch" --force-with-lease
  else
    git push origin "$current_branch"
  fi

  # Generate PR description
  local pr_title=$(git log -1 --pretty=format:'%s')
  local commits=$(git log --oneline origin/$TARGET_BRANCH..HEAD | sed 's/^/- /')

  local pr_body="## Summary
Changes in this PR:

$commits

## Test Plan
- [ ] Verify key functionality
- [ ] Test edge cases
- [ ] Confirm integration points

Generated with Claude Code (https://claude.com/claude-code)"

  # Create PR
  local pr_url=$(gh pr create \
    --title "$pr_title" \
    --body "$pr_body")

  log_success "PR created: $pr_url"

  # Enable auto-merge if requested
  if [ "$AUTO_MERGE" = true ]; then
    log_step "Enabling auto-merge..."
    local pr_number=$(echo "$pr_url" | grep -o '[0-9]\+$')
    gh pr merge "$pr_number" --auto --squash
    log_success "Auto-merge enabled"
  fi

  # Show PR details
  gh pr view
}

# Main workflow
main() {
  echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC}  Automated PR Creation with Safety   ${BLUE}║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

  check_conventions
  analyze_repo_state
  commit_changes
  manage_branches
  check_and_rebase
  create_pr

  echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║${NC}         PR Creation Complete!         ${GREEN}║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
}

main
