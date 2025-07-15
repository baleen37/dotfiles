#!/bin/bash
# Branch Protection Setup Script
# Configures main branch protection with required CI checks
# while allowing merge without code review

set -euo pipefail

REPO_FULL_NAME=$(gh repo view --json owner,name --jq '.owner.login + "/" + .name')
REPO_NAME=$(gh repo view --json name --jq '.name')
BRANCH="main"

echo "Setting up branch protection for $REPO_FULL_NAME branch: $BRANCH"

# Define required status checks based on available workflows
REQUIRED_CHECKS=(
    "CI Summary"
    "Validate & Lint"
)

echo "Required status checks to be configured:"
for check in "${REQUIRED_CHECKS[@]}"; do
    echo "  - $check"
done

# Create branch protection configuration
PROTECTION_CONFIG=$(cat <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [$(printf '"%s",' "${REQUIRED_CHECKS[@]}" | sed 's/,$//')]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false,
  "lock_branch": false,
  "allow_fork_syncing": true
}
EOF
)

echo "Branch protection configuration:"
echo "$PROTECTION_CONFIG" | jq .

# Apply branch protection settings
echo "Applying branch protection settings..."
if echo "$PROTECTION_CONFIG" | gh api repos/"$REPO_FULL_NAME"/branches/"$BRANCH"/protection --method PUT --input -; then
    echo "✅ Branch protection successfully configured for $BRANCH"
    echo ""
    echo "Configuration summary:"
    echo "  - Required status checks: ENABLED (strict mode)"
    echo "  - Required checks: $(printf '%s, ' "${REQUIRED_CHECKS[@]}" | sed 's/, $//')"
    echo "  - Required approving reviews: 0 (merge without code review allowed)"
    echo "  - Dismiss stale reviews: YES"
    echo "  - Force pushes: BLOCKED"
    echo "  - Branch deletions: BLOCKED"
    echo ""
    echo "🎯 Issue #403 requirements met:"
    echo "  ✅ CI tests must pass before merge"
    echo "  ✅ Merge without code review still possible"
    echo "  ✅ Auto-merge will wait for required checks"
else
    echo "❌ Failed to configure branch protection"
    echo "Please check your GitHub permissions and try again"
    exit 1
fi

# Verify the configuration
echo "Verifying branch protection configuration..."
CURRENT_PROTECTION=$(gh api repos/"$REPO_FULL_NAME"/branches/"$BRANCH"/protection)

echo "Current protection status:"
echo "$CURRENT_PROTECTION" | jq '{
    required_status_checks: .required_status_checks,
    required_pull_request_reviews: .required_pull_request_reviews,
    enforce_admins: .enforce_admins
}'

echo ""
echo "✅ Branch protection setup completed successfully!"
