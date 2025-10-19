---
name: create-claude-skill
description: "Generate new Claude skills following best practices and established patterns"
---

Create new Claude skills with proper structure, validation, and integration following official best practices.

**Usage**: `/create-claude-skill [skill-name] [description]`

## Skill Creation Process

1. **Requirements Analysis**: Understand skill purpose and when it should be invoked
2. **Best Practices Review**:
   - Use WebFetch to check latest guidelines: https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices
   - Verify skill follows current Claude Code skill guidelines
   - Review anti-patterns and validation checklist
3. **Template Generation**: Create SKILL.md with proper frontmatter and structure
4. **Validation**: Check line count, naming, and content quality
5. **Integration**: Add to skills directory and verify accessibility

## Skill Best Practices (Official Guidelines)

### Conciseness
- Keep SKILL.md under 500 lines
- Only include information Claude doesn't already know
- Use progressive disclosure (reference.md for details)

### Naming
- Use gerund form (verb + -ing): "Processing PDFs", "Analyzing Code"
- Avoid vague names like "Helper" or "Utils"
- Be specific and descriptive

### Description
- Write in third person
- Be specific about what it does and when to use it
- Include key terms for invocation matching

### Structure
```yaml
---
name: Processing PDFs
description: Extracts and analyzes content from PDF files. Use when working with PDF documents.
allowed-tools: [Read, Write, Bash]
---

# Main Instructions

## Core workflow here
```

## Required Elements

### YAML Frontmatter
- `name`: Gerund form, under 64 characters
- `description`: Specific purpose and usage context, under 1024 characters
- `allowed-tools`: Optional list of permitted tools

### Core Content
- **Clear Workflow**: Sequential steps for Claude to follow
- **Specific Instructions**: Precise actions, no vague guidance
- **Feedback Loops**: Validation and error handling steps
- **Consistent Terminology**: Use same terms throughout

## Progressive Disclosure

For complex skills, create separate files:
- `SKILL.md`: Core workflow and essential instructions (< 500 lines)
- `reference.md`: Detailed examples, troubleshooting, advanced topics
- `templates/`: Template files if needed
- `scripts/`: Utility scripts for deterministic operations

Keep references one level deep (don't nest too deeply).

## Validation Checklist

- [ ] Name uses gerund form (verb + -ing)
- [ ] Description is specific and in third person
- [ ] SKILL.md is under 500 lines
- [ ] Workflow is clear and sequential
- [ ] No unnecessary explanations (only what Claude needs)
- [ ] Consistent terminology throughout
- [ ] References appropriate tools via allowed-tools
- [ ] Includes validation/feedback steps
- [ ] Detailed content separated to reference.md if needed

## Anti-Patterns to Avoid

- ❌ Deeply nested file references
- ❌ Offering too many options (be prescriptive)
- ❌ Including common knowledge Claude already has
- ❌ Time-sensitive information that will become outdated
- ❌ Magic numbers without justification
- ❌ Vague names like "Helper Skill" or "Utility Skill"

## Skill Categories

- **Processing**: Transform or analyze specific file types
- **Analyzing**: Deep inspection and reporting on code/systems
- **Debugging**: Systematic issue identification and resolution
- **Generating**: Create artifacts following patterns
- **Coordinating**: Orchestrate multi-step workflows
- **Validating**: Check quality, compliance, correctness

## Example Usage

```
/create-claude-skill "processing-test-results" "Analyzes test output files and generates quality reports. Use when reviewing test execution results."
```

This will:
1. Create skill directory in `.claude/skills/processing-test-results/`
2. Generate SKILL.md with proper structure
3. Follow best practices (gerund name, specific description)
4. Stay under 500 lines
5. Include validation steps

## Directory Structure

```
.claude/skills/your-skill/
├── SKILL.md           # Core workflow (< 500 lines)
├── reference.md       # Optional: detailed examples
├── templates/         # Optional: template files
└── scripts/          # Optional: utility scripts
```

## Testing Your Skill

1. Create skill and verify file structure
2. Test invocation by describing the use case
3. Verify Claude can access and use the skill
4. Iterate based on actual usage observations
5. Keep skill focused on single capability

## Integration Notes

- Skills are stored in `.claude/skills/` (local, not Nix-managed)
- Changes apply immediately (no rebuild needed)
- Claude autonomously decides when to invoke based on description
- Use specific descriptions to improve invocation accuracy

## Related Commands

- `/create-command`: Create custom slash commands
- `/nix-claude-config`: Manage Claude configuration in Nix dotfiles

## References

- [Claude Code Skills Docs](https://docs.claude.com/en/docs/claude-code/skills)
- [Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
