# Development Plan (GitHub Integration)

This document outlines the standard procedure for addressing user requests, with a focus on GitHub integration.

## 1. Understand the Request

*   **Clarify the Goal:** Fully understand what the user wants to achieve. If the request is ambiguous, ask clarifying questions.
*   **Identify Constraints:** Note any specific constraints or requirements mentioned by the user.

## 2. Analyze the Codebase

*   **File & Directory Search:** Use `glob` to find relevant files and directories.
*   **Content Search:** Use `search_file_content` to locate specific code snippets, functions, or variables.
*   **Read and Understand:** Use `read_file` or `read_many_files` to thoroughly understand the existing code, its structure, and conventions.

## 3. Formulate a Plan

*   **Outline the Steps:** Create a clear, step-by-step plan for implementing the required changes.
*   **Consider Edge Cases:** Think about potential side effects and edge cases.
*   **Plan for Verification:** Decide how you will test the changes (e.g., running existing tests, creating new tests).
*   **Propose to User:** Present the plan to the user for approval before making any modifications.

## 4. Implement Changes

*   **Modify Files:** Use `write_file` or `replace` to make the necessary code changes. Adhere strictly to the project's coding style and conventions.
*   **Create New Files:** Use `write_file` if new files are needed.

## 5. Verify and Test

*   **Run Tests:** Execute the project's test suite using the appropriate command (e.g., `npm run test`, `pytest`).
*   **Linting and Formatting:** Run linters and formatters to ensure code quality and consistency.
*   **Manual Verification:** If necessary, perform manual checks to confirm the changes work as expected.

## 6. Commit and Finalize (GitHub)

*   **Review Changes:** Use `git status` and `git diff` to review the modifications.
*   **Stage and Commit:** Use `git add` and `git commit` with a clear and descriptive commit message that follows the project's conventions.
*   **Branching (Optional):** If working on a new feature, create a new branch with a descriptive name.
*   **Push to GitHub:** Use `git push` to upload the changes to the remote repository.
*   **Create Pull Request:** If applicable, create a pull request on GitHub, linking it to the relevant issue.