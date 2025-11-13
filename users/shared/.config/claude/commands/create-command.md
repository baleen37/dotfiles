---
description: Create new Claude Code slash commands with systematic workflow and best practices
---

Create a new Claude Code slash command by following this systematic process:

1. **Determine command purpose** - What specific task will this command automate?
2. **Choose appropriate scope** - Project-specific (.claude/commands/) or shared (users/shared/.config/claude/commands/)
3. **Write the command file** - Include clear frontmatter with description
4. **Test the command** - Verify it works with /help and direct execution
5. **Consider arguments** - Add $ARGUMENTS or positional parameters if needed
6. **Add allowed-tools** - Specify required tools if the command needs special permissions

The command should follow the existing patterns in this directory and include:
- YAML frontmatter with description
- Clear, actionable instructions
- Appropriate tool permissions if needed
- Argument hints if the command accepts parameters

Examples of existing commands can be found in the same directory for reference.

**Integration points:**
- **Pairs with:** writing-skills (create the underlying skill first), testing-skills-with-subagents (validate command works)
- **Required background:** Understand slash command structure and workflow automation
