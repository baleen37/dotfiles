# Collaboration Skills

Working effectively with other agents and developers.

## Available Skills

- skills/collaboration/brainstorming - Interactive idea refinement using Socratic method to develop fully-formed designs. Use when your human partner has new idea to explore. Before writing implementation plans.

- skills/collaboration/writing-plans - Create detailed implementation plans with bite-sized tasks for engineers with zero codebase context. Use after brainstorming/design is complete. Before implementation begins.

- skills/collaboration/using-git-worktrees - Create isolated git worktrees with smart directory selection and safety verification. Use when starting feature implementation in isolation. When brainstorming transitions to code. Before executing plans.

- skills/collaboration/executing-plans - Execute detailed plans in batches with review checkpoints. Use when have complete implementation plan to execute. When implementing in separate session from planning.

- skills/collaboration/subagent-driven-development - Execute plan by dispatching fresh subagent per task with code review between tasks. Alternative to executing-plans when staying in same session. Use when tasks are independent. When want fast iteration with review checkpoints.

- skills/collaboration/finishing-a-development-branch - Complete feature development with structured options for merge, PR, or cleanup. Use after completing implementation. When all tests passing. At end of executing-plans or subagent-driven-development.

- skills/collaboration/remembering-conversations - Search previous Claude Code conversations for facts, patterns, decisions, and context using semantic or text search. Use when your human partner mentions "we discussed this before". When debugging similar issues. When looking for architectural decisions or code patterns from past work. Before reinventing solutions. When searching for git SHAs or error messages.

- skills/collaboration/dispatching-parallel-agents - Use multiple Claude agents to investigate and fix independent problems concurrently. Use when you have 3+ unrelated failures that can be debugged in parallel.

- skills/collaboration/requesting-code-review - Dispatch code-reviewer subagent to review implementation against plan before proceeding. Use after completing task. After major feature. Before merging. When executing plans (after each task).

- skills/collaboration/receiving-code-review - Receive and act on code review feedback with technical rigor, not performative agreement or blind implementation. Use when receiving feedback from your human partner or external reviewers. Before implementing review suggestions. When feedback seems wrong or unclear.
