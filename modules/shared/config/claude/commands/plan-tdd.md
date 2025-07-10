# Development Plan (Strict Test-Driven Development)

This document mandates a **strict, sequential, and non-skippable** Test-Driven Development (TDD) workflow. Each phase must be completed in order.

<rules>
**CRITICAL: WORKFLOW MANDATE**
1.  **SEQUENTIAL EXECUTION:** You **MUST** follow the phases in the exact order presented: 1 → 2 → 3 → 4 → 5 → 6. **DO NOT SKIP PHASES.**
2.  **PHASE COMPLETION:** You **MUST** complete all actions and checkpoints within a phase before moving to the next.
3.  **NO SHORTCUTS:** Do not combine phases. For example, do not write implementation code (Phase 4.2) before a failing test (Phase 4.1) exists and has been verified.
4.  **USER APPROVAL:** Critical checkpoints, especially the TDD plan (Phase 3), require explicit user approval before proceeding.
</rules>

---

## Phase 1: Understand the Request
*   **Action:** Clarify the user's goal and identify all constraints. Ask questions if the request is ambiguous.
*   **Checkpoint:** Confirm your understanding with the user. **Proceed only after confirmation.**

## Phase 2: Analyze the Codebase
*   **Action:** Use `glob`, `search_file_content`, and `read_file`/`read_many_files` to thoroughly understand the existing code, its structure, conventions, and history (`git log`).
*   **Checkpoint:** You have a comprehensive understanding of the relevant code and its context.

## Phase 3: Formulate & Propose a TDD Plan
*   **Action:** Create a step-by-step plan for the Red-Green-Refactor cycle.
    *   Identify the smallest functional unit to implement.
    *   Define the failing test for that unit.
    *   Consider edge cases.
    *   Plan for final verification (e.g., running the full test suite).
*   **Action:** Present the detailed plan to the user.
*   **Checkpoint:** **Obtain explicit user approval for the plan.** Do not proceed without it.

## Phase 4: Execute the TDD Cycle (Red-Green-Refactor)
This phase is iterative. For each small piece of functionality, you must follow this exact sub-sequence:

### 4.1. RED: Write a Failing Test
*   **Action:** Write the smallest possible test case for the next piece of functionality.
*   **Action:** Run the test suite.
*   **Checkpoint:** **Confirm that the new test fails as expected.** This is a mandatory check. If it passes, you have made a mistake; stop and re-evaluate.

### 4.2. GREEN: Write Minimal Code to Pass
*   **Action:** Write *only* the code required to make the new test pass. No more, no less.
*   **Action:** Run the entire test suite.
*   **Checkpoint:** **Confirm that all tests now pass.**

### 4.3. REFACTOR: Improve Code Quality
*   **Action:** Refactor the code you just wrote to improve its design, readability, and maintainability without changing its behavior.
    *   **CRITICAL:** Remove any dead code.
    *   **CRITICAL:** Do not create temporary files (`_new`, `_refactored`). Refactor in place.
*   **Action:** Run the entire test suite again.
*   **Checkpoint:** **Confirm that all tests still pass.**

### 4.4. ITERATE
*   **Action:** If the feature is not yet complete, return to step 4.1 for the next piece of functionality. Otherwise, proceed to Phase 5.

## Phase 5: Final Verification
*   **Action:** Execute the project's **entire** test suite one last time. Identify the command from `package.json`, `Makefile`, etc., and run it.
*   **Action:** Run the project's linter and formatter.
*   **Checkpoint:** Confirm all tests pass and the code adheres to all quality standards.

## Phase 6: Commit and Finalize
*   **Action:** Review all changes with `git status` and `git diff`.
*   **Action:** Stage the changes with `git add`.
*   **Action:** Write a clear, conventional commit message and commit the changes with `git commit`.
*   **Checkpoint:** The work is successfully committed, and the working directory is clean.
