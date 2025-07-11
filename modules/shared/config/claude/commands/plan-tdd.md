# TDD (Test-Driven Development) Workflow Guide

This document outlines the standard procedure for using Test-Driven Development (TDD). Following these principles and phases will help you produce high-quality, well-tested, and maintainable code.

---

### **Core Principles of TDD**

Keep these guiding principles in mind throughout the development cycle. They are the "why" behind the TDD process.

*   **Test Behavior, Not Implementation:** Focus your tests on *what* the code should do, not *how* it does it. This makes your tests more resilient to refactoring.
*   **One Reason to Fail:** Each test should be specific enough that it fails for only one reason. This makes debugging much faster.
*   **The Simplest Thing That Could Possibly Work:** In the "Green" phase, write the absolute minimum amount of code to pass the test. Avoid premature optimization or adding features that haven't been tested for.
*   **You Aren't Gonna Need It (YAGNI):** Do not add functionality until a test requires it.

---

### **Phase 1: Planning & Understanding**

This phase is about preparation. **Do not write any implementation code yet.**

**1.1. Understand the Request**
*   **Goal:** Fully understand the user's objective. Ask clarifying questions if there's any ambiguity.
*   **Constraints:** Identify all constraints and requirements mentioned by the user.
*   **Checkpoint:** Confirm your understanding with the user if there is any ambiguity.

**1.2. Analyze Codebase & Context**
*   **Search:** Use `glob` and `search_file_content` to find relevant files and directories.
*   **Read:** Use `read_file` or `read_many_files` to understand the existing code.
*   **History & Conventions:** Analyze `git log`, related files, and existing patterns to understand the project's history and conventions. Strictly adhere to them.

**1.3. Formulate & Propose TDD Plan**
*   **TDD Cycle Plan:** Create a clear, step-by-step plan focusing on the Red-Green-Refactor cycle. Identify the smallest piece of functionality to implement first.
*   **Edge Cases:** Think about potential side effects and edge cases and plan how to test them.
*   **Propose to User:** Present the plan to the user for approval before making any modifications.
*   **Checkpoint:** Obtain explicit approval from the user before starting implementation.

---

### **Phase 2: TDD Implementation Cycle**

Iterate through the Red-Green-Refactor cycle for each piece of functionality.

| Step | Action | Verification |
| :--- | :--- | :--- |
| **RED** | Write the *smallest possible* test case for a single piece of functionality. | Run tests and confirm the new test **fails** for the expected reason. |
| **GREEN** | Write the *absolute minimum* code required to make the test pass. | Run all tests and confirm they **all pass**. |
| **REFACTOR** | Improve code quality (readability, remove duplication, etc.) without changing its external behavior. | Run all tests again and confirm they **still pass**. |

**Key Refactoring Rules:**
*   **CRITICAL: Dead Code Prohibition**: Actively identify and remove any dead code. Refer to `CLAUDE.md`'s `DEADCODE PROHIBITION` for details.
*   **CRITICAL: File Naming/Creation**: Do NOT rename existing files or create new files with suffixes like `Refactored`, `New`, `_old`, etc. Refactor in place.

**CRITICAL: If a test does not behave as expected:**
1.  **STOP.** Do not proceed with any further implementation.
2.  **INVESTIGATE.** Find the root cause. Do not apply quick fixes or workarounds.
3.  **DEBUGGING PROTOCOL:**
    *   Review the full test output and `git diff` of your recent changes.
    *   Isolate the problem by simplifying the test or code.
    *   Systematically apply the debugging framework in `CLAUDE.md`.
4.  **RESOLVE.** You MUST resolve the underlying issue before continuing the TDD cycle.

---

### **Common Pitfalls to Avoid**

Be mindful of these common traps that can undermine the benefits of TDD.

*   **Writing Tests That Are Too Large:** Tests should be small and focused. If a test is too complex, it's a sign that your implementation step is too large. Break it down.
*   **Skipping the Refactor Step:** The "Refactor" step is not optional. Skipping it leads to technical debt and makes the code harder to work with in the future.
*   **Writing Tests That Don't Fail First:** If a test passes the first time you run it, it's not a valid test. It might be testing something that already works, or the test itself could be flawed.
*   **Forgetting to Run All Tests:** Only running the new test is not enough. You must run the entire test suite to ensure your changes haven't broken existing functionality (regressions).
*   **Testing Implementation Details:** Coupling tests to implementation details makes them brittle. When you refactor the code, the tests will break even if the behavior is still correct.

---

### **Phase 3: Verification & Finalization**

**3.1. Final Verification**
*   **Run All Tests:** Execute the project's entire test suite to ensure no regressions.
    *   **ACTION:** Identify and run the project's test command (e.g., from `package.json`, `Makefile`). Report the outcome.
*   **Linting and Formatting:** Run linters and formatters to ensure code quality.
    *   **ACTION:** Identify and run the project's linting/formatting commands. Report the outcome.
*   **Manual Verification:** If necessary, perform manual checks to confirm the changes work as expected.
*   **Checkpoint:** Confirm that all tests and quality checks pass.

**3.2. Commit Changes**
*   **Review:** Use `git status` and `git diff` to review all modifications.
*   **Stage and Commit:** Use `git add` and `git commit` with a clear, descriptive, and conventional commit message. Commits should reflect complete, logical units of work.
*   **Checkpoint:** Double-check the staged changes (`git diff --staged`) before committing.
