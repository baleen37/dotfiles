#!/usr/bin/env bash
#
# setup-branch-protection.sh
# Sets up GitHub branch protection rules for pre-commit CI
#
# Usage:
#   ./setup-branch-protection.sh [--yes] [--branch BRANCH]
#
# Options:
#   --yes           Skip confirmation prompt
#   --branch NAME   Specify branch (default: auto-detect)

set -euo pipefail

# Parse arguments
AUTO_YES=false
BRANCH=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --yes)
      AUTO_YES=true
      shift
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--yes] [--branch BRANCH]"
      exit 1
      ;;
  esac
done

# Check gh CLI
if ! command -v gh &> /dev/null; then
  echo "❌ gh CLI not found"
  echo ""
  echo "Install:"
  echo "  brew install gh"
  echo "  # or: https://cli.github.com"
  echo ""
  echo "Or configure manually:"
  echo "  GitHub → Settings → Branches → Add rule"
  exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
  echo "❌ Not authenticated with GitHub"
  echo ""
  echo "Run: gh auth login"
  exit 1
fi

# Detect repository
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)
if [[ -z "$REPO" ]]; then
  echo "❌ Not in a GitHub repository"
  exit 1
fi

# Detect or use specified branch
if [[ -z "$BRANCH" ]]; then
  BRANCH=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo "main")
fi

echo "Repository: $REPO"
echo "Branch: $BRANCH"
echo ""

# Check existing protection
echo "Checking current branch protection..."
CURRENT_PROTECTION=$(gh api "repos/$REPO/branches/$BRANCH/protection" 2>/dev/null || echo "{}")

if [[ "$CURRENT_PROTECTION" != "{}" ]]; then
  echo "⚠️  Branch protection already exists"
  echo ""
  echo "Current settings:"
  echo "$CURRENT_PROTECTION" | jq -r '
    "- Required status checks: \(.required_status_checks.contexts // [] | join(", ") | if . == "" then "none" else . end)",
    "- Force push allowed: \(.allow_force_pushes.enabled)",
    "- Deletions allowed: \(.allow_deletions.enabled)"
  ' 2>/dev/null || echo "$CURRENT_PROTECTION"
  echo ""

  if [[ "$AUTO_YES" == "false" ]]; then
    read -p "Overwrite existing settings? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 0
  fi
fi

# Show what will be configured
echo "Will configure:"
echo "  ✓ Direct push to $BRANCH blocked (PR required)"
echo "  ✓ CI must pass to merge (pre-commit check)"
echo "  ✓ Force push disabled"
echo "  ✓ Branch deletion disabled"
echo ""

# Confirm
if [[ "$AUTO_YES" == "false" ]]; then
  read -p "Continue? [Y/n] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Cancelled"
    exit 0
  fi
fi

# Apply protection
echo "Applying branch protection..."

gh api \
  --method PUT \
  "repos/$REPO/branches/$BRANCH/protection" \
  -f required_status_checks='{"strict":true,"contexts":["pre-commit"]}' \
  -f enforce_admins=false \
  -f required_pull_request_reviews=null \
  -f restrictions=null \
  -F allow_force_pushes=false \
  -F allow_deletions=false \
  > /dev/null

echo ""
echo "✅ Branch protection enabled for $BRANCH"
echo ""
echo "Next steps:"
echo "  1. Create a PR to test"
echo "  2. Verify pre-commit CI runs"
echo "  3. Confirm merge is blocked until CI passes"
