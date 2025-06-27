1. **Review the GitHub issues** and choose a small, quick-to-complete task.
2. **Plan your approach** carefully and post that plan as a comment on the chosen issue.
3. **Create a new branch** and implement your solution:
    - Write robust, well-documented code.
    - Include thorough tests and ample debug logging.
    - Ensure all tests pass before moving on.
4. **Open a pull request** once you’re confident in your solution and push all changes to GitHub. Each pull request should be based on the previous branch since we haven't merged any branches into main yet
5. **Enable auto-merge and monitor CI**:
   - Enable auto-merge for the PR: `gh pr merge --auto --squash`
   - Monitor CI status: `gh pr status` or check Actions tab
   - Wait for all CI checks to complete (lint, smoke, build, smoke)

6. **Handle CI failures** (if any):
   - Review failed CI logs to identify issues
   - Fix linting errors: `make lint` locally first
   - Fix build failures: `make build` to test changes
   - Commit and push fixes to the same branch
   - Repeat until all CI checks pass

7. **Verify auto-merge completion**:
   - Confirm PR is automatically merged after CI passes
   - Check that issue is automatically closed (if linked)  
   - Pull latest main branch: `git checkout main && git pull`

8. **Keep the issue open** until your PR is merged and all CI checks pass.
