<objective>
Draft a detailed, step-by-step blueprint for building this project in a test-driven manner.
</objective>

<steps>
First, use the "TodoWrite" tool to register all high-level tasks for the entire planning and implementation process.

Once you have a solid overall plan, break it down into small, iterative chunks that build on each other. For each chunk, your plan should follow the core Test-Driven Development (TDD) cycle. This means structuring the work into a series of prompts for a code-generation LLM that explicitly follows these steps:

1.  **Write a Failing Test (Red):** The first prompt for any new piece of functionality should be to write a test that defines the desired behavior and fails because the implementation doesn't exist yet.
2.  **Make the Test Pass (Green):** The next prompt should be to write the simplest possible code to make the failing test pass.
3.  **Refactor:** Once the test is passing, the following prompt should be to refactor the code for clarity, efficiency, and to remove duplication, all while ensuring the tests continue to pass.

Review the results of this breakdown and make sure that the steps are small enough to be implemented safely, but big enough to move the project forward. Iterate on this planning process until you feel the steps are the right size for this project.

Each prompt should build on the previous ones, creating a clear, incremental path. This ensures there are no big jumps in complexity and that all code is integrated and tested from the moment it's created. Make sure to separate each prompt section using markdown, and tag the prompt text itself using code tags. The goal is to output a complete, test-driven implementation plan as a series of LLM prompts.
</process>

<deliverables>
Store the plan in plan.md. Also create a todo.md to keep state.
</deliverables>

<context>
The spec is in the file called:
</context>
