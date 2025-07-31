# Agent Patterns Documentation

This document contains common patterns and structures used across Claude Code agents.

## Common Constraints

All agents should include these base constraints:

- The agent/entity name must be in `kebab-case`.
- The generated file must be a markdown file with the `.md` extension.
- Always reference an existing similar agent to ensure consistency.

## Common Validation Pattern

All agents should include this validation structure:

- A new agent file is successfully created in the target directory.
- The user is satisfied with the generated agent template.

## Standard Workflow Structure

Most agents follow this 4-step workflow pattern:

### Step 1: Analyze Existing
- **List Existing Agents**: List all existing agents in the target directory to understand the project agent landscape.
- **Identify Patterns**: Analyze existing agents to identify common patterns, structures, and conventions.

### Step 2: Gather Information
- **Agent Name**: Ask for the name (in `kebab-case`).
- **Agent Description**: Ask for a brief, one-sentence description. **IMPORTANT**: Emphasize that this description is critical for Claude Code's automatic delegation system.
- **Proactive Usage**: Ask if this agent should be used proactively by including keywords like "use PROACTIVELY" or "MUST BE USED".
- **Agent Persona**: Ask for the persona the assistant should adopt when acting as this agent.
- **Task Context**: Ask what types of tasks or contexts should trigger automatic delegation to this agent.

### Step 3: Generate Agent File
- **File Name**: Generate filename based on the provided name.
- **File Path**: Determine the appropriate directory path.
- **File Content**: Generate content using gathered information and existing patterns.
- **Delegation Optimization**: Ensure the description field uses action-oriented language and includes specific keywords to improve Claude Code's automatic selection accuracy.

### Step 4: Finalize
- **Show User**: Display the path and content of the newly created agent file.
- **Delegation Testing**: Explain how to test if the agent will be automatically delegated by Claude Code.
- **Next Steps**: Provide clear instructions including delegation testing and refinement.
- **Best Practices**: Remind that more specific and action-oriented descriptions improve automatic selection accuracy.

## Directory Paths

Common directory structures used in agents:

- Agents: `modules/shared/config/claude/agents/`
- Documentation: `.claude/docs/`

## Agent File Template Structure

Most generated agent files should include:

```markdown
---
name: [agent-name]
description: [Action-oriented description optimized for automatic delegation, including PROACTIVE keywords if needed]
---

# [Agent Name] - [한글 간단 설명]

[한 줄 영어 설명]

<persona>
[Domain-specific role and expertise description optimized for the agent's specialty]
</persona>

<objective>
[Clear, concise objective with delegation triggers]
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

**참조**: 자세한 템플릿과 예시는 [agent-template.md](../templates/agent-template.md)를 확인하세요.

## Delegation Optimization Guidelines

### Description Field Best Practices
- Use action-oriented language that clearly indicates when the agent should be used
- Include specific keywords that match common task descriptions
- Add "use PROACTIVELY" or "MUST BE USED" for agents that should be automatically selected
- Be specific about the agent's domain and capabilities

### Task Context Examples
Include examples of task contexts that should trigger automatic delegation:
- Specific types of requests that match the agent's expertise
- Keywords that users might use when requesting this type of work
- Scenarios where the agent provides unique value

### Testing Delegation
- Test the agent's automatic delegation by using task descriptions that match the intended context
- Refine the description field if the agent isn't being selected automatically
- Use specific, action-oriented language in task requests to trigger proper delegation

## Agent Documentation Standards

### YAML Front Matter Format

Agent documentation uses YAML front matter. Each document must start and end with `---`.

```yaml
---
name: [agent-name]
description: [Detailed description of the agent]
---
```

#### Fields

- `name`: A unique, concise, and clear name for the agent, reflecting its core function (e.g., `security-auditor`, `nix-expert`, `frontend-developer`).
- `description`: A detailed explanation of the agent's responsibilities, skills, and areas of expertise.
    - What tasks does it perform?
    - What technology stack is it familiar with (e.g., JWT, OAuth2, Nix, React)?
    - What standards does it adhere to (e.g., OWASP, POSIX)?
    - Clear guidelines on when to use this agent (e.g., `Use PROACTIVELY for...`).

### Documentation Examples

#### Good Example

This example is the gold standard. It clearly defines the agent's role, skills, and use case.

```yaml
---
name: security-auditor
description: Review code for vulnerabilities, implement secure authentication, and ensure OWASP compliance. Handles JWT, OAuth2, CORS, CSP, and encryption. Use PROACTIVELY for security reviews, auth flows, or vulnerability fixes.
---
```

#### Another Good Example

```yaml
---
name: nix-expert
description: Manages Nix and NixOS configurations. Specializes in flake.nix, Nix modules, and home-manager. Responsible for optimizing Nix builds, ensuring reproducibility, and troubleshooting Nix-related issues.
---
```

#### Bad Example

This example is too vague and lacks the necessary detail.

```yaml
---
name: coder
description: Writes code.
---
```

**Why it's bad:**
- **Vague**: It's unclear what kind of code the agent writes (frontend, backend, infrastructure, etc.).
- **Lacks Detail**: No mention of programming languages, frameworks, or libraries.
- **No Context**: It's impossible to know when to call this agent.

### Core Documentation Principles

1. **Be Specific**: Detail the agent's abilities and specialties.
2. **Be Clear**: Use simple, unambiguous language.
3. **Write in English**: Maintain consistency with other project documents.
4. **Keep Up-to-Date**: Update the documentation if the agent's capabilities change.
