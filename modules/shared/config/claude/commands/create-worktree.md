# Command: create-worktree

## Description
Intelligently and quickly creates a new git worktree. It analyzes your request, project conventions, and current git state to determine the best branch name and path, then immediately creates the worktree without requiring confirmation.

## Usage
-   **Direct**: `@create-worktree [type] <description>`
-   **Conversational**: "I need to work on a fix for a null pointer issue."

## Arguments
-   `[type]` (Optional): The type of change. Defaults to `feat`. Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.
-   `<description>` (Required): A short, descriptive name for the branch (e.g., `add-login-button`).

## High-Speed, No-Confirmation Workflow

This command is optimized for maximum speed by eliminating any interactive approval steps.

1.  **Concurrent Analysis**: As soon as the command is invoked, it runs several git commands in parallel to gather all necessary information instantly:
    *   `git fetch --all`: Fetches all remotes to ensure the latest data.
    *   `git remote show origin`: Identifies the default branch (e.g., `main` or `master`).
    *   `git branch -r --sort=-committerdate`: Reviews recent branch names to learn project-specific naming conventions.

2.  **Construct & Execute**: It immediately constructs the branch name and worktree path, then executes the creation command.
    *   **Branch Name**: `[type]/[description]` (e.g., `fix/resolve-login-issue`)
    *   **Worktree Path**: `.local/[type]-[description]` (e.g., `.local/fix-resolve-login-issue`)
    *   **Execution**: Runs `git worktree add -b <branch_name> <worktree_path> origin/<default_branch>` without delay.

## Example

**User Request:**
> `fix` 타입으로 `login-error` 브랜치 만들어줘.

**Agent Interaction (No Approval):**
> ⏺ Roger that. I will create a new worktree for `fix/login-error`.
>
> ⏺ **Plan**
>   ⎿ ☑ Fetch git repo status & check conventions
>   ⎿ ☑ Create new worktree
>
> ⏺ **Bash** (Running concurrently)
>   ⎿ `git fetch --all`
>   ⎿ `git remote show origin | grep 'HEAD branch'`
>   ⎿ `git branch -r --sort=-committerdate | head -10`
>
> ⏺ Creating worktree with branch `fix/login-error`...
>
> ⏺ **Bash**
>   ⎿ `git worktree add -b fix/login-error .local/fix-login-error origin/main`

This revised workflow is significantly faster, proceeding without interruption while keeping all worktrees neatly organized in the `.local` directory.
