---
name: create-claude-command
description: "Generate new Claude commands following established patterns and conventions"
---

Create new Claude commands with proper structure, validation, and integration following project conventions.

**Usage**: `/create-claude-command [command-name] [description]`

## Command Creation Process

1. **Requirements Analysis**: Understand command purpose and category
2. **Pattern Analysis**: Study existing commands for conventions and structure
3. **Template Generation**: Create command file with proper metadata and sections
4. **Validation**: Ensure command follows established patterns and naming conventions
5. **Integration**: Add to command registry and verify functionality

## Command Categories

- **Planning**: Feature ideation, proposals, brainstorming
- **Implementation**: Technical execution, coding tasks
- **Analysis**: Review, audit, generate insights
- **Workflow**: Coordinate multiple steps, orchestration
- **Utility**: Tools, helpers, convenience functions

## Required Sections

### Metadata

```yaml
---
name: command-name
description: "Brief description of command purpose"
---
```

### Core Content

- **Purpose Statement**: What the command does
- **Usage**: Command syntax and examples
- **Process Flow**: Step-by-step workflow
- **Key Behaviors**: Important operational details
- **Deliverables**: Expected outputs and results

## Naming Conventions

- Use kebab-case for command names
- Be descriptive but concise
- Avoid temporal references (v2, new, legacy)
- Focus on what the command does, not how

## Validation Checklist

- [ ] Follows established command structure
- [ ] Has proper YAML frontmatter
- [ ] Uses consistent section formatting
- [ ] References appropriate MCP tools
- [ ] Includes usage examples
- [ ] Specifies clear deliverables
- [ ] Matches project patterns and conventions

## Example Usage

```
/create-claude-command "optimize-performance" "Systematic performance analysis and optimization recommendations"
```

This will generate a new command file following established patterns and conventions.
