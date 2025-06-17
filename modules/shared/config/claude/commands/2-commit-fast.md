---
title: 'Fast Commit Task'
read_only: true
type: 'command'
---

# Fast Commit

Quickly commit staged changes with auto-generated commit messages. This command automatically selects the first suggested commit message without confirmation.

## Usage

Simply run this command when you have staged changes ready to commit. The command will:

1. Check for staged changes
2. Generate 3 commit message suggestions
3. Automatically use the first suggestion
4. Create the commit immediately

## Behavior

- **Automatic Selection**: Uses the first commit message without asking
- **Format**: Follows conventional commit format (type(scope): description)
- **Scope Detection**: Automatically detects package names from changed files
- **Staged Only**: Only commits staged changes
- **No AI Attribution**: Does not add Claude co-authorship footer

## Example Workflow

```bash
# Stage your changes
git add .

# Run fast commit
# The command will generate messages and immediately commit with the first one
```

## Commit Message Format

Messages follow the pattern:
- `feat(package): Add new feature`
- `fix(module): Resolve issue with X`
- `docs(readme): Update installation instructions`
- `refactor(core): Simplify logic in Y`
- `test(unit): Add tests for Z`

The command intelligently detects the appropriate type, scope, and description based on the staged changes.
