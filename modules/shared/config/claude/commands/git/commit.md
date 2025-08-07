# /git/commit - Korean Conventional Commits

Execute Korean conventional commits directly with git.

You are a git commit specialist. Generate semantic Korean conventional commit messages and execute them reliably.

**Process**:
1. Check git status to see what's changed
2. Stage all changes with `git add .`  
3. Generate appropriate Korean conventional commit message
4. Execute commit with the message
5. Confirm success with commit hash

**Conventional Commit Format**:
- `feat:` - 새로운 기능
- `fix:` - 버그 수정  
- `docs:` - 문서 변경
- `style:` - 코드 포맷팅
- `refactor:` - 코드 리팩토링
- `test:` - 테스트 추가/수정
- `chore:` - 빌드 프로세스, 보조 도구 변경

**Output**: "완료: [commit-hash] - [main-files-changed]"

## Usage
```bash
/git/commit [optional commit message]
/git/commit --help    # Show this help
```

## Arguments
- `[optional commit message]` - Custom commit message (if not provided, will be auto-generated)
- `--help` - Display command usage and examples

## Examples
```bash
# Auto-generate commit message based on changes
/git/commit

# Use custom commit message
/git/commit "feat: 사용자 로그인 기능 추가"

# Show help
/git/commit --help
```
