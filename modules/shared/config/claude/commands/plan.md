# Development Plan

This document outlines a standard, structured development workflow. Each phase should be completed in order to ensure quality and consistency.

<rules>
**CRITICAL: WORKFLOW MANDATE**
1.  **SEQUENTIAL EXECUTION:** You **MUST** follow the phases in the exact order presented: 1 → 2 → 3 → 4 → 5.
2.  **PHASE COMPLETION:** You **MUST** complete all actions and checkpoints within a phase before moving to the next.
3.  **USER APPROVAL:** Critical checkpoints, especially the development plan (Phase 3), require explicit user approval before proceeding.
</rules>

---

## Phase 1: Understand the Request
*   **Action:** Clarify the user's goal and identify all constraints. Ask questions if the request is ambiguous.
*   **Checkpoint:** Confirm your understanding with the user. **Proceed only after confirmation.**

## Phase 2: Analyze the Codebase
*   **Action:** Use `glob`, `search_file_content`, and `read_file`/`read_many_files` to thoroughly understand the existing code, its structure, conventions, and history (`git log`).
*   **Checkpoint:** You have a comprehensive understanding of the relevant code and its context.

## Phase 3: Formulate & Propose a Development Plan
*   **Action:** Create a step-by-step implementation plan.
    *   Break down the request into logical, sequential steps.
    *   Identify which files to create or modify.
    *   Define the verification steps for each part of the implementation.
    *   Consider potential risks and edge cases.
*   **Action:** Present the detailed plan to the user.
*   **Checkpoint:** **Obtain explicit user approval for the plan.** Do not proceed without it.

## Phase 4: Implement and Verify
This phase is iterative. For each step outlined in the plan:

### 4.1. IMPLEMENT
*   **Action:** Write or modify the code as described in the current step of the plan.
*   **Checkpoint:** The code for the current step is complete.

### 4.2. VERIFY
*   **Action:** If applicable, write or update tests for the new code.
*   **Action:** Run relevant tests to ensure the changes work as expected and do not break existing functionality.
*   **Action:** Run the project's linter and formatter.
*   **Checkpoint:** The implementation is verified, and all quality checks pass.

### 4.3. ITERATE
*   **Action:** If the plan is not yet complete, return to step 4.1 for the next implementation step. Otherwise, proceed to Phase 5.

## Phase 5: Finalize and Commit
*   **Action:** Review all changes with `git status` and `git diff`.
*   **Action:** Stage all related changes with `git add`.
*   **Action:** Write a clear, conventional commit message summarizing the entire change.
*   **Action:** Commit the changes with `git commit`.
*   **Checkpoint:** The work is successfully committed, and the working directory is clean.
