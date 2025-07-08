# Development Plan (Test-Driven Development)

This document outlines the standard procedure for addressing user requests using a Test-Driven Development (TDD) approach.

## 1. Understand the Request

*   **Clarify the Goal:** Fully understand what the user wants to achieve. If the request is ambiguous, ask clarifying questions.
*   **Identify Constraints:** Note any specific constraints or requirements mentioned by the user.
*   **Checkpoint:** Confirm understanding with Jito if there is any ambiguity.

## 2. Analyze the Codebase

*   **File & Directory Search:** Use `glob` to find relevant files and directories.
*   **Content Search:** Use `search_file_content` to locate specific code snippets, functions, or variables.
*   **Read and Understand:** Use `read_file` or `read_many_files` to thoroughly understand the existing code, its structure, and conventions.
*   **Context Discovery:** Analyze `git log`, related files, and existing patterns to understand the project's history and conventions.
*   **Checkpoint:** Ensure a comprehensive understanding of the relevant code, its history, and conventions before proceeding.

## 3. Formulate a TDD Plan

*   **Outline the Steps (TDD Cycle):** Create a clear, step-by-step plan for implementing the required changes, focusing on the Red-Green-Refactor cycle.
    *   Identify the smallest piece of functionality to implement.
    *   Determine how to test this functionality *before* writing the code.
*   **Consider Edge Cases:** Think about potential side effects and edge cases, and how they will be covered by tests.
*   **Plan for Verification:** Decide how you will test the changes (i.g., running existing tests, creating new tests).
*   **Propose to User:** Present the plan to the user for approval before making any modifications.
*   **Checkpoint:** Obtain explicit approval from Jito before starting implementation.

## 4. Implement Changes (TDD Cycle: Red-Green-Refactor)

This phase involves iterative cycles of writing a failing test, making it pass, and then refactoring.

### 4.1. Red: Write a Failing Test

*   **Write Test:** Create the *smallest possible* new test case that specifically targets the *single, smallest piece of functionality* identified in the plan.
*   **Ensure Failure:** Run the tests and confirm that the newly added test fails. This confirms the test is correctly written and the functionality does not yet exist.
*   **Checkpoint:** Confirm the new test fails for the expected reason.

### 4.2. Green: Write Just Enough Code to Pass

*   **Implement Minimal Solution:** Write *only* the absolutely necessary code to make the failing test pass. Do not add *any* extra functionality, even if you anticipate needing it later.
*   **Run Tests:** Run all tests (including the new one) and ensure they all pass.
*   **Checkpoint:** Confirm all tests pass after the minimal implementation.

### 4.3. Refactor: Improve Code Quality

*   **Refactor Code:** Improve the design, readability, and maintainability of the code without changing its external behavior. This includes removing duplication, simplifying logic, and adhering to coding standards.
    *   **CRITICAL: Dead Code Prohibition**: Actively identify and remove any dead code introduced during the Green phase or existing in the refactored area. Refer to `CLAUDE.md`'s `DEADCODE PROHIBITION` for details.
    *   **CRITICAL: File Naming/Creation**: Do NOT rename existing files or create new files with suffixes like `Refactored`, `New`, `V2`, `_old`, `_backup`, etc. Refactor in place.
*   **Run Tests:** Run all tests again to ensure that refactoring has not introduced any regressions.
*   **Checkpoint:** Confirm all tests still pass after refactoring and no dead code or improperly named files remain.

### 4.4. Handling Test Failures (During Red-Green-Refactor)
*   **CRITICAL: If a test does not behave as expected (e.g., does not fail in Red, does not pass in Green, or fails after Refactoring):**
    *   **STOP IMMEDIATELY.** Do NOT proceed with any further implementation or refactoring.
    *   **Think Hard & Find the Root Cause**: This is a critical juncture. Do not apply quick fixes or workarounds. Your primary goal is to understand *why* the test is failing or not behaving as expected.
    *   **Debugging Protocol**:
        1.  **Review Test Output**: Carefully examine the full test output, including stack traces and error messages.
        2.  **Inspect Recent Changes**: Use `git diff` to review your most recent code changes.
        3.  **Isolate the Problem**: If possible, simplify the test case or the code under test to pinpoint the exact source of the issue.
        4.  **Consult CLAUDE.md Debugging Process**: Systematically apply the debugging framework outlined in the `<debugging_process>` section of `CLAUDE.md`. This includes reproducing consistently, checking recent changes, asking "WHY" repeatedly, and forming/testing hypotheses.
    *   **Resolution**: You MUST resolve the underlying issue and ensure the test behaves correctly (failing in Red, passing in Green/Refactor) before attempting to move to the next step in the TDD cycle.

### 4.5. Iterate

*   Repeat steps 4.1 to 4.3 for the next smallest piece of functionality until the entire feature is implemented.

## 5. Verify and Test (Continuous Integration)

*   **Run All Tests:** Execute the project's entire test suite to ensure no regressions have been introduced throughout the TDD cycles.
    *   **ACTION:** Identify the project's test command by checking `package.json` scripts, `Makefile`, `README.md`, or common test runners (e.g., `npm test`, `pytest`, `go test ./...`). Run it and report the outcome.
*   **Linting and Formatting:** Run linters and formatters to ensure code quality and consistency.
    *   **ACTION:** Identify the project's linting and formatting commands by checking `package.json` scripts, `Makefile`, `README.md`, or common linters (e.g., `npm run lint`, `black .`, `ruff check .`). Run them and report the outcome.
*   **Manual Verification:** If necessary, perform manual checks to confirm the changes work as expected.
*   **Checkpoint:** Confirm that the entire test suite passes and all code quality checks are met.

## 6. Commit and Finalize

## 7. Final Task Completion Check

*   **Review Changes:** Use `git status` and `git diff` to review the modifications.
*   **Stage and Commit:** Use `git add` and `git commit` with a clear and descriptive commit message that follows the project's conventions. Commits should ideally reflect completed Red-Green-Refactor cycles.
*   **Checkpoint:** Double-check the commit message and the staged changes (`git diff --staged`) before committing.

## Project Context & History Preservation

*   **Analyze History:** Before making changes, review `git log` and related file histories to understand the evolution of the code.
*   **Maintain Conventions:** Strictly adhere to existing naming conventions, architectural patterns, and coding styles.
*   **Document Rationale:** If significant changes are made, be prepared to explain the reasoning behind them, referencing the project's history and goals.
