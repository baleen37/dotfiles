# Code Development Workflow

A systematic development workflow command for solving complex problems through iterative cycles.

## Step 1: Explore (Analysis)

**Objective:** Analyze the codebase and gather all necessary context and requirements for the task.
**Prompt Example:**

> "I am about to work on '\[description of the problem]'.
> Please review the following files and links to understand the overall structure and logic:
>
> - \[filename1.js]
> - \[filename2.py]
> - \[optional documentation or URL]
>   If you have any questions for clarification, feel free to ask directly.
>   **Do not write any code at this stage.** Provide only your analysis."

---

## Step 2: Plan (Design)

**Objective:** Create a detailed plan with small, iterative tasks that can be completed independently.
**Prompt Example:**

> "Great, your analysis is complete. Now, please develop a detailed plan for '\[description of the problem]'.
> Use the **think hard** command to explore different approaches before finalizing the plan.
>
> Break down the work into small, iterative tasks (each completable in 1-4 hours):
> - Each task should deliver working functionality
> - Tasks should be independent when possible
> - Include verification steps after each task
>
> Structure the plan in Markdown:
> 1. Task 1: \[Specific, small task]
>    - Implementation details
>    - Success criteria
> 2. Task 2: \[Next iterative improvement]
>    - Implementation details
>    - Success criteria"

---

## Step 3: Review & Approval

**Objective:** Submit the proposed plan for review and wait for user approval before proceeding.
**Prompt Example:**

> "I've drafted the plan. Please review and let me know if I should proceed as is, or make revisions."
> _User response should be either:_

- "Yes, proceed"
- "No, please adjust \[specific feedback]"

---

## Step 4: Iterative Development

**Objective:** Execute each task through simple cycles of implement → test → commit.
**Prompt Example:**

> "Starting development. First, create the feature branch based on the approved plan.
>
> For each task in the plan:
>
> **1. Implement**
> - Build the working solution for this task
> - Focus on making it work first
>
> **2. Test**  
> - Run tests immediately
> - Fix any issues until tests pass
>
> **3. Commit**
> - Create a focused commit: `type: what was done`
> - Examples: `feat: add user login`, `fix: resolve memory leak`
> - Include docs/comments in the same commit
>
> Repeat for all tasks. Each commit shows progress naturally.
> If blocked or tests keep failing, stop and ask for help."

---

## Step 5: Final Integration Review

**Objective:** Review the complete implementation as a whole after all tasks are done.
**Prompt Example:**

> "All tasks are complete. Let's do a final integration review:
>
> 1. Verify all tasks from the original plan are implemented
> 2. Run the full test suite
> 3. Check that all components work together correctly
> 4. Review the overall code quality and architecture
> 5. Ensure documentation is complete
> 6. **Capture learnings**:
>    - What went well?
>    - What was challenging?
>    - What patterns emerged that could be reused?
>    - Any architectural insights?
>
> Provide a summary of what was accomplished and key learnings."

---

## Step 6: Final Commit & PR

**Objective:** Prepare the final pull request with all changes.
**Prompt Example:**

> "Ready to create the pull request:
>
> 1. Create a summary commit if needed (or use existing atomic commits)
> 2. Push to appropriate branch based on change type:
>    - `feat/[descriptive-name]` - new features
>    - `fix/[descriptive-name]` - bug fixes
>    - `chore/[descriptive-name]` - maintenance tasks
>    - `refactor/[descriptive-name]` - code improvements
>    - Or follow team's existing convention
> 3. Open a Pull Request targeting the default branch
> 4. Write comprehensive PR description summarizing all changes
> 5. Link any related issues or tickets
> 6. Include a 'Lessons Learned' section if applicable"

---

## Error Handling Guidelines

**When things go wrong:**

1. **Implementation Blockers**
   - Stop immediately when truly stuck
   - Clearly describe what you're trying to do
   - Share what you've tried
   - Ask specific questions

2. **Test Failures**
   - First attempt: Analyze and fix
   - Second attempt: Try different approach
   - Third time: Stop and ask for guidance

3. **Plan Deviations**
   - Minor adjustments: Note and continue
   - Major changes: Stop and re-plan with user
   - Always communicate why plans changed

4. **Time Overruns**
   - Alert when task exceeds estimated time
   - Suggest splitting into smaller tasks
   - Update estimates for similar future tasks
