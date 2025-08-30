---
name: reflect  
description: "Claude Code instruction optimization through systematic analysis"
---

# /reflect - Claude Code Instruction Optimization

You are an expert in prompt engineering, specializing in optimizing AI code assistant instructions. Your task is to analyze and improve the instructions for Claude Code. Follow these steps carefully:

## Analysis Phase

1. **Context Review**: Analyze recent chat history for patterns in Claude's behavior
2. **Focused Scope**: Only examine instructions/commands directly relevant to identified issues
3. **Issue Categories**:
   - Response inconsistencies or errors
   - Misaligned behavior vs user expectations
   - Missing functionality for common tasks
   - Inefficient command structures
   - MCP permission gaps
   - Command execution failures and syntax errors

**Settings Scope Guidelines:**

- **User Global settings** (~/.claude/ directory): Cross-project personal preferences
  - File paths:
    * `~/.claude/CLAUDE.md`
    * `~/.claude/settings.json`
    * `~/.claude/commands/*.md`
    * `~/.claude/agents/*.md`
  - ✅ Personal workflow preferences and communication style
  - ✅ Language preferences and response formatting
  - ✅ Universal development patterns and tool permissions
  - ❌ Project-specific technical requirements

- **Project settings** (project root): Repository-wide configurations
  - File paths:
    * `./CLAUDE.md`
    * `./.claude/commands/*.md`
    * `./.claude/agents/*.md`
  - ✅ Domain-specific technical instructions (Nix, React, etc.)
  - ✅ Project workflow requirements and architecture patterns
  - ✅ Team coding standards and conventions
  - ✅ Project-specific tool permissions and build commands
  - ❌ Personal communication preferences (belongs in user global)

- **Project Local settings**: Environment-specific overrides
  - File paths:
    * `./.claude/settings.local.json`
  - ✅ Local development environment configurations
  - ✅ Machine-specific tool paths and settings
  - ✅ Temporary experimental configurations
  - ✅ Personal overrides for team project settings
  - ❌ Team-wide configurations (belongs in project)

## Proposal Phase

Present 3-5 prioritized improvement suggestions in this numbered format:

## [1] Priority [High/Medium/Low]: [Issue Title]
- Current problem: [Brief description]
- Proposed solution: [Specific change]  
- Expected benefit: [How it improves performance]

## [2] Priority [High/Medium/Low]: [Issue Title]
- Current problem: [Brief description]
- Proposed solution: [Specific change]
- Expected benefit: [How it improves performance]

**Selection Instructions:**
Ask user to select improvements by number:
- Single: "1" or "3"  
- Multiple: "1,3,5" or "1, 3, 5"
- All: "all" or "1,2,3,4,5"

## Implementation Phase

For approved changes:
1. **Validate scope**: Confirm global changes are universally applicable
2. **Show target file**: Clearly indicate which configuration file will be modified
   - User Global: `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/commands/*.md`, `~/.claude/agents/*.md`
   - Project: `./CLAUDE.md`, `./.claude/commands/*.md`, `./.claude/agents/*.md`
   - Project Local: `./.claude/settings.local.json`
3. **Verify file existence**: Check if target file exists at specified path
4. **Present before/after diff**: Show exact changes with scope justification
5. **Implement immediately**: Apply the change to the specified file
6. **Verify changes**: Confirm changes were applied correctly

**Implementation Rules:**
- **User Global changes**: Must benefit user across all projects and environments
- **Project changes**: Repository-wide, affects all team members and environments
- **Project Local changes**: Environment-specific, personal machine configurations
- **Scope Priority**: Project Local → Project → User Global (least invasive first)
- **When in doubt**: Propose as Project Local change first

Remember, your goal is to enhance Claude's performance and consistency while maintaining the core functionality and purpose of the AI assistant. Be thorough in your analysis, clear in your explanations, and precise in your implementations.
