# Development Plan (Test-Driven Development)

This document outlines the standard procedure for addressing user requests using a Test-Driven Development (TDD) approach.

## 1. Understand the Request

*   **Clarify the Goal:** Fully understand what the user wants to achieve. If the request is ambiguous, ask clarifying questions.
*   **Identify Constraints:** Note any specific constraints or requirements mentioned by the user.

## 2. Analyze the Codebase

*   **File & Directory Search:** Use `glob` to find relevant files and directories.
*   **Content Search:** Use `search_file_content` to locate specific code snippets, functions, or variables.
*   **Read and Understand:** Use `read_file` or `read_many_files` to thoroughly understand the existing code, its structure, and conventions.

## 3. Formulate a TDD Plan

*   **Outline the Steps (TDD Cycle):** Create a clear, step-by-step plan for implementing the required changes, focusing on the Red-Green-Refactor cycle.
    *   Identify the smallest piece of functionality to implement.
    *   Determine how to test this functionality *before* writing the code.
*   **Consider Edge Cases:** Think about potential side effects and edge cases, and how they will be covered by tests.
*   **Plan for Verification:** Decide how you will test the changes (i.g., running existing tests, creating new tests).
*   **Propose to User:** Present the plan to the user for approval before making any modifications.

## 4. Implement Changes (TDD Cycle: Red-Green-Refactor)

This phase involves iterative cycles of writing a failing test, making it pass, and then refactoring.

### 4.1. Red: Write a Failing Test

*   **Write Test:** Create a new test case that specifically targets the smallest piece of functionality identified in the plan.
*   **Ensure Failure:** Run the tests and confirm that the newly added test fails. This confirms the test is correctly written and the functionality does not yet exist.

### 4.2. Green: Write Just Enough Code to Pass

*   **Implement Minimal Solution:** Write *only* the necessary code to make the failing test pass. Do not add extra functionality.
*   **Run Tests:** Run all tests (including the new one) and ensure they all pass.

### 4.3. Refactor: Improve Code Quality

*   **Refactor Code:** Improve the design, readability, and maintainability of the code without changing its external behavior. This includes removing duplication, simplifying logic, and adhering to coding standards.
*   **Run Tests:** Run all tests again to ensure that refactoring has not introduced any regressions.

### 4.4. Iterate

*   Repeat steps 4.1 to 4.3 for the next smallest piece of functionality until the entire feature is implemented.

## 5. Verify and Test (Continuous Integration)

*   **Run All Tests:** Execute the project's entire test suite to ensure no regressions have been introduced throughout the TDD cycles.
*   **Linting and Formatting:** Run linters and formatters to ensure code quality and consistency.
*   **Manual Verification:** If necessary, perform manual checks to confirm the changes work as expected.

## 6. Commit and Finalize

*   **Review Changes:** Use `git status` and `git diff` to review the modifications.
*   **Stage and Commit:** Use `git add` and `git commit` with a clear and descriptive commit message that follows the project's conventions. Commits should ideally reflect completed Red-Green-Refactor cycles.