---
description: Review code and create GitHub issues collaboratively with the user
---

# Make GitHub Issue

Review code and create GitHub issues collaboratively with the user.

**Process:**

1. **Code Analysis & Issue Identification**
   - Review the code for bugs, design issues, and code quality problems
   - Identify multiple issues but avoid over-fragmentation
   - Focus on meaningful, substantial problems that warrant separate issues

2. **Collaborative Review**
   - Present numbered list of identified issues to the user:
     ```
     1. [CRITICAL] Authentication bypass vulnerability in login handler
     2. [HIGH] Memory leak in data processing loop
     3. [MEDIUM] Missing error handling for API calls
     4. [LOW] Code style inconsistencies in utility functions
     ```
   - Discuss priority and impact with the user
   - Ask which issues the user wants to create on GitHub
   - Confirm final selection before proceeding

3. **Duplicate Issue Check**
   - Before creating each approved issue, search existing GitHub issues
   - Use `gh issue list --search "keyword"` or similar queries
   - Check for:
     - Similar problem descriptions
     - Related error messages
     - Overlapping functionality areas
   - If duplicates found, inform user and suggest:
     - Adding comment to existing issue instead
     - Modifying scope to avoid duplication
     - Skipping if already covered

4. **GitHub Issue Creation**
   - Create issues only for user-approved, non-duplicate items
   - Each issue includes:
     - Specific, actionable title
     - Clear problem description
     - Steps to reproduce (if applicable)
     - Expected vs actual behavior
     - Suggested solution approach
   - Use `gh` CLI when available

**Important:** Never create issues without explicit user approval and duplicate verification. Always present options and let the user decide what to prioritize.
