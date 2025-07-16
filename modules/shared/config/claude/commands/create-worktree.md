# Command: create-worktree

## Description
Quickly creates a new git worktree based on the project's default branch (e.g., `main`). It follows a `type/description` branching convention.

## Usage
`@create-worktree [type] <description>`

## Arguments
- `[type]` (Optional): The type of change. Defaults to `feat`. Common types include: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
- `<description>` (Required): A short, descriptive name for the branch (e.g., `add-login-button`).

## Workflow

1.  **Parse Arguments**: Determines the `type` and `description` from your request.
2.  **Fetch Upstream**: Runs `git fetch origin` to get the latest changes.
3.  **Identify Default Branch**: Finds the default branch from `origin` (e.g., `main`).
4.  **Construct Names**:
    -   Branch Name: `[type]/[description]`
    -   Worktree Path: `.local/[type]-[description]`
5.  **Execute**: Creates the new branch and worktree from the latest version of the default branch.

## Example
`@create-worktree feat add-cool-new-feature`

This will:
1.  Create a branch named `feat/add-cool-new-feature`.
2.  Create a worktree in the directory `.local/feat-add-cool-new-feature`.

---
This revised workflow is significantly faster as it eliminates slow analysis steps like reading `CONTRIBUTING.md` and inspecting branch history. It uses a clear, direct command structure for immediate execution, and organizes all worktrees within the `.local` directory.
