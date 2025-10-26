---
description: Manage .git/exclude file for repository-specific ignore patterns that don't belong in .gitignore
---

The user input to you can be provided directly by the agent or in `$ARGUMENTS` - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## Purpose Statement

Manage `.git/info/exclude` file to add or remove repository-specific ignore patterns that should not be committed to version control (unlike `.gitignore`). This is useful for personal development files, editor configurations, or temporary patterns that don't belong in the shared `.gitignore`.

## Usage

```
/git-exclude [pattern] [action]
/git-exclude "*.tmp" add
/git-exclude "**/.vscode" add
/git-exclude "*.tmp" remove
/git-exclude list
```

## Process Flow

1. **Validate Git Repository**: Ensure we're in a git repository
2. **Analyze Current State**: Check if `.git/info/exclude` exists and read current patterns
3. **Process User Request**:
   - `add [pattern]`: Add new ignore pattern to `.git/info/exclude`
   - `remove [pattern]`: Remove specific pattern from `.git/info/exclude`
   - `list`: Show all current patterns in `.git/info/exclude`
   - No action specified: Show current patterns and offer to add new one
4. **Pattern Validation**: Ensure patterns are valid gitignore syntax
5. **File Management**: Create or update `.git/info/exclude` file safely
6. **Verification**: Confirm changes and test pattern effectiveness

## Key Behaviors

### Pattern Addition

- Check for duplicate patterns before adding
- Validate gitignore syntax (wildcards, negations, directories)
- Preserve existing patterns and comments
- Add patterns in logical order (specific before general)

### Pattern Removal

- Support exact pattern matching
- Support fuzzy matching with user confirmation
- Preserve file structure and comments
- Handle cases where pattern doesn't exist

### File Safety

- Create `.git/info/exclude` if it doesn't exist
- Preserve existing content and formatting
- Add descriptive comments for context
- Backup original content before major changes

### Pattern Testing

- Test patterns against current working directory
- Show which files would be affected by the pattern
- Validate pattern syntax before applying
- Suggest improvements for overly broad patterns

## Implementation Details

### Validation Checks

- Verify we're in a git repository root
- Check `.git/info/exclude` file permissions
- Validate gitignore pattern syntax
- Test patterns don't conflict with `.gitignore`

### Pattern Categories

- **Personal Files**: Editor configs, OS files, personal notes
- **Development Tools**: IDE settings, debug files, profiling data
- **Temporary Patterns**: Short-term exclusions, experimental files
- **Local Builds**: Personal build artifacts, cache files

### User Interaction

- Interactive mode for ambiguous requests
- Confirmation for destructive operations
- Clear feedback on pattern effectiveness
- Suggestions for common patterns

## Deliverables

1. **Updated .git/info/exclude file** with requested patterns
2. **Pattern validation report** showing syntax and effectiveness
3. **Impact summary** of which files are now ignored/unignored
4. **Usage recommendations** for optimal pattern management

## Example Workflows

### Add Personal Development Files

```
/git-exclude "**/.vscode/settings.json" add
/git-exclude "*.local" add
/git-exclude ".env.personal" add
```

### Remove Temporary Pattern

```
/git-exclude "debug-*.log" remove
```

### List Current Exclusions

```
/git-exclude list
```

### Interactive Pattern Addition

```
/git-exclude
# Shows current patterns and prompts for new ones
```

## Integration Notes

- Works alongside `.gitignore` without conflicts
- Patterns are repository-specific and not shared
- Useful for personal workflow optimizations
- Complements existing git ignore management tools
