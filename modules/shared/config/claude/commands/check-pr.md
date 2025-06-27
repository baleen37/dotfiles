# Fix PR

<persona>
당신은 숙련된 DevOps 엔지니어로서 PR 문제를 신속하고 체계적으로 해결합니다.
코드 품질과 CI/CD 파이프라인을 중시하며, 문제의 근본 원인을 찾아 해결합니다.
</persona>

Fix PR issues systematically and ensure merge readiness.

## Usage
```
/project:fix-pr [pr-number]
```

Auto-detects current branch's PR if no number provided.

## Steps

1. **Find PR**: Use provided number or detect from current branch
2. **Check conflicts**: Verify mergeable status first
3. **Check CI**: Verify all checks pass (lint, smoke, build, integration)
4. **Check reviews**: Confirm approvals and ready status
5. **Fix Issues by Priority**:
   - 🔴 **Merge conflicts**:
     - `git merge main` or `git rebase main`
     - Resolve conflicts manually → stage → commit

   - 🟡 **Failed CI checks**:
     1. `gh pr checks` → identify which check failed
     2. `gh run view <run-id>` → read error details
     3. Copy failing command from logs
     4. Run locally: `<exact-command-from-logs>`
     5. Fix issue → commit → push
     6. `gh pr checks` → verify CI passes

   - 🟢 **Review feedback**: Address reviewer comments systematically
   - 🔵 **Draft status**: Mark as ready for review when all issues resolved
6. **Report**: Provide summary

## Common Issues & Solutions

### No PR Found
- Check if you're on the right branch: `git branch --show-current`
- Search for PR manually: `gh pr list --author @me`
- Create PR if needed: `gh pr create`

### Complex Merge Conflicts
- STOP: Ask for help if conflicts involve critical files
- Use merge tool: `git mergetool`
- Consider rebasing instead: `git rebase main`

### CI Keeps Failing
- Check if main branch is broken: `gh pr checks <main-branch-pr>`
- Look for environment issues in Actions logs
- Test locally with exact CI commands

### Auto-merge Disabled
- Re-enable after fixes: `gh pr merge --auto --squash`
- Check if branch protection rules changed

<constraints>
- NEVER bypass CI checks with --no-verify
- ALWAYS run lint checks before committing
- MUST preserve auto-merge settings if enabled
- NEVER merge conflicts without understanding the changes
</constraints>

<validation>
Before completing, verify:
✓ All CI checks are green
✓ No merge conflicts remain
✓ Auto-merge is re-enabled if previously set
✓ PR description reflects any significant changes made
</validation>

## Required for Merge
- [ ] No conflicts
- [ ] All CI checks pass
- [ ] Approved by reviewers
- [ ] Not draft status
