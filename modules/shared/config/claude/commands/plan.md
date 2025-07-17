<objective>
Draft a detailed, step-by-step blueprint for building this project.
</objective>

<steps>
First, use the "TodoWrite" tool to register all high-level tasks for the entire planning and implementation process.

Once you have a solid overall plan, break it down into small, iterative chunks that build on each other. For each chunk, your plan should provide a clear, step-by-step guide for the implementation. This means structuring the work into a series of prompts for a code-generation LLM that explicitly follows these steps:

1.  **Define the Goal:** Clearly state the objective for the current step.
2.  **Break Down the Task:** Provide a detailed, sequential plan for the LLM to follow.
3.  **Provide Context:** Include any necessary code snippets, file paths, or other context the LLM will need.
4.  **Specify the Output:** Clearly define the expected output, whether it's a new file, a modification to an existing one, or a command to be run.

Review the results of this breakdown and make sure that the steps are small enough to be implemented safely, but big enough to move the project forward. Iterate on this planning process until you feel the steps are the right size for this project.

Each prompt should build on the previous ones, creating a clear, incremental path. This ensures there are no big jumps in complexity and that all code is integrated from the moment it's created. Make sure to separate each prompt section using markdown, and tag the prompt text itself using code tags. The goal is to output a complete implementation plan as a series of LLM prompts.
</process>

<deliverables>
Store the plan in plan.md. Also create a todo.md to keep state.
</deliverables>

<context>
The spec is in the file called:
</context>
