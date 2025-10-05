---
description: Create well-structured git commits with conventional commit format and automated staging
---

The user input can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## Purpose

Automate git commit workflow with:

- Conventional commit message generation
- Smart file staging
- Pre-commit hook compliance
- TDD-aware commit organization

## Usage

```bash
/commit [optional message or scope]
```

## Process Flow

1. **Analyze Changes**
   - Run `git status` to identify modified, staged, and untracked files
   - Run `git diff` for unstaged changes
   - Run `git diff --staged` for staged changes
   - Review recent commits via `git log -5 --oneline` for style consistency

2. **Categorize Changes**
   - Determine commit type based on changes:
     - `feat`: New features or functionality
     - `fix`: Bug fixes
     - `refactor`: Code restructuring without behavior change
     - `test`: Test additions or modifications
     - `docs`: Documentation updates
     - `chore`: Maintenance tasks (dependencies, configs)
     - `perf`: Performance improvements
     - `style`: Code formatting (not visual style)

3. **Generate Commit Message**
   - Follow conventional commit format: `type(scope): description`
   - Scope: Module or component affected (optional but recommended)
   - Description: Imperative mood, lowercase, no period
   - Body (if needed): Explain what and why, not how
   - Footer: Include breaking changes or issue references

4. **Smart Staging**
   - If no files staged: Auto-stage relevant files based on change type
   - Skip staging for:
     - Generated files (build artifacts, lock files unless dependency update)
     - Sensitive files (.env, credentials)
     - Temporary files (.swp, .tmp, .bak)
   - Always verify with user before staging secrets or large binary files

5. **Execute Commit**
   - Stage files via `git add [files]`
   - Create commit with generated message using heredoc format:

   ```bash
   git commit -m "$(cat <<'EOF'
   type(scope): description

   Optional body explaining context.

   🤖 Generated with [Claude Code](https://claude.ai/code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   EOF
   )"
   ```

   - NEVER use `--no-verify` flag (pre-commit hooks required)
   - If pre-commit hook modifies files, verify authorship and amend if safe

6. **Post-Commit Actions**
   - Run `git status` to confirm clean state
   - Report commit SHA and summary
   - If pre-commit hook fails: Run `make format` and retry

## Key Behaviors

- **TDD Integration**: Separate test and implementation commits when following TDD workflow
- **Atomic Commits**: One logical change per commit
- **Message Quality**: Clear, concise, searchable commit messages
- **Hook Compliance**: Never bypass pre-commit hooks
- **Safety Checks**: Warn before committing secrets or large files
- **Context Awareness**: Match existing commit style in repository

## Example Messages

```text
feat(cachix): Add binary cache module for faster builds
fix(build-switch): Resolve sudo requirement in CI environment
refactor(modules): Simplify darwin configuration using direct imports
test(unit): Add comprehensive build-switch validation tests
docs(claude): Update development workflow guidelines
```

## Best Practices

**Commit Size**

- Small enough to review easily (~50-300 lines changed)
- Large enough to be a complete logical unit
- Can be reverted independently without breaking the codebase

**When to Split Commits**

- Tests before implementation (TDD workflow)
- Refactoring separate from new features
- Bug fix separate from feature addition
- Configuration changes separate from code changes

**Message Writing**

- Start with the change impact, not implementation detail
- Answer: "What does this commit do?" not "What did I do?"
- Use body for context when summary isn't enough
- Reference issues/PRs when relevant: `Closes #123`

**Pre-Commit Checklist**

- Run tests related to your changes
- Remove debug code, console.logs, commented code
- Verify no secrets or sensitive data included
- Check diff one more time before committing

**Avoid**

- WIP commits in main branch (use feature branches)
- Generic messages: "fix bugs", "update code", "changes"
- Mixing unrelated changes in one commit
- Committing commented-out code or dead code
- Breaking changes without explicit warning in footer

## Validation Rules

- Message summary ≤ 72 characters
- Body lines wrapped at 72 characters
- Type must be from conventional commit spec
- Scope should match module/component names
- No trailing punctuation in summary
- Imperative mood (add, fix, update vs added, fixed, updated)

## Error Handling

- **Pre-commit failure**: Run `make format`, then retry commit
- **Merge conflicts**: Halt and report conflict files
- **No changes to commit**: Report status, suggest next action
- **Hook modification**: Check authorship before amending
- **Large files**: Warn and request confirmation

## Deliverables

- Git commit with conventional format
- Staged relevant files
- Clean working directory
- Pre-commit hooks executed successfully
- Commit SHA and summary reported
