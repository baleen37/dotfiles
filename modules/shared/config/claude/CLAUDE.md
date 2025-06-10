## Workflow 1: Explore → Plan → Review & Approval → Code → Commit

> This workflow is designed for complex problem-solving, ensuring the AI analyzes and plans thoroughly before writing any code.

### Step 1: Explore (Analysis)

* **Objective:** Analyze the codebase and gather all necessary context and requirements for the task.
* **Prompt Example:**

  ```text
  "I am about to work on '[description of the problem]'.
  Please review the following files and links to understand the overall structure and logic:
  - [filename1.js]
  - [filename2.py]
  - [optional documentation or URL]
  If you have any questions for clarification, feel free to use sub-agents or ask me directly.
  **Do not write any code at this stage.** Provide only your analysis."
  ```

### Step 2: Plan (Design)

* **Objective:** Create a detailed, step-by-step plan based on the analysis.
* **Prompt Example:**

  ```text
  "Great, your analysis is complete. Now, please develop a detailed plan for '[description of the problem]'.
  Use the **think hard** command to explore different approaches before finalizing the plan.
  Structure the plan in Markdown with numbered steps, for example:
  1. Step 1: [Task description]
  2. Step 2: [Task description]
  3. Step 3: [Task description]
  ```

### Step 3: Review & Approval

* **Objective:** Submit the proposed plan for review and wait for user approval before proceeding.
* **Prompt Example:**

  ```text
  "I've drafted the plan. Please review and let me know if I should proceed or make revisions."
  ```

  * The user should respond with either “Yes, proceed” or “No, please adjust \[specific feedback]”.

### Step 4: Implement Code (Coding)

* **Objective:** Write the actual code according to the approved plan.
* **Prompt Example:**

  ```text
  "The plan has been approved. Now, implement the code following the plan exactly. Keep verifying each part against the plan and ensure it's a sound solution."
  ```

### Step 5: Commit & Document

* **Objective:** Commit the completed code and update documentation to finalize the task.
* **Prompt Example:**

  ```text
  "The code is complete. Please:
  1. Commit with message: '[Feat: Brief description]'.
  2. Push to the feature branch: '[feat/branch-name]'.
  3. Open a Pull Request targeting 'main'.
  4. Update README.md and CHANGELOG.md with a summary of the changes."
  ```

---

## Workflow 2: Test-Driven Development (TDD)

> This workflow emphasizes writing tests first to define clear success criteria, then implementing code to satisfy those tests.

### Step 1: Write Tests

* **Objective:** Create test cases that define expected behavior before any implementation.
* **Prompt Example:**

  ```text
  "Starting '[new feature or change]' using Test-Driven Development.
  First, write the tests based on:
  - **Expected Input:** [example input]
  - **Expected Output:** [example output]
  **Do not write any implementation code.** Provide only the test code, even if it references non-existent functions."
  ```

### Step 2: Confirm Failure & Commit Tests

* **Objective:** Run the tests, confirm they fail (since implementation is missing), then commit the test code.
* **Prompt Example:**

  ```text
  "Run the tests and confirm they fail as expected. Once confirmed, commit only the test code with message: 'Test: Add tests for [feature name]'."
  ```

### Step 3: Write Code & Iterate to Pass

* **Objective:** Implement only the code needed to make the tests pass. Repeat the cycle of modifying code and running tests until all pass.
* **Prompt Example:**

  ```text
  "Now, write the minimal implementation to make all tests pass.
  - Do not modify the test code under any circumstances.
  - After writing code, run tests. If any fail, adjust the implementation and rerun until success."
  ```

### Step 4: Commit Final Code

* **Objective:** After all tests pass, commit the implementation code.
* **Prompt Example:**

  ```text
  "All tests are passing. Commit the implementation with message: 'Feat: Implement [feature name]'."
  ```
