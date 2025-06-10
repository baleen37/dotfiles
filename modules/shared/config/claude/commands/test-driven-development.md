# Workflow 2: Test-Driven Development (TDD)

> This workflow emphasizes writing tests first to define clear success criteria, then implementing code to satisfy those tests.

## Step 1: Write Tests

**Objective:** Create test cases that define expected behavior before any implementation.

**Prompt Example:**
```text
"Starting '[new feature or change]' using Test-Driven Development.
First, write the tests based on:
- **Expected Input:** [example input]
- **Expected Output:** [example output]
**Do not write any implementation code.** Provide only the test code, even if it references non-existent functions."
```

## Step 2: Confirm Failure & Commit Tests

**Objective:** Run the tests, confirm they fail (since implementation is missing), then commit the test code.

**Prompt Example:**
```text
"Run the tests and confirm they fail as expected. Once confirmed, commit only the test code with message: 'Test: Add tests for [feature name]'."
```

## Step 3: Write Code & Iterate to Pass

**Objective:** Implement only the code needed to make the tests pass. Repeat the cycle of modifying code and running tests until all pass.

**Prompt Example:**
```text
"Now, write the minimal implementation to make all tests pass.
- Do not modify the test code under any circumstances.
- After writing code, run tests. If any fail, adjust the implementation and rerun until success."
```

## Step 4: Commit Final Code

**Objective:** After all tests pass, commit the implementation code.

**Prompt Example:**
```text
"All tests are passing. Commit the implementation with message: 'Feat: Implement [feature name]'."
```