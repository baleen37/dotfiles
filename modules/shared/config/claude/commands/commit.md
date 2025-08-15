---
name: commit
description: "Intelligent commit message generation with change analysis and conventional commits"
---

<command>
/commit - Smart Git Commit

<purpose>
Generate intelligent commit messages through automated change analysis and conventional commit standards
</purpose>

<usage>
```bash
/commit                      # Smart commit with auto-generated message
/commit "custom message"     # Commit with custom message
```
</usage>

<execution-strategy>
- **Change Analysis**: Analyze staged files and generate contextual commit messages
- **Conventional Commits**: Follow conventional commit format (feat:, fix:, docs:, etc.)
- **Scope Detection**: Automatically detect affected modules/components for commit scope
- **Breaking Changes**: Detect and mark breaking changes in commit messages
- **Validation**: Ensure commit message follows project conventions
</execution-strategy>

<mcp-integration>
- None required for commit message generation
</mcp-integration>

<examples>
```bash
/commit                      # Auto: "feat(auth): add JWT token validation"
/commit "fix: resolve login bug"  # Custom message with validation
```
</examples>

<message-generation-logic>
1. **Analyze Changes**: Read diff of staged files
2. **Categorize Type**: Determine commit type (feat, fix, docs, style, refactor, test, chore)
3. **Extract Scope**: Identify affected modules/components
4. **Generate Description**: Create clear, concise description of changes
5. **Format Message**: Apply conventional commit format
</message-generation-logic>

<agent-routing>
- No specialized agents required for commit operations
</agent-routing>
</command>
