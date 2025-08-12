---
name: explain
description: "Provide clear explanations of code, concepts, or system behavior"
agents: [code-educator]
---

# /explain - Code and Concept Explanation

**Purpose**: Deliver clear, comprehensive explanations of code functionality, concepts, or system behavior with educational clarity

## Usage

```bash
/explain <target>            # General code/concept explanation
/explain basic <topic>       # Beginner-friendly explanation
/explain advanced <topic>    # Advanced technical explanation
/explain concept <topic>     # -> code-educator agent
```

## Execution Strategy

- **Basic**: Clear explanations with practical examples and context
- **Advanced**: In-depth technical analysis with system relationships
- **Concept**: Educational explanations with learning progression
- **Interactive**: Question-based exploration and clarification
- **Examples**: Practical use cases and implementation patterns

## MCP Integration

- **Sequential**: Multi-step concept breakdown and systematic analysis
- **Context7**: Framework-specific documentation and best practices

## Examples

```bash
/explain authentication.js   # Code functionality explanation
/explain basic "how JWT works" # Beginner explanation
/explain advanced microservices # Advanced system explanation
/explain concept React hooks    # Educational concept breakdown
```

## Agent Routing

- **code-educator**: Complex concept explanations, educational content, progressive learning
