<objective>
This document outlines the standard procedure for addressing user requests, with a focus on Jira integration using the `mcp-atlassian` tool.
</objective>

<process>
  <step name="1. Understand the Request">
    - *Clarify the Goal:* Fully understand what the user wants to achieve. If the request is ambiguous, ask clarifying questions.
    - *Identify Constraints:* Note any specific constraints or requirements mentioned by the user.
  </step>

  <step name="2. Analyze the Codebase">
    - *File & Directory Search:* Use `glob` to find relevant files and directories.
    - *Content Search:* Use `search_file_content` to locate specific code snippets, functions, or variables.
    - *Read and Understand:* Use `read_file` or `read_many_files` to thoroughly understand the existing code, its structure, and conventions.
  </step>

  <step name="3. Formulate a Plan">
    - *Outline the Steps:* Create a clear, step-by-step plan for implementing the required changes.
    - *Consider Edge Cases:* Think about potential side effects and edge cases.
    - *Plan for Verification:* Decide how you will test the changes (e.g., running existing tests, creating new tests).
    - *Propose to User:* Present the plan to the user for approval before making any modifications.
  </step>

  <step name="4. Implement Changes">
    - *Modify Files:* Use `write_file` or `replace` to make the necessary code changes. Adhere strictly to the project's coding style and conventions.
    - *Create New Files:* Use `write_file` if new files are needed.
  </step>

  <step name="5. Verify and Test">
    - *Run Tests:* Execute the project's test suite using the appropriate command (e.g., `npm run test`, `pytest`).
    - *Linting and Formatting:* Run linters and formatters to ensure code quality and consistency.
    - *Manual Verification:* If necessary, perform manual checks to confirm the changes work as expected.
  </step>

  <step name="6. Commit and Finalize (Jira)">
    - *Review Changes:* Use `git status` and `git diff` to review the modifications.
    - *Stage and Commit:* Use `git add` and `git commit`. Ensure the commit message includes the Jira issue key (e.g., `PROJ-123: Fix login bug`).
    - *Update Jira Ticket:* After pushing the changes, use the `mcp-atlassian` tool to interact with Jira:
      - `jira_transition_issue`: Update the status of the Jira ticket (e.g., to "In Review").
      - `jira_add_comment`: Add a comment to the ticket with a summary of the changes.
      - `jira_log_work`: Log the time spent on the task if required.
  </step>
</process>
