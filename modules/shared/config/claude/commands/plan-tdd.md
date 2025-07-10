# TDD Workflow & Development Protocol

This document outlines the standard procedure for addressing user requests using a Test-Driven Development (TDD) approach. This protocol is a specific implementation of the **Test-Plan-Verify (TPV) Development Cycle** described in `CLAUDE.md`.

## Core Principles (Guiding the Entire Process)

Before starting any task, internalize these principles from `CLAUDE.md`. They are not steps, but a mindset to maintain throughout the workflow.

*   **Context Preservation:** Your primary duty is to understand and maintain the project's existing conventions, architecture, and history. Never introduce changes that deviate from established patterns without a compelling, documented reason.
*   **Think Hard Mandate:** For complex problems, especially test failures or system-level issues, you must stop and engage in deep analysis. Do not guess or apply superficial fixes. Understand the root cause before proceeding.
*   **Convention Adherence:** Strictly follow existing file structures, naming conventions, and coding styles.

## Phase 1: Understand & Analyze

*   **1.1. Clarify the Goal:** Fully understand what the user wants to achieve. If the request is ambiguous, ask clarifying questions. Note any specific constraints or requirements.
*   **1.2. Analyze the Codebase (Context Discovery Protocol):**
    *   **File & Directory Search:** Use `glob` to find relevant files and directories.
    *   **Content Search:** Use `search_file_content` to locate specific code snippets, functions, or variables.
    *   **Read and Understand:** Use `read_file` or `read_many_files` to thoroughly understand the existing code.
    *   **Analyze History:** Review `git log` and related file histories to understand the evolution of the code and its conventions.
*   **Checkpoint:** Do you have a comprehensive understanding of the request, the relevant code, its history, and its conventions? If there is any ambiguity, confirm with the user.

## Phase 2: Plan

*   **2.1. Formulate a TDD Strategy:**
    *   **Outline the Steps (TDD Cycle):** Create a clear, step-by-step plan that follows the Red-Green-Refactor cycle. Identify the smallest possible piece of functionality to implement first.
    *   **Plan for Tests:** Determine how to test this functionality *before* writing the implementation code. Consider edge cases and potential side effects.
*   **2.2. Propose to User:** Present the high-level plan to the user for approval before making any modifications.
*   **Checkpoint:** Has the user explicitly approved the plan?

## Phase 3: Implement (The Red-Green-Refactor Cycle)

This phase involves iterative cycles of writing a failing test, making it pass, and then refactoring.

### 3.1. Red: Write a Failing Test
*   **Write Test:** Create the *smallest possible* new test case that targets the *single, smallest piece of functionality* you're implementing.
*   **Ensure Failure:** Run the tests and confirm that the new test fails for the expected reason. This proves the test is working correctly and the functionality doesn't exist yet.
*   **Checkpoint:** Did the new test fail as expected?

### 3.2. Green: Write Just Enough Code to Pass
*   **Implement Minimal Solution:** Write *only* the code necessary to make the failing test pass. Do not add any extra functionality.
*   **Run Tests:** Run the entire test suite and ensure all tests pass.
*   **Checkpoint:** Do all tests now pass?

### 3.3. Refactor: Improve Code Quality
*   **Refactor Code:** Improve the design, readability, and maintainability of the implementation without changing its external behavior. Remove duplication, simplify logic, and adhere to project conventions.
    *   **CRITICAL: Dead Code Prohibition**: Actively identify and remove any dead code.
    *   **CRITICAL: No Temporary Files**: Refactor in place. Do NOT rename files or create new files with suffixes like `_new`, `_v2`, or `_backup`.
*   **Run Tests:** Run all tests again to ensure refactoring has not introduced any regressions.
*   **Checkpoint:** Do all tests still pass after refactoring?

### 3.4. Critical Protocol: Handling Test Deviations
*   **CRITICAL: If a test does not behave as expected at any point (e.g., doesn't fail in Red, doesn't pass in Green, or fails after Refactor):**
    *   **STOP IMMEDIATELY.** Do not proceed.
    *   **Think Hard & Find the Root Cause**: This is a critical failure. Your primary goal is to understand *why* the test is not behaving as expected.
    *   **Debugging Protocol**:
        1.  **Review Test Output**: Carefully examine the full test output, including stack traces and error messages.
        2.  **Inspect Recent Changes**: Use `git diff` to review your most recent code changes.
        3.  **Isolate the Problem**: Simplify the test case or the code to pinpoint the source of the issue.
        4.  **Consult `CLAUDE.md`**: Systematically apply the debugging frameworks outlined in `CLAUDE.md`.
    *   **Resolution**: You MUST resolve the underlying issue before moving to the next step.

### 3.5. Document Progress
*   **ACTION: Update `plan.md`**: After each successful Red-Green-Refactor cycle, update `plan.md` to mark the completed functionality and reflect the current progress. This ensures the plan is always up-to-date.

### 3.6. Iterate
*   Repeat steps 3.1 to 3.5 for the next smallest piece of functionality until the entire feature is implemented.

## Phase 4: Verify

*   **4.1. Run All Project Checks:**
    *   **ACTION: Run Test Suite:** Identify and execute the project's entire test suite (e.g., `npm test`, `pytest`).
    *   **ACTION: Run Linters/Formatters:** Identify and execute project quality tools (e.g., `npm run lint`, `ruff check .`).
*   **4.2. Manual Verification:** If necessary, perform a final manual check to confirm the changes work as expected from a user's perspective.
*   **Checkpoint:** Does the entire test suite pass, and are all code quality checks met?

## Phase 5: Finalize

*   **5.1. Review Changes:** Use `git status` and `git diff --staged` to review all modifications one last time. Ensure no temporary or debug code is included.
*   **5.2. Craft Commit Message:** Write a clear and descriptive commit message that follows the project's conventions (review `git log` for examples). The message should explain the "why" behind the change.
*   **5.3. Commit:** Use `git add` and `git commit` to finalize the task. Commits should ideally represent complete, self-contained Red-Green-Refactor cycles.
*   **Checkpoint:** Is the commit message clear and conventional? Are the staged changes correct?
