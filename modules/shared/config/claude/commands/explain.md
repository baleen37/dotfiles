---
name: explain
description: "Provide clear explanations of code, concepts, or system behavior"
agents: [code-educator]
---

<command>
/explain - Code and Concept Explanation

<purpose>
Deliver clear, comprehensive explanations of code functionality, concepts, or system behavior with educational clarity
</purpose>

<usage>
```bash
/explain <target>            # General code/concept explanation
/explain basic <topic>       # Beginner-friendly explanation
/explain advanced <topic>    # Advanced technical explanation
/explain concept <topic>     # -> code-educator agent
```
</usage>

<execution-strategy>
- **Basic**: Clear explanations with practical examples and context
- **Advanced**: In-depth technical analysis with system relationships
- **Concept**: Educational explanations with learning progression
- **Interactive**: Question-based exploration and clarification
- **Examples**: Practical use cases and implementation patterns
</execution-strategy>

<mcp-integration>
- **Sequential**: Multi-step concept breakdown and systematic analysis
- **Context7**: Framework-specific documentation and best practices
</mcp-integration>

<examples>
```bash
/explain authentication.js   # Code functionality explanation
/explain basic "how JWT works" # Beginner explanation
/explain advanced microservices # Advanced system explanation
/explain concept React hooks    # Educational concept breakdown
```
</examples>

<agent-routing>
- **code-educator**: Complex concept explanations, educational content, progressive learning
</agent-routing>
</command>
