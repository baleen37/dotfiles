# /git/upsert-pr - Pull Request Creation & Update

Create new pull requests or update existing ones via git-master agent with Korean conventional titles.

## Usage
```bash
/git/upsert-pr [--draft] [--title "custom title"] [--update]
/git/upsert-pr --help    # Show this help
```

## Arguments
- `--draft` - Create as draft pull request
- `--title "custom title"` - Custom PR title (if not provided, will be auto-generated)
- `--update` - Update existing PR instead of creating new one
- `--help` - Display command usage and examples

## Upsert Behavior
- **If PR exists**: Updates title, description, and converts between draft/ready status
- **If PR doesn't exist**: Creates new PR with specified options
- **Auto-detection**: Automatically detects existing PR for current branch

## Examples
```bash
# Create/update PR with auto-generated title (upsert behavior)
/git/upsert-pr

# Create/update draft PR
/git/upsert-pr --draft

# Create/update PR with custom title
/git/upsert-pr --title "feat: 새로운 사용자 인증 시스템"

# Force update existing PR (explicit update mode)
/git/upsert-pr --update --title "Updated: 성능 최적화 완료"

# Create draft PR with custom title
/git/upsert-pr --draft --title "WIP: 성능 최적화 작업"

# Convert existing draft to ready
/git/upsert-pr --update

# Show help
/git/upsert-pr --help
```
