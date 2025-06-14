# Planning & Design Workflow

A systematic approach to planning and designing solutions for complex problems.

## Step 1: Explore (Analysis)

**Objective:** Analyze the codebase and gather all necessary context and requirements for the task.

**Prompt Example:**

> "I am about to work on '\[description of the problem]'.
> Please review the following files and links to understand the overall structure and logic:
>
> * \[filename1.js]
> * \[filename2.py]
> * \[optional documentation or URL]
>   If you have any questions for clarification, feel free to ask directly.
>   **Do not write any code at this stage.** Provide only your analysis."

---

## Step 2: Plan (Design)

**Objective:** Create a detailed, step-by-step plan based on the analysis.

**Prompt Example:**

> "Great, your analysis is complete. Now, please develop a detailed plan for '\[description of the problem]'.
> Use the **think hard** command to explore different approaches before finalizing the plan.
> Structure the plan in Markdown with numbered steps, for example:
>
> 1. Step 1: \[Task description]
> 2. Step 2: \[Task description]
> 3. Step 3: \[Task description]"

---

## Step 3: Review & Approval

**Objective:** Submit the proposed plan for review and wait for user approval before proceeding.

**Prompt Example:**

> "I've drafted the plan. Please review and let me know if I should proceed as is, or make revisions."

*User response should be either:*

* "Yes, proceed"
* "No, please adjust \[specific feedback]"