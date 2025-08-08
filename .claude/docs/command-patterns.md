# Command Patterns Documentation

This document contains common patterns and structures used across Claude Code commands.

## Common Constraints

All commands should include these base constraints:

- The command/entity name must be in `kebab-case`.
- The generated file must be a markdown file with the `.md` extension.
- Always reference an existing similar file to ensure consistency.

## Common Validation Pattern

All commands should include this validation structure:

- A new file is successfully created in the target directory.
- The user is satisfied with the generated template.

## Standard Workflow Structure

Most commands follow this 4-step workflow pattern:

### Step 1: Analyze Existing

- **List Existing Files**: List all existing files in the target directory to understand the project landscape.
- **Identify Patterns**: Analyze existing files to identify common patterns, structures, and conventions.

### Step 2: Gather Information

- **Name**: Ask for the name (in `kebab-case`).
- **Description**: Ask for a brief, one-sentence description.
- **Persona**: Ask for the persona to adopt.
- **Category/Context**: Ask for categorization or contextual information.

### Step 3: Generate File

- **File Name**: Generate filename based on the provided name.
- **File Path**: Determine the appropriate directory path.
- **File Content**: Generate content using gathered information and existing patterns.

### Step 4: Finalize

- **Show User**: Display the path and content of the newly created file.
- **Next Steps**: Provide clear instructions for what the user should do next.

## Directory Paths

Common directory structures used in commands:

- Commands: `modules/shared/config/claude/commands/`
- Agents: `modules/shared/config/claude/agents/`
- Documentation: `.claude/docs/`

## File Template Structure

Most generated files should include:

```markdown
<persona>
[Role and expertise description]
</persona>

<objective>
[Clear, concise objective statement]
</objective>

<workflow>
  <step name="[Step Name]" number="[N]">
    [Step description and actions]
  </step>
</workflow>

<constraints>
[List of constraints and requirements]
</constraints>

<validation>
[Success criteria and validation steps]
</validation>
```
