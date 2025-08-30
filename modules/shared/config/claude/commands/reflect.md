---
name: reflect  
description: "Claude Code prompt optimization and command improvement specialist"
---

# /reflect - Claude Code Instruction Optimization

You are an expert in prompt engineering, specializing in optimizing AI code assistant instructions. Your task is to analyze and improve the instructions for Claude Code. Follow these steps carefully:

## Analysis Phase

Review the chat history in your context window.

Then, examine the current Claude instructions, commands and config:

<claude_instructions>
# Settings Priority (Highest to Lowest):
1. Project local: .claude/settings.local.json, .claude/CLAUDE.local.md
2. Project shared: /CLAUDE.md, .claude/settings.json, .claude/commands/, .claude/agents/
3. Global user: ~/.claude/CLAUDE.md, ~/.claude/settings.json, ~/.claude/commands/, ~/.claude/agents/

# Configuration Scope:
- **Project local**: Individual developer's environment-specific overrides (git-ignored)
- **Project shared**: Team-wide settings shared via version control  
- **Global user**: Personal settings applied across all projects (must be generic/universal, never project-specific)

# Actual File Locations:
- **Global User**: `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/commands/`, `~/.claude/agents/`
- **Project Shared**: `$PROJECT_ROOT/CLAUDE.md`, `$PROJECT_ROOT/.claude/settings.json`, `$PROJECT_ROOT/.claude/commands/`, `$PROJECT_ROOT/.claude/agents/`
- **Project Local**: `$PROJECT_ROOT/.claude/settings.local.json`, `$PROJECT_ROOT/.claude/CLAUDE.local.md`

# File Modification Guidelines:
- **Commands**: Individual `.md` files in `commands/` directory (e.g., `~/.claude/commands/reflect.md`)
- **Agents**: Individual `.md` files in `agents/` directory (e.g., `~/.claude/agents/backend-engineer.md`)
- **Settings**: JSON format in `settings.json` or `settings.local.json`
- **Instructions**: Markdown format in `CLAUDE.md` or `CLAUDE.local.md`
</claude_instructions>

Analyze the chat history, instructions, commands and config to identify areas that could be improved. Look for:

- Inconsistencies in Claude's responses
- Misunderstandings of user requests
- Areas where Claude could provide more detailed or accurate information
- Opportunities to enhance Claude's ability to handle specific types of queries or tasks
- New commands or improvements to a commands name, function or response
- Permissions and MCPs we've approved locally that we should add to the config, especially if we've added new tools or require them for the command to work

## Interaction Phase

Present your findings and improvement ideas to the human. For each suggestion:

a) Explain the current issue you've identified
b) Propose a specific change or addition to the instructions
c) Describe how this change would improve Claude's performance

**Present numbered proposals:**

### [1] Priority [High/Medium/Low]: [Issue Title]

- **Current Issue**: [What you've identified from analysis]
- **Proposed Change**: [Specific change or addition to instructions]
- **Performance Impact**: [How this improves Claude's performance]
- **Files to Change**: [Specific file paths with full directory structure, e.g., `~/.claude/CLAUDE.md`, `$PROJECT_ROOT/.claude/settings.json`]

### [2] Command: /[command-name]

(Only for commands used in conversation)

- **Current Issue**: [Problems identified from usage]
- **Proposed Change**: [Specific improvements]
- **Performance Impact**: [Expected improvements]
- **Files to Change**: [Full command file path, e.g., `~/.claude/commands/command-name.md`]

### [3] Agent: [agent-name]

(Only for agents used in conversation)

- **Current Issue**: [Performance problems observed]
- **Proposed Change**: [Optimization improvements]
- **Performance Impact**: [Expected improvements]
- **Files to Change**: [Full agent file path, e.g., `~/.claude/agents/agent-name.md`]

Wait for feedback from the human on each suggestion before proceeding. If the human approves a change, move it to the implementation phase. If not, refine your suggestion or move on to the next idea.

**Selection Method**: "1", "1,2,3", or "all"

## Implementation Phase

For each approved change:

a) **Target File Identification**: Specify the exact file path being modified
b) **Section Location**: Clearly state the section or line numbers being modified
c) **Change Content**: Present the new or modified text for that section
d) **Validation**: Explain how to verify the change was applied correctly
e) **Impact Explanation**: Explain how this change addresses the issue identified in the analysis phase

### File Modification Process:
1. **Read** the target file first to understand current state
2. **Edit** the specific sections identified
3. **Verify** changes by reading the modified sections
4. **Test** the command/agent/setting if applicable

## Output Format

Present your final output in the following structure:

[List the issues identified and potential improvements]

[For each approved improvement:
1. Section being modified
2. New or modified instruction text
3. Explanation of how this addresses the identified issue]

```text
<final_instructions>
[Present the complete, updated set of instructions for Claude, incorporating all approved changes]
</final_instructions>
```

Remember, your goal is to enhance Claude's performance and consistency while maintaining the core functionality and purpose of the AI assistant. Be thorough in your analysis, clear in your explanations, and precise in your implementations.
