---
name: brainstorm_v2
description: "Systematic idea exploration with Socratic questioning to transform ambiguous concepts into concrete specifications"
---

Transform ambiguous ideas into actionable specifications through systematic exploration and Socratic dialogue.

**Usage**: `/brainstorm_v2 [idea/topic] [--strategy systematic|agile] [--depth shallow|normal|deep]`

## Strategy Options

- `systematic`: Comprehensive step-by-step analysis with complete requirement coverage
- `agile`: Rapid MVP-focused exploration for quick iteration

## Depth Levels

- `shallow`: Basic concept validation and core requirements
- `normal`: Standard specification with key details (default)
- `deep`: Comprehensive analysis including edge cases and technical constraints

## Process Flow

1. **Initial Exploration**: Ask targeted questions to understand the core concept
2. **Requirement Discovery**: Systematically explore user needs, constraints, and goals
3. **Technical Feasibility**: Assess implementation approach and technical requirements
4. **Specification Generation**: Create detailed, actionable specification document

## Key Behaviors

- Ask **one question at a time** to maintain focus
- Build questions on previous answers for deeper understanding
- Explore **why** behind requirements, not just what
- Challenge assumptions constructively
- Validate feasibility throughout the process

## Deliverables

- Detailed specification document (spec.md)
- Technical requirements and constraints
- Implementation recommendations
- Success criteria and validation approach

## Example Usage

```
/brainstorm_v2 "AI-powered code review tool" --strategy systematic --depth normal
```

The command will guide you through systematic exploration to transform this idea into a complete specification ready for implementation.
