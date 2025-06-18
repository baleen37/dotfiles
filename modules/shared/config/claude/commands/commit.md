# Claude Command: Commit

This command helps you create well-formatted commits with conventional commit messages.

## Usage

To create a commit, just type:
```
/commit
```

Or with options:
```
/commit --no-verify
```

## What This Command Does

1. Unless specified with `--no-verify`, runs any configured pre-commit hooks
2. Checks which files are staged with `git status`
3. If no files are staged, automatically adds all modified and new files with `git add`
4. Performs a `git diff` to understand what changes are being committed
5. Analyzes the diff to determine if multiple distinct logical changes are present
6. If multiple distinct changes are detected, suggests breaking the commit into multiple smaller commits
7. For each commit (or the single commit if not split), creates a commit message using conventional commit format

## Best Practices for Commits

- **Verify before committing**: Ensure code is linted, builds correctly, and documentation is updated
- **Atomic commits**: Each commit should contain related changes that serve a single purpose
- **Split large changes**: If changes touch multiple concerns, split them into separate commits
- **Conventional commit format**: Use the format `<type>: <description>` where type is one of:
  - `feat`: A new feature
  - `fix`: A bug fix
  - `docs`: Documentation changes
  - `style`: Code style changes (formatting, etc)
  - `refactor`: Code changes that neither fix bugs nor add features
  - `perf`: Performance improvements
  - `test`: Adding or fixing tests
  - `chore`: Changes to the build process, tools, etc.
- **Present tense, imperative mood**: Write commit messages as commands (e.g., "add feature" not "added feature")
- **Concise first line**: Keep the first line under 72 characters

## Choosing the Right Commit Type

When unsure which type to use, ask yourself these questions:

1. **Did the behavior change from the user's perspective?**
   - Yes, new behavior → `feat`
   - Yes, fixed broken behavior → `fix`
   - No → Continue to next question

2. **Did you change how the code works internally?**
   - Yes → `refactor`
   - No → Continue to next question

3. **Did you only change formatting, whitespace, or code style?**
   - Yes → `style`

4. **Did you change documentation, comments, or README files?**
   - Yes → `docs`

5. **Did you change tests?**
   - Yes → `test`

6. **Did you change build scripts, dependencies, or tooling?**
   - Yes → `chore`

7. **Did you improve performance without changing behavior?**
   - Yes → `perf`

## Guidelines for Splitting Commits

When analyzing the diff, consider splitting commits based on these criteria:

1. **Different concerns**: Changes to unrelated parts of the codebase
2. **Different types of changes**: Mixing features, fixes, refactoring, etc.
3. **File patterns**: Changes to different types of files (e.g., source code vs documentation)
4. **Logical grouping**: Changes that would be easier to understand or review separately
5. **Size**: Very large changes that would be clearer if broken down

### Signs You Should Split Your Commit

- You want to use words like "and", "also", or "plus" in your commit message
- The changes affect multiple unrelated features or modules
- Reverting the commit would break unrelated functionality
- The diff is longer than 200 lines across multiple files
- You're mixing different commit types (e.g., feat + fix + refactor)
- A reviewer would need to understand multiple concepts to review the changes

## Examples

Good commit messages:
- feat: add user authentication system
- fix: resolve memory leak in rendering process
- docs: update API documentation with new endpoints
- refactor: simplify error handling logic in parser
- fix: resolve linter warnings in component files
- chore: improve developer tooling setup process
- feat: implement business logic for transaction validation
- fix: address minor styling inconsistency in header
- fix: patch critical security vulnerability in auth flow
- style: reorganize component structure for better readability
- fix: remove deprecated legacy code
- feat: add input validation for user registration form
- fix: resolve failing CI pipeline tests
- feat: implement analytics tracking for user engagement
- fix: strengthen authentication password requirements
- feat: improve form accessibility for screen readers

Example of splitting commits:
- First commit: feat: add new solc version type definitions
- Second commit: docs: update documentation for new solc versions
- Third commit: chore: update package.json dependencies
- Fourth commit: feat: add type definitions for new API endpoints
- Fifth commit: feat: improve concurrency handling in worker threads
- Sixth commit: fix: resolve linting issues in new code
- Seventh commit: test: add unit tests for new solc version features
- Eighth commit: fix: update dependencies with security vulnerabilities

## Command Options

- `--no-verify`: Skip running pre-commit hooks

## Commit Message Length Guidelines

- **Subject line**: 50 characters ideal, 72 maximum
- **Body** (if needed): Wrap at 72 characters
- **Why 50/72?**: Git log displays better, email patches work correctly

Example structure:
```
type: short description under 50 chars

Longer explanation wrapped at 72 characters if needed.
Explain what and why, not how. The code shows how.

## Important Notes

- By default, pre-commit hooks will run if configured in the repository
- If specific files are already staged, the command will only commit those files
- If no files are staged, it will automatically stage all modified and new files
- The commit message will be constructed based on the changes detected
- Before committing, the command will review the diff to identify if multiple commits would be more appropriate
- If suggesting multiple commits, it will help you stage and commit the changes separately
- Always reviews the commit diff to ensure the message matches the changes
