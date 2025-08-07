# /git/update-pr - Pull Request Update

Update existing pull requests via git-master agent with Korean conventional titles.

## Usage
```bash
/git/update-pr [--draft] [--ready] [--title "custom title"]
/git/update-pr --help    # Show this help
```

## Arguments
- `--draft` - Convert PR to draft status
- `--ready` - Convert draft PR to ready for review
- `--title "custom title"` - Update PR title (if not provided, keeps current title)
- `--help` - Display command usage and examples

## Behavior
- **Updates existing PR**: Modifies the pull request for the current branch
- **Auto-detection**: Automatically finds existing PR for current branch
- **Status management**: Handles draft/ready status conversion
- **Title update**: Updates PR title and description as needed

## Examples
```bash
# Update existing PR (keeps current title and status)
/git/update-pr

# Convert PR to draft
/git/update-pr --draft

# Convert draft PR to ready for review
/git/update-pr --ready

# Update PR title
/git/update-pr --title "feat: 사용자 인증 시스템 완료"

# Update title and convert to ready
/git/update-pr --ready --title "feat: 성능 최적화 완료"

# Show help
/git/update-pr --help
```
