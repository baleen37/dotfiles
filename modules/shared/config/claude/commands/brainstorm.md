---
name: brainstorm
description: "Transform ambiguous ideas into concrete requirements through interactive exploration"
category: planning
complexity: simple
mcp-servers: [sequential, context7, serena]
---

# /brainstorm - Idea Refinement

## Purpose
Transform ambiguous ideas into concrete requirements and actionable plans through Socratic dialogue

## Usage
```
/brainstorm [idea/topic]
```

## Core Principle
**Keep asking questions until fully concrete** - Continue dialogue until all essential elements are clearly defined

## Process
1. **Question**: Ask targeted questions to uncover missing details
2. **Clarify**: Challenge assumptions and explore edge cases  
3. **Structure**: Organize information into clear requirements
4. **Validate**: Ensure technical feasibility and resource constraints
5. **Plan**: Create actionable next steps

## MCP Integration
- **Sequential MCP**: Multi-step reasoning for systematic exploration
- **Context7 MCP**: Technical feasibility assessment and framework guidance
- **Serena MCP**: Cross-session persistence and project context

## Key Behaviors
- Ask follow-up questions until no ambiguity remains
- Challenge assumptions to reveal hidden requirements
- Explore edge cases and failure scenarios
- Consider technical constraints and dependencies
- Generate specific, measurable requirements

## Example Flow
```
User: "/brainstorm mobile app for tracking habits"

Claude: "Let me help refine this idea. Here are some key questions:

1. What specific habits do you want to track?
2. Who is your target user?
3. What platforms (iOS/Android/web)?
4. How should users input data?
5. What kind of progress visualization?
..."

[Continues questioning until fully specified]
```

## Deliverables
- Clear problem statement
- Detailed requirements list
- Technical constraints identified
- Priority-ordered feature list
- Next action steps
