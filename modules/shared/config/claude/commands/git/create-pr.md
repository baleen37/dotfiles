# /git/create-pr - Pull Request Creation

Create new pull requests via git-master agent with Korean conventional titles.

## Usage
```bash
/git/create-pr [--draft] [--title "custom title"]
/git/create-pr --help    # Show this help
```

## Arguments
- `--draft` - Create as draft pull request
- `--title "custom title"` - Custom PR title (if not provided, will be auto-generated)
- `--help` - Display command usage and examples

## Behavior
- **Creates new PR**: Always creates a new pull request for the current branch
- **Auto-detection**: Automatically generates conventional Korean title if not specified
- **Branch validation**: Ensures current branch is not main/master before creating PR

## Examples
```bash
# Create PR with auto-generated title
/git/create-pr

# Create draft PR
/git/create-pr --draft

# Create PR with custom title
/git/create-pr --title "feat: 새로운 사용자 인증 시스템"

# Create draft PR with custom title
/git/create-pr --draft --title "WIP: 성능 최적화 작업"

# Show help
/git/create-pr --help
```
