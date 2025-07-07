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

*   **Write Test:** Create a new test case that specifically targets the smallest piece of functionality identified in the plan.
*   **Ensure Failure:** Run the tests and confirm that the newly added test fails. This confirms the test is correctly written and the functionality does not yet exist.
*   **Checkpoint:** Confirm the new test fails for the expected reason.

### 4.2. Green: Write Just Enough Code to Pass

*   **Implement Minimal Solution:** Write *only* the necessary code to make the failing test pass. Do not add extra functionality.
*   **Run Tests:** Run all tests (including the new one) and ensure they all pass.
*   **Checkpoint:** Confirm all tests pass after the minimal implementation.

### 4.3. Refactor: Improve Code Quality

*   **Refactor Code:** Improve the design, readability, and maintainability of the code without changing its external behavior. This includes removing duplication, simplifying logic, and adhering to coding standards.
*   **Run Tests:** Run all tests again to ensure that refactoring has not introduced any regressions.
*   **Checkpoint:** Confirm all tests still pass after refactoring.

### 4.4. Iterate

*   Repeat steps 4.1 to 4.3 for the next smallest piece of functionality until the entire feature is implemented.

## 5. Verify and Test (Continuous Integration)

*   **Run All Tests:** Execute the project's entire test suite to ensure no regressions have been introduced throughout the TDD cycles.
*   **Linting and Formatting:** Run linters and formatters to ensure code quality and consistency.
*   **Manual Verification:** If necessary, perform manual checks to confirm the changes work as expected.
*   **Checkpoint:** Confirm that the entire test suite passes and all code quality checks are met.

## 6. Commit and Finalize

*   **Review Changes:** Use `git status` and `git diff` to review the modifications.
*   **Stage and Commit:** Use `git add` and `git commit` with a clear and descriptive commit message that follows the project's conventions. Commits should ideally reflect completed Red-Green-Refactor cycles.
*   **Checkpoint:** Double-check the commit message and the staged changes (`git diff --staged`) before committing.

## Project Context & History Preservation

*   **Analyze History:** Before making changes, review `git log` and related file histories to understand the evolution of the code.
*   **Maintain Conventions:** Strictly adhere to existing naming conventions, architectural patterns, and coding styles.
*   **Document Rationale:** If significant changes are made, be prepared to explain the reasoning behind them, referencing the project's history and goals.
