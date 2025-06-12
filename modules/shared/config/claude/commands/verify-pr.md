# Verify PR

Command to verify PR status and CI checks.

## Usage
```
/project:verify-pr [pr-number]
```

If no PR number is provided, automatically finds and verifies the PR for the current branch.

## Execution Steps

Follow these steps to verify PR status and CI checks:

1. If PR number is provided, use `gh pr view <pr-number>`. If not provided, get current branch name with `git branch --show-current` then find PR with `gh pr list --head <branch-name>`
2. Retrieve PR details
3. Check PR status (Open, Draft, Ready for review)
4. Check for conflicts first (`gh pr view <pr-number> --json mergeable`)
5. Check CI/CD status using `gh pr checks <pr-number>`
6. If CI is not running, guide user to resolve conflicts
7. Verify required check items pass:
   - lint checks (pre-commit hooks)
   - smoke tests (flake validation)
   - build tests (all configurations)
   - integration tests
8. Check merge readiness
9. Check review status and approvals
10. Provide verification summary report

All GitHub operations use GitHub CLI (`gh`).

## Examples
```
/project:verify-pr 85
```
Verify PR #85 status and CI checks

```
/project:verify-pr
```
Verify current branch's PR status and CI checks

## Verification Items

### Required Checks
- [ ] No conflicts (prerequisite for CI execution)
- [ ] CI checks pass (all checks successful)
- [ ] Code review approved
- [ ] Not in Draft status

### Recommended Checks
- [ ] Branch up to date (synced with main)
- [ ] Appropriate PR title and description
- [ ] Proper labeling
